package OSCAR::Package;

# Copyright 2001-2002 International Business Machines
#                     Sean Dague <japh@us.ibm.com>
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
#   $Id: Package.pm,v 1.53 2003/06/23 20:18:35 brechin Exp $

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


use strict;
use vars qw(@EXPORT $VERSION $RPM_TABLE $RPM_POOL %PHASES
	    @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);
use OSCAR::Database;
use OSCAR::PackageBest;
use OSCAR::Logger;
use File::Basename;
use File::Copy;
use XML::Simple;
use Carp;

@EXPORT = qw(list_installable_packages list_installable_package_dirs 
	     run_pkg_script run_pkg_user_test
             run_pkg_script_chroot rpmlist distro_rpmlist install_rpms
             pkg_config_xml list_selected_packages getSelectionHash
             isPackageSelectedForInstallation getConfigurationValues);
$VERSION = sprintf("%d.%02d", q$Revision: 1.53 $ =~ /(\d+)\.(\d+)/);

# Trying to figure out the best way to set this.

$RPM_POOL = $ENV{OSCAR_RPMPOOL} || '/tftpboot/rpm';

# XML data from all the packages.

my $PACKAGE_CACHE = undef;
my $xs = new XML::Simple(keyattr => {}, forcearray => 
			 [ "site", "uri", 
			   "rpm",
			   "shortcut", "fieldnames",
			   "requires", "conflicts", "provides" ]);

# The list of phases that are valid for package install.  For more
# info, please see the developement doc

%PHASES = (
	   setup => ['setup'],
	   pre_configure => ['pre_configure'],
	   post_configure => ['post_configure'],
           post_server_install => ['post_server_install',
				   'post_server_rpm_install'],
           post_rpm_install => ['post_client_rpm_install',
				'post_rpm_install'],
           post_clients => ['post_clients'],
           post_install => ['post_install'],
           test_root    => ['test_root'],
           test_user    => ['test_user'],
          );

# The possible places where packages may live.  

@PKG_SOURCE_LOCATIONS = ( "$ENV{OSCAR_HOME}/packages", 
			  "/var/lib/oscar/packages",
			  );

#
# list_installable_packages - this returns a list of installable packages.
#
# You may specify "core", "noncore", or "all" as the first argument to
# get a list of core, noncore, or all packages (respectively).  If no
# argument is given, "all" is implied.
#

sub list_installable_packages {
    my $type = shift;

    # If no argument was specified, use "all"

    $type = "all" if ((!(defined $type)) || (!$type));

    # make the database command and do the database read

    my $command_args;
    if ( $type eq "all" ) {
	$command_args = "packages_installable";
    } elsif ( $type eq "core" ) {
	$command_args = "packages_installable packages.class=core";
    } else {
	$command_args = "packages_installable packages.class!=core";
    }
    my @packages = ();
    if ( OSCAR::Database::database_execute_command( $command_args, 
						    \@packages ) ) {
	return @packages;
    } else {
	warn "Cannot read installable packages list from the ODA database.";
	return undef;
    }
}

#
# list_installable_package_dirs - this returns a list of installable 
# packages without using the database.
#
# You may specify "core", "noncore", or "all" as the first argument to
# get a list of core, noncore, or all packages (respectively).  If no
# argument is given, "all" is implied.
#

sub list_installable_package_dirs {
    my $type = shift;
    my @packages_to_return = ();

    # If no argument was specified, use "all"

    $type = "all" if ((!(defined $type)) || (!$type));

    # read in the database packages table configuration
    
    read_all_pkg_config_xml_files() if (!$PACKAGE_CACHE);
    
    # Now do the work
    
    my @packages = keys %{$PACKAGE_CACHE};
    foreach my $pkg (@packages) {
	
	# First, check if the package has its installable attribute set to 1.
	next if ($PACKAGE_CACHE->{$pkg}->{installable} ne 1);
	
	# If it's a valid package, see if it's the right kind or not
	if ($type eq "all") {
	    push @packages_to_return, $pkg;
	} elsif ($type eq "core") {
	    if ((defined $PACKAGE_CACHE->{$pkg}->{class}) and
		($PACKAGE_CACHE->{$pkg}->{class} eq "core")) {
		push @packages_to_return, $pkg;
	    }
	} else {
	    if ((defined $PACKAGE_CACHE->{$pkg}->{class}) and
		($PACKAGE_CACHE->{$pkg}->{class} ne "core")) {
		push @packages_to_return, $pkg;
	    }
	}
    }

    return @packages_to_return;
}

#
# run_pkg_script - runs the package script for a specific package
#

sub run_pkg_script {
    my ($pkg, $phase, $verbose, $args) = @_;
    my $scripts = $PHASES{$phase};
    if (!$scripts) {
        carp("No such phase '$phase' in OSCAR package API");
        return undef;
    }

    foreach my $dir (@PKG_SOURCE_LOCATIONS) {
	foreach my $scriptname (@$scripts) {
	    my $script = "$dir/$pkg/scripts/$scriptname";
	    if (-e $script) {
		oscar_log_subsection("About to run $script for $pkg") if $verbose;
		$ENV{OSCAR_PACKAGE_HOME} = "$dir/$pkg";
		my $rc = system("$script $args");
		delete $ENV{OSCAR_PACKAGE_HOME};
		if($rc) {
		    my $realrc = $rc >> 8;
		    carp("Script $script exitted badly with exit code '$realrc'") if $verbose;
		    return 0;
		}
	    } 
	}
    }
    return 1;
}

sub run_pkg_script_chroot {
    my ($pkg, $dir) = @_;
    my $scripts = $PHASES{post_rpm_install};
    if (!$scripts) {
        carp("No such phase 'post_rpm_install' in OSCAR package API");
        return undef;
    }
    foreach my $scriptname (@$scripts) {
	foreach my $pkg_dir (@PKG_SOURCE_LOCATIONS) {
	    my $script = "$pkg_dir/$pkg/scripts/$scriptname";
	    if (-e $script) {
		oscar_log_subsection("About to run $script for $pkg");
		run_in_chroot($dir,$script) or (carp "Script $script failed", 
						return undef);
	    }
        }
    }
    return 1;
}

sub run_in_chroot {
    my ($dir, $script) = @_;
    my $base = basename($script);
    my $nscript = "$dir/tmp/$base";
    copy($script, $nscript) 
	or (carp("Couldn't copy $script to $nscript"), return undef);
    chmod 0755, $nscript;
    !system("chroot $dir /tmp/$base") 
	or (carp("Couldn't run /tmp/$script"), return undef);
    unlink $nscript or (carp("Couldn't remove $nscript"), return undef);
    return 1;
}

#
# run_pkg_user_test - runs the package test script as a user
#

sub run_pkg_user_test {
    my ($script, $user, $verbose, $args) = @_;

    if (-e $script) {
            oscar_log_subsection("About to run $script") if $verbose;
            my $uid=getpwnam($user);
	    my $rc;
            if ($uid == $>) {
            	$rc = system("$script $args");
            } else {
                $rc = system("su --command='OSCAR_TESTPRINT=$ENV{OSCAR_TESTPRINT} OSCAR_HOME=$ENV{OSCAR_HOME} $script $args' - $user");
            }
            if($rc) {
                my $realrc = $rc >> 8;
                carp("Script $script exitted badly with exit code '$realrc'") if $verbose;
                return 0;
            }
    }
    return 1;
}
#
# This returns the type of rpm list for a package file.  Use this
# order of precedence in looking for the RPM list:
#
# 1. If XML RPM lists for client, server, or all exist, use them.

# 3. Otherwise, get a listing of all the RPMs in package/[name]/RPMS,
#    and use those.
#

sub rpmlist {
    my ($pkg, $type) = @_;
    my $prefix;
    foreach my $pkg_dir (@PKG_SOURCE_LOCATIONS) {
	if (-d "$pkg_dir/$pkg") {
	    $prefix = "$pkg_dir/$pkg";
	    last;
	}
    }
    if (! $prefix) {
	return ();
    }
# These files are deprecated
#    my $cfile = "$prefix/client.rpmlist";
#    my $sfile = "$prefix/server.rpmlist";
#    my $listfile = ($type eq "client") ? $cfile : $sfile;


# First try the database
    my @field = ("id");
    my @wheres= ( "name=$pkg" );
    my $idresult = database_read_table_fields('packages', \@field, \@wheres, 'id');
    my ($pkgid, $null) = each %$idresult;
    my @rpms_to_return = ();
    @field = ( "rpm" );
    @wheres= ( "package_id=$pkgid", "group=$type" );
    my $key;
    my $value;
    my $results = database_read_table_fields('packages_rpmlists', \@field, \@wheres, 'rpm', "Couldn't get $type rpms for package $pkg");

#print "keys: " . keys(%$results) . " values: " . values(%$results) . "\n";
#print "defined? " . defined(%$results) . " true? " . %$results . "\n";
    if ( keys(%$results) > 0 ) {

	while (($key, $value) = each %$results) {
	#  print "key: $key, value: $value\n";
          push @rpms_to_return, $key;
	}
        #  print "RPMS: " . @rpms_to_return . "\n";
	undef $results;

# Now we need the "all" rpmlist
        @field = ( "rpm", "group" );
	@wheres= ( "package_id=$pkgid" );
	$results = database_read_table_fields('packages_rpmlists', \@field, \@wheres, 'rpm', "Couldn't get $type rpms for package $pkg");
        while (($key, $value) = each %$results) {
	  my ($null, $group) = each %$value;
	  if ( $group =~ /oscar/ ) {
	    delete $$results{$key};
	  } else {
	    push @rpms_to_return, $key;
	  }
	}
    }


# THE FOLLOWING SECTION IS DEPRECATED BY NEW ODA FUNCTIONALITY
    # If we haven't read in all the package config.xml files, do so.

#    read_all_pkg_config_xml_files() if (!$PACKAGE_CACHE);

    # Double check to ensure that the package's "installable" XML
    # attribute is 1.  Return an empty RPM list if it's not.

    # Look for XML first
#
#    if ($PACKAGE_CACHE->{$pkg}->{rpmlist}->{server} ||
#	$PACKAGE_CACHE->{$pkg}->{rpmlist}->{client} ||
#	$PACKAGE_CACHE->{$pkg}->{rpmlist}->{all}) {
#	
#	foreach my $i (0 .. 
#		       $#{$PACKAGE_CACHE->{$pkg}->{rpmlist}->{all}->{rpm}}) {
#	    my $rpm = $PACKAGE_CACHE->{$pkg}->{rpmlist}->{all}->{rpm}[$i];
#	    push @rpms_to_return, $rpm;
#	}
#
#	foreach my $i (0 .. 
#		       $#{$PACKAGE_CACHE->{$pkg}->{rpmlist}->{$type}->{rpm}}) {
#	    my $rpm = $PACKAGE_CACHE->{$pkg}->{rpmlist}->{$type}->{rpm}[$i];
#	    push @rpms_to_return, $rpm;
#	}
#    }


# server and client rpmlist files are deprecated
    # Next, look for client.rpmlist and/or server.rpmlist

#    elsif (-f $cfile || -f $sfile) {
#	if (open(IN,"<$listfile")) {
#	    while(<IN>) {
#		# get rid of comments
#		s/\#.*//;
#		if(/(\S+)/) {
#		    push @rpms_to_return, $1;
#		}
#	    }
#	    close(IN);
#	}
#    } 

    # Otherwise, get a list of files in packages/[name]/RPMS.

    else {
	if (-d "$prefix/RPMS") {
	    my @parts;
	    my %found;
	    my $base;
	    opendir(PKGDIR, "$prefix/RPMS") ||
		carp("Unable to open $prefix/RPMS");
	    
	    # Remember that there may be multiple versions /
	    # architectures for each base RPM.  We don't try to
	    # determine which one is "best" here (that's for
	    # PackageBest) -- instead, we simply make a list of all
	    # the base RPM names and ignore the duplicates.
	    
	    # Crude hueristic: take each *.rpm filename, split it by
	    # the character "-" and drop the last 2 components.
	    
	    foreach my $file (grep { /\.rpm$/ && -f "$prefix/RPMS/$_" }
			      readdir(PKGDIR)) {
		@parts = split(/\-/, $file);
		pop @parts;
		pop @parts;
		$base = join("-", @parts);
		$found{$base} = 1;
	    }
	    closedir(PKGDIR);
	    @rpms_to_return = keys(%found);
	}
    }

    # That's all she wrote

    oscar_log_subsection("Returning $type RPMs for $pkg: " . 
			 join(' ', @rpms_to_return));

    @rpms_to_return;
}

#
# distro_rpmlist - returns the rpms needed for a specific distro on
# the server could be modified for client as well.
#

sub distro_rpmlist {
    my ($distro, $version, $arch) = @_;
    my $listfile = "$distro-$version-$arch.rpmlist";
    my $file = "$ENV{OSCAR_HOME}/share/serverlists/$listfile";
    my @rpms = ();
    open(IN,"<$file") 
	or carp("Couldn't open package list file $file for reading!");
    while(<IN>) {
        # get rid of comments
        s/\#.*//;
        if(/(\S+)/) {
            push @rpms, $1;
        }
    }
    close(IN);
    return @rpms;
}

#
# This is a routine to install the best rpms on the server, only if
# they don't already exist at a high enough version
#

sub install_rpms {
    my (@rpms) = @_;
    my ($ret, %bestrpms) = find_files(
                              PKGDIR => $RPM_POOL,
                              PKGLIST => [@rpms],
                             );
    if ($ret == 0) {
	oscar_log_subsection("Warning: OSCAR find_files errored out");
	return 0;
    }

    foreach my $key (keys %bestrpms) {
        my $fullfilename = "$RPM_POOL/$bestrpms{$key}";
        if(server_version_goodenough($fullfilename)) {
            # purge the package from the list
            delete $bestrpms{$key};
        }
    }

    my @fullfiles = map {"$RPM_POOL/$_"} (sort values %bestrpms);
    
    if(!scalar(@fullfiles)) {
	return 1;
    }
    
    my $cmd = "rpm -Uhv " . join(' ', @fullfiles);
    my $rc = system($cmd);
    if($rc) {
        carp("Couldn't run $cmd");
        return 0;
    } else {
        return 1;
    }
}

sub server_version_goodenough {
    my ($file) = @_;
    my $output1 = `rpm -qp --qf '\%{NAME} \%{VERSION} \%{RELEASE}' $file`;
    my ($n1, $v1, $r1) = split(/ /,$output1);
    my $output2 = `rpm -q --qf '\%{NAME} \%{VERSION} \%{RELEASE}' $n1`;
    if($?) {
        # Then the package doesn't exist on the server at all
        return 0;
    }
    my ($n2, $v2, $r2) = split(/ /,$output2);

    if($v1 eq $v2) {
        # are the versions the same?
        if($r1 eq $r2) {
            # if the versions are the same and the releases are as well, 
            # we know we are good enough
            return 1;
        } elsif (find_best($r1, $r2) eq $r2) {
            # the release on the server is better than the file
            return 1;
        } else {
            # release in file is better than server
            return 0;
        }
    } elsif (find_best($v1, $v2) eq $v2) {
        # the version on server is better
        return 1;
    } else {
        # the version in file is better
        return 0;
    }
}

sub pkg_config_xml {
    # If we haven't read in all the package config.xml files, do so.

    read_all_pkg_config_xml_files() if (!$PACKAGE_CACHE);

    # Return the reference to it

    $PACKAGE_CACHE;
}

###########################################################################

# Return an new, empty XML structure with most fields blank.  However,
# give it a name of the package name, put it in the third-party class,
# and mark it as installable.

sub make_empty_xml {
    my ($package_name) = @_;

    return {
	name => $package_name,
	class => "third-party",
	installable => 1,
	summary => "Not provided",
	description => "Not provided",
    };
}

#
# Returns a hash of *all* packages' config.xml files (or empty hashes
# for the ones that don't have config.xml files), reading them directly
# from each package's config.xml files. This should only be used if the
# oda database has not been initialized. Once the oda database has been
# initialized, the function read_all_pkg_config should be used instead.
#

sub read_all_pkg_config_xml_files {
    foreach my $pkg_dir (@PKG_SOURCE_LOCATIONS) {
	next if (! -d $pkg_dir);

	opendir(PKGDIR, $pkg_dir) 
	    or (carp("Couldn't open $pkg_dir for reading"), 
		return undef);

	while (my $pkg = readdir(PKGDIR)) {
	    chomp($pkg);
	    my $dir = "$pkg_dir/$pkg";
	    my $config = "$dir/config.xml";
	    
	    # Check if it's a valid package: not ".", not "..", not "CVS"
	    # and doesn't contain a .oscar_ignore file
	    if (-d $dir && $pkg ne "." && $pkg ne ".." && $pkg ne "CVS" &&
		! -e "$dir/.oscar_ignore") {
		if (-f $config) {
#       oscar_log_subsection("Reading $config");
		    $PACKAGE_CACHE->{$pkg} = eval { $xs->XMLin($config); };
		    if ($@) {
			oscar_log_subsection("WARNING! The config.xml file for $pkg is invalid.  Creating an empty one...");
			$PACKAGE_CACHE->{$pkg} = make_empty_xml($pkg);
		    } else {
			$PACKAGE_CACHE->{$pkg}->{installable} = 1 if 
			    (!defined($PACKAGE_CACHE->{$pkg}->{installable}));
		    }
		} else {
#       oscar_log_subsection("Got empty XML config for $pkg");
		    $PACKAGE_CACHE->{$pkg} = make_empty_xml($pkg);
		}
	    }
	}
	
	close(PKGDIR);
    }

    $PACKAGE_CACHE;
}

#########################################################################
#  Subroutine: list_selected_packages                                   #
#  Parameters: The "type" of packages - "core", "noncore", or "all"     #
#  Returns   : A list of packages selected for installation.            #
#  If you do not specify the "type" of packages, "all" is assumed.      #
#                                                                       #
#  Usage: @packages_that_are_selected = list_selected_packages();       #
#########################################################################
sub list_selected_packages # ($type) -> @selectedlist
{
    my $type = shift;

    # If no argument was specified, use "all"

    $type = "all" if ((!(defined $type)) || (!$type));

    # make the database command and do the database read

    my $command_args;
    if ( $type eq "all" ) {
	$command_args = "packages_in_selected_package_set";
    } elsif ( $type eq "core" ) {
	$command_args = "packages_in_selected_package_set packages.class=core";
    } else {
	$command_args = "packages_in_selected_package_set packages.class!=core";
    }
    my @packages = ();
    if ( OSCAR::Database::database_execute_command( $command_args, 
						    \@packages ) ) {
	return @packages;
    } else {
	warn "Cannot read selected packages list from the ODA database.";
	return undef;
    }
}

#########################################################################
#  Subroutine: isPackageSelectedForInstallation                         #
#  Parameter : The name of an OSCAR package (directory)                 #
#  Returns   : 1 if the passed in package is selected for installation, #
#              0 otherwise                                              #
#  Use this subroutine if you want a quick T/F answer if a particular   #
#  OSCAR package is selected for installation or not.  Note that this   #
#  subroutine doesn't take into account core/noncore packages.  It      #
#  only cares if it was selected for installation or not.               #
#                                                                       #
#  Usage: $installit = isPackageSelectedForInstallation('mypackage');   #
#########################################################################
sub isPackageSelectedForInstallation # ($package) -> $yesorno
{
  my($package) = @_;
  my($selhash) = getSelectionHash();
  return $selhash->{$package};
}

#########################################################################
#  Subroutine: getSelectionHash                                         #
#  Parameters: None                                                     #
#  Returns   : A hash of packages selected (or not) for installation.   #
#  This subroutine reads in a hidden XML file generated when the user   #
#  selects some OSCAR packages for installation.  It then returns a     #
#  hash of all the OSCAR packages and whether or not each package       #
#  was selected for installation.  Note that this subroutine doesn't    #
#  take into account core/noncore packages.  It only cares if a         #
#  package was selected for installation or not.                        #
#                                                                       #
#  Usage: $install_packages = getSelectionHash();                       #
#         if ($install_packages->{'mypackage'}) then { print "Cool!"; } #
#########################################################################
sub getSelectionHash # () -> $selectionhashref
{
  my($selection);
  my($config) = "$ENV{OSCAR_HOME}/.oscar/.selection.config";

  # If we haven't read in all the package config.xml files, do so.
  read_all_pkg_config_xml_files() if (!$PACKAGE_CACHE);

  if (-s $config)  # Make sure the file exists
    { # Read in the hidden XML selection file
      my($selconf) = eval { XMLin($config,suppressempty => ''); };
      if ($@)
        { # Whoops! Some problem with the file.
          carp("Warning! The .selection.config file was invalid."); 
        }
      else
        { # Get which configuration was selected
          my $configname = $selconf->{selected};
          $selection = $selconf->{configs}{$configname}{packages};
        }
    }
  return $selection;
}

#########################################################################
#  Subroutine: getConfigurationValues                                   #
#  Parameter : The name of an OSCAR package (directory)                 #
#  Returns   : A hash of configuration parameters and their values      #
#  This subroutine takes in the name of an OSCAR package and returns    #
#  The configuration values set by the user in Step 3 of the OSCAR      #
#  install_cluster script.  These values are completely determined by   #
#  each package maintainer in the HTML configuration file (if any).     #
#  NOTE: To make things consistent, each value for a given parameter    #
#        is stored in an array.  So to correctly access each value,     #
#        you need to iterate through each hash parameter.  However, if  #
#        you know that a particular parameter can have at most one      #
#        value, you can access the zeroth element of the array.  See    #
#        the example in the Usage clause below.                         #
#                                                                       #
#  Usage: $configvalues = getConfigurationValues('mypackage');          #
#         $myvalue = $configvalues->{'value'}[0];  # Only one value     #
#         @myvalues = $configvalues->{'happy'};    # Multiple values    #
#########################################################################
sub getConfigurationValues # ($package) -> $valueshashref
{
  my($package) = @_;
  my($values);
  my($filename);

  foreach my $dir (@PKG_SOURCE_LOCATIONS) {
      $filename = "$dir/$package/.configurator.values";
      if (-s $filename) {
	  $values =  eval { XMLin($filename, 
				  suppressempty => '', 
				  forcearray => '1'); 
			};
	  undef $values if ($@);
	  return $values;
      }
  }

  return undef;
}

1;

package OSCAR::Package;

# Copyright 2001-2002 International Business Machines
#                     Sean Dague <japh@us.ibm.com>
# Copyright (c) 2002 The Trustees of Indiana University.  
#                    All rights reserved.
# 
#   $Id: Package.pm,v 1.20 2002/10/25 12:47:37 jsquyres Exp $

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
use vars qw(@EXPORT $VERSION $RPM_TABLE $RPM_POOL @COREPKGS %PHASES);
use base qw(Exporter);
use OSCAR::PackageBest;
use OSCAR::Logger;
use File::Basename;
use File::Copy;
use XML::Simple;
use Carp;

@EXPORT = qw(list_pkg run_pkg_script run_pkg_script_chroot rpmlist distro_rpmlist install_rpms read_all_pkg_config_xml);
$VERSION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);

# Trying to figure out the best way to set this.

$RPM_POOL = $ENV{OSCAR_RPMPOOL} || '/tftpboot/rpm';

# XML data from all the packages.

my $PACKAGE_CACHE = undef;
my $xs = new XML::Simple(keyattr => {}, forcearray => 
			 [ "site", "uri", 
			   "rpm",
			   "requires", "conflicts", "provides" ]);

# This defines which packages are core packages (i.e. MUST be
# installed before the wizard comes up).  

@COREPKGS = qw(c3 sis switcher);

# The list of phases that are valid for package install.  For more
# info, please see the developement doc

%PHASES = (
	   setup => ['setup'],
           post_server_install => ['post_server_install',
				   'post_server_rpm_install'],
           post_rpm_install => ['post_client_rpm_install',
				'post_rpm_install'],
           post_clients => ['post_clients'],
           post_install => ['post_install']
	   );

#
# list_pkg - this returns a list of packages.
#
# you may specify "core" or "noncore" as the first argument to get a
# list of core or noncore packages instead of all packages.  Basic
# theory, if you want core, return the core list.  If you want
# something else, read the package directory, if 'noncore' through
# away core packages as you hit them.
#

sub list_pkg {
    my $type = shift;
    my @packages_to_return = ();

    # If we haven't read in all the package config.xml files, do so.

    read_all_pkg_config_xml() if (!$PACKAGE_CACHE);

    # Now do the work

    my @packages = keys %{$PACKAGE_CACHE};
    foreach my $pkg (@packages) {
	
	# First, check if it's a valid package: not ".", not "..", not
	# "CVS", doesn't contain a .oscar_ignore file, and has its
	# installable attribute set to 1.
	
	my $dir = "$ENV{OSCAR_HOME}/packages/$pkg";
	next if (! -d $dir || $pkg eq "." || $pkg eq ".." || $pkg eq "CVS" ||
		 -f "$dir/.oscar_ignore" ||
		 $PACKAGE_CACHE->{$pkg}->{installable} ne 1);
	
	# If it's a valid package, see if it's the right kind or not

	if ($type eq "core") {
	    if ($PACKAGE_CACHE->{$pkg}->{class} eq "core") {
		push @packages_to_return, $pkg;
	    }
	} else {
	    if ($PACKAGE_CACHE->{$pkg}->{class} ne "core") {
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
    my ($pkg, $phase, $verbose) = @_;
    my $scripts = $PHASES{$phase};
    if (!$scripts) {
        carp("No such phase '$phase' in OSCAR package API");
        return undef;
    }

    foreach my $scriptname (@$scripts) {
        my $script = $ENV{OSCAR_HOME} . "/packages/" . $pkg . "/scripts/" . 
	    $scriptname;
        if (-e $script) {
            oscar_log_subsection("About to run $script for $pkg");
            my $rc = system($script);
            if ($rc) {
                my $realrc = $rc >> 8;
                carp("Script $script exitted badly with exit code '$realrc'");
                return 0;
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
        my $script = $ENV{OSCAR_HOME} . "/packages/" . $pkg . "/scripts/" . 
	    $scriptname;
        if (-e $script) {
            oscar_log_subsection("About to run $script for $pkg");
            run_in_chroot($dir,$script) or (carp "Script $script failed", 
					    return undef);
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
# This returns the type of rpm list for a package file.  Use this
# order of precedence in looking for the RPM list:
#
# 1. If XML RPM lists for client, server, or all exist, use them.
# 2. If client.rpmlist or server.rpmlist exists, use them.
# 3. Otherwise, get a listing of all the RPMs in package/[name]/RPMS,
#    and use those.
#

sub rpmlist {
    my ($pkg, $type) = @_;
    my $prefix = "$ENV{OSCAR_HOME}/packages/$pkg";
    my $cfile = "$prefix/client.rpmlist";
    my $sfile = "$prefix/server.rpmlist";
    my $listfile = ($type eq "client") ? $cfile : $sfile;
    my @rpms_to_return = ();
    
    # If we haven't read in all the package config.xml files, do so.

    read_all_pkg_config_xml() if (!$PACKAGE_CACHE);

    # Double check to ensure that the package's "installable" XML
    # attribute is 1.  Return an empty RPM list if it's not.

    # Look for XML first

    if ($PACKAGE_CACHE->{$pkg}->{rpmlist}->{server} ||
	$PACKAGE_CACHE->{$pkg}->{rpmlist}->{client} ||
	$PACKAGE_CACHE->{$pkg}->{rpmlist}->{all}) {
	
	foreach my $i (0 .. 
		       $#{$PACKAGE_CACHE->{$pkg}->{rpmlist}->{all}->{rpm}}) {
	    my $rpm = $PACKAGE_CACHE->{$pkg}->{rpmlist}->{all}->{rpm}[$i];
	    push @rpms_to_return, $rpm;
	}

	foreach my $i (0 .. 
		       $#{$PACKAGE_CACHE->{$pkg}->{rpmlist}->{$type}->{rpm}}) {
	    my $rpm = $PACKAGE_CACHE->{$pkg}->{rpmlist}->{$type}->{rpm}[$i];
	    push @rpms_to_return, $rpm;
	}
    }

    # Next, look for client.rpmlist and/or server.rpmlist

    elsif (-f $cfile || -f $sfile) {
	if (open(IN,"<$listfile")) {
	    while(<IN>) {
		# get rid of comments
		s/\#.*//;
		if(/(\S+)/) {
		    push @rpms_to_return, $1;
		}
	    }
	    close(IN);
	}
    } 

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

###########################################################################

# Return an new, empty XML structure with most fields blank.  However,
# give it a name of the package name, put it in the third-party class,
# and mark it as installable.

sub make_empty_xml {
    my ($package_name) = @_;

    return {
	name => $package_name,
	version => {
	    major => 0,
	    minor => 0,
	    subversion => 0,
	    release => 0,
	    epoch => 0
	    },
	class => "third-party",
	installable => 1,
	summary => "Not provided",
	license => "",
	group => "",
	url => "",
	maintainer => {
	    name => "",
	    email => ""
	},
	packager => {
	    name => "",
	    email => ""
	},
	description => "Not provided",
	download => {
	    uri => [ "" ],
	    size => 0,
	    md5sum => ""
	},
    };
}

#
# Returns a hash of *all* packages' config.xml files (or empty hashes
# for the ones that don't have config.xml files).
#

sub read_all_pkg_config_xml {
    opendir(PKGDIR,"$ENV{OSCAR_HOME}/packages") 
	or (carp("Couldn't open $ENV{OSCAR_HOME}/packages for reading"), 
	    return undef);

    while (my $pkg = readdir(PKGDIR)) {
	chomp($pkg);
	my $dir = "$ENV{OSCAR_HOME}/packages/$pkg";
	my $config = "$dir/config.xml";
	if (-d $dir && $pkg ne "." && $pkg ne ".." && $pkg ne "CVS") {
	    if (-f $config) {
		oscar_log_subsection("Reading $config");
		$PACKAGE_CACHE->{$pkg} = $xs->XMLin($config);
	    } else {
		oscar_log_subsection("Got empty XML config for $pkg");
		$PACKAGE_CACHE->{$pkg} = make_empty_xml($pkg);
	    }
	}
    }
    close(PKGDIR);

    $PACKAGE_CACHE;
}

1;

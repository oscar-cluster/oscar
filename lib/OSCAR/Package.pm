package OSCAR::Package;

# Copyright (c) 2003, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
# Copyright 2001-2002 International Business Machines
#                     Sean Dague <japh@us.ibm.com>
# Copyright (c) 2002-2005 The Trustees of Indiana University.  
#                         All rights reserved.
# 
#   $Id$

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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw(@EXPORT $VERSION %PHASES);
use base qw(Exporter);
use OSCAR::Database;
use OSCAR::PackagePath;
use OSCAR::OpkgDB;
use OSCAR::Logger;
use File::Basename;
use File::Copy;
use XML::Simple;
use OSCAR::OCA::OS_Detect;
use OSCAR::ConfigManager;
use Carp;

# Default package group.
my $DEFAULT = "Default";

@EXPORT = qw(
             run_pkg_script
             run_pkg_user_test
             run_pkg_script_chroot
             run_pkg_apitest_test
             isPackageSelectedForInstallation
             getConfigurationValues
             run_pkg_apitest_test
             get_excluded_opkg
             );
$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# The list of phases that are valid for package install.  For more
# info, please see the developement doc
# Note that we still list old scripts' name to ease the transition.
# Mid-term they should be removed
%PHASES = (
           setup => ['api-pre-install',
                     'setup'], # deprecated
           pre_configure => ['api-pre-configure',
                             'pre_configure'], # deprecated
           post_configure => ['api-post-configure',
                              'post_configure'], # deprecated
           post_server_install => ['server-post-install',
                                   'server-post_install', # for RPM sys only
                                   'post_server_install', # deprecated
                                   'post_server_rpm_install'], # deprecated
           post_rpm_install => ['client-post-install',
                                'client-post_install', # for RPM sys only
                                'post_client_rpm_install', # deprecated
                                'post_rpm_install'], # deprecated
           post_rpm_nochroot => ['api-post-image',
                                 'post_rpm_nochroot'], # deprecated
           post_clients => ['api-post-clientdef',
                            'post_clients'], # deprecated
           post_install => ['api-post-deploy',
                            'post_install'], # deprecated
           test_root    => ['test_root'],
           test_user    => ['test_user'],
          );

my $oscar_configurator = OSCAR::ConfigManager->new(
        config_file => "/etc/oscar/oscar.conf");
my $config = $oscar_configurator->get_config();

#
# get_pkg_dir - return directory where scripts can be found for a given
#               package and phase
#

sub get_scripts_dir ($$) {
    my ($pkg, $phase) = @_;
    if ($phase eq 'test_root' || $phase eq 'test_user') {
        return "/var/lib/oscar/testing/$pkg";
    } else {
        return "/var/lib/oscar/packages/$pkg";
    }
}


#
# run_pkg_script - runs the package script for a specific package
#
# Return: 1 if success, 0 else.

sub run_pkg_script ($$$$) {
    my ($pkg, $phase, $verbose, $args) = @_;
    my $scripts = $PHASES{$phase};
    if (!$scripts) {
        carp("ERROR: No such phase '$phase' in OSCAR package API");
        return 0;
    }

    my $pkgdir = get_script_dir ($pkg, $phase);
    return 0 unless ((defined $pkgdir) && (-d $pkgdir));
    foreach my $scriptname (@$scripts) {
	my $script = "$pkgdir/$scriptname";
	if (-e $script) {
        chmod 0755, $script;
	    oscar_log_subsection("About to run $script for $pkg") if $verbose;
	    $ENV{OSCAR_PACKAGE_HOME} = $pkgdir;
	    my $rc = system("$script $args");
	    delete $ENV{OSCAR_PACKAGE_HOME};
	    if ($rc) {
		my $realrc = $rc >> 8;
		carp("ERROR: Script $script exitted badly with exit code '$realrc'") 
            if $verbose;
		return 0;
	    }
	} 
    }
    return 1;
}

# Return: 1 if success, undef else.
sub run_pkg_script_chroot ($$) {
    my ($pkg, $dir) = @_;
    my $phase = "post_rpm_install";
    my $scripts = $PHASES{$phase};
    if (!$scripts) {
        carp("ERROR: No such phase 'post_rpm_install' in OSCAR package API");
        return undef;
    }

    my $pkgdir = get_scripts_dir ($pkg, $phase);
    return undef unless ((defined $pkgdir) && (-d $pkgdir));
    foreach my $scriptname (@$scripts) {
        my $script = "$pkgdir/$scriptname";
        if (-e $script) {
            chmod 0755, $script;
            oscar_log_subsection("About to run $script for $pkg");
            run_in_chroot ($dir,$script)
                or (carp ("ERROR: Script $script failed"), return undef);
        }
    }
    return 1;
}

# Return: 1 if success, undef else.
sub run_in_chroot ($$) {
    my ($dir, $script) = @_;
    my $base = basename($script);
    my $nscript = "$dir/tmp/$base";
    copy($script, $nscript) 
        or (carp("ERROR: Couldn't copy $script to $nscript"), return undef);
    chmod 0755, $nscript;
    !system("chroot $dir /tmp/$base") 
        or (carp("ERROR: Couldn't run /tmp/$script"), return undef);
    unlink $nscript or (carp("ERROR: Couldn't remove $nscript"), return undef);
    return 1;
}

#
# run_pkg_user_test - runs the package test script as a user
#
# Return: 1 if success, 0 else.
sub run_pkg_user_test ($$$$) {
    my ($script, $user, $verbose, $args) = @_;

    if (-e $script) {
            oscar_log_subsection("About to run $script") if $verbose;
            my $uid=getpwnam($user);
        my $rc;
            if ($uid == $>) {
                $rc = system("$script $args");
            } else {
                if( defined($ENV{OSCAR_PACKAGE_TEST_HOME}) ) {
                     # TJN: this EnvVar is used by 'test_user' scripts. 
                    $rc = system("su --command='OSCAR_TESTPRINT=$ENV{OSCAR_TESTPRINT} OSCAR_HOME=$ENV{OSCAR_HOME} OSCAR_PACKAGE_TEST_HOME=$ENV{OSCAR_PACKAGE_TEST_HOME} $script $args' - $user");
                } else {
                    $rc = system("su --command='OSCAR_TESTPRINT=$ENV{OSCAR_TESTPRINT} OSCAR_HOME=$ENV{OSCAR_HOME} $script $args' - $user");
                }
            }
            if($rc) {
                my $realrc = $rc >> 8;
                carp("Script $script exited badly with exit code '$realrc'") if $verbose;
                return 0;
            }
    }
    return 1;
}


#
# APItest Additions
#  This runs an APItest file (or batch file).  Expected that this 
#  will be run as 'root', but can use another user if needed.
#
# Return: 1 if success, 0 else.
# TODO Fix work arounds for current release of APItest v0.2.5-1
sub run_pkg_apitest_test ($$$) {
	use File::Spec;

	my ($script, $user, $verbose) = @_;
	my $apitest = "apitest";
	my $rc = 0;


	if (-e $script) {
		oscar_log_subsection("About to run APItest: $script") if $verbose;

		#FIXME: TJN: work around path problem of APItest that 
		#       dies when called from other location than CWD of file.
		#       So must do: (cd $cpath; apitest test_file)

		my ($vol,$path,$file) = File::Spec->splitpath( $script );
		my $cpath = File::Spec->canonpath( $path );

		my $uid=getpwnam($user);
		if ($uid == $>) {
			#FIXME: work around path problem of APItest
			#$rc = system("$apitest -T -f $script");
			my $cmd = "(cd $cpath && $apitest -T -f $file)";
			$rc = system($cmd);
		} else {
			#FIXME: work around path problem of APItest (cd $cpath; ...)
			#$rc = system("su --command='OSCAR_HOME=$ENV{OSCAR_HOME} $apitest -T -f $script' - $user");
			my $cmd = "su --command='OSCAR_HOME=$ENV{OSCAR_HOME} (cd $cpath && $apitest -T -f $file)' - $user";
			$rc = system($cmd);
		}
	} else {
		oscar_log_subsection("Warning: not exist '$script' ") if $verbose;
	}

	if($rc) {
		my $realrc = $rc >> 8;
		carp("Script APItest $script exited badly with exit code '$realrc'") 
            if $verbose;
		return 0;
	}

	return 1;
}


#########################################################################
# Subroutine: get_excluded_opkg
# Parameter : None
# Returns   : The list of OSCAR packages excluded for the current Linux
#             distribution, i.e., for the end node
#
# TODO: - extend to any systems, not only the headnode (warning for that
#         dependences with the headnode has to be managed, we currently 
#         have nothing for that.
#       - currently the list of excluded opkg for Linux distributions is
#         done via files in oscar/share/exclude_pkg_set. It should be 
#         nice to be able to do that via config.xml files.
sub get_excluded_opkg () {
    my $os = OSCAR::OCA::OS_Detect::open();
    exit -1 if(!$os);
    my $filename = $ENV{OSCAR_HOME} . "/share/exclude_pkg_set/";
    $filename .= $os->{compat_distro} . "-" . $os->{compat_distrover} . "-" 
                . $os->{arch} . ".txt";
    my @exclude_packages = qw();
    if ( -f $filename ) {
        print "File exists, excluding packages...\n";
        open (FILE, $filename);
        my $package;
        while ($package = <FILE>) {
            chomp ($package);
            if ($package ne "") {
                push(@exclude_packages, $package);
            }
        }
        close (FILE);
    }

    return @exclude_packages;
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
  #
  # Use the database for finding out about selected packages!
  # This code is obsolete!
  #
  #my($selhash) = getSelectionHash();
  #return $selhash->{$package};
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
# Return: configuration parameters (hash) or undef if error.            #
#########################################################################
sub getConfigurationValues ($) # ($package) -> $valueshashref
{
    my $package = shift;
    my $values;
    my $filename;

#    my $pkgdir = getOdaPackageDir($package);
    my $pkgdir = $config->{'opkgs_path'} . "/$package";
    if ((defined $pkgdir) && (-d $pkgdir)) {
        $filename = "$pkgdir/.configurator.values";
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

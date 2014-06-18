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
use OSCAR::LoggerDefs;
use OSCAR::Utils;
use File::Basename;
use File::Copy;
use XML::Simple;
use OSCAR::OCA::OS_Detect;
use OSCAR::OCA::OS_Settings;
use OSCAR::ConfigManager;
use Carp;

# Default package group.
my $DEFAULT = "Default";

@EXPORT = qw(
             get_excluded_opkg
             get_scripts_dir
             get_data_dir
             getConfigurationValues
             isPackageSelectedForInstallation
             run_pkg_script
             run_pkg_user_test
             run_pkg_script_chroot
             run_pkg_apitest_test
             );
$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

=encoding utf8

=head1 NAME

OSCAR::Package; -- OSCAR Packages management abstraction module

=head1 SYNOPSIS

use OSCAR::Package;

=head1 DESCRIPTION

This module provides a collection of fuctions to provide an abstraction
layer to system services management.

Depending on Linux distro, services are managed by systemd, initscripts
commands (chkconfig, service) upstart commands (start, stop, restart, ...)
or manually (run the /etc/init.d script directly or enabling it manually
as well). This module allows to forget those differences when managing
services.

=head2 Phases

=over 4

The list of phases that are valid for package install.  For more
info, please see the developement doc
Note that we still list old scripts' name to ease the transition.
Mid-term they should be removed

  Phase               corresponding script    when it is run
* setup               api-pre-install         
* pre_configure       api-pre-configure       Before step 2 (before configuration occures)
* post_configure      api-post-configure      End of step 2 (after configuration occured)
* post_server_install server-post-install     End of step 3
* post_rpm_install    client-post-install     After image creation (chrooted in image)
* post_rpm_nochroot   api-post-image          After image creation (not chrooted)
* post_clients        api-post-clientdef      After step 5 (Define OSCAR Clients)
* post_install        api-post-deploy         During step 7 (complete cluster setup)
* test_root           test_root               DEPRECATED (step 8)
* test_user           test_user               DEPRECATED (step 8)

=cut
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

=head2 Functions

=over 4

=cut

###############################################################################
=item get_scripts_dir($pkg,$phase)

Returns directory where scripts can be found for a given package and phase

Input:  $pkg:   The package
        $phase: The phase which can be chosen from %PHASES (see above)

Return: directory where scripts can be found

=cut 
###############################################################################

sub get_scripts_dir ($$) {
    my ($pkg, $phase) = @_;
    if ($phase eq 'test_root' || $phase eq 'test_user') {
        my $testing_path=OSCAR::OCA::OS_Settings::getitem('oscar_testing_path');
        return "$testing_path/$pkg";
    } else {
        my $packages_path=OSCAR::OCA::OS_Settings::getitem('oscar_packages_path');
        return "$packages_path/$pkg";
    }
}

###############################################################################
=item get_data_dir($pkg)

Return directory where test data can be found for a given package

Input:  $pkg:   The package

Return: directory where scripts can be found

=cut
###############################################################################

sub get_data_dir ($) {
    my $pkg = shift;
    my $testing_path=OSCAR::OCA::OS_Settings::getitem('oscar_testing_path');
    return "$testing_path/data/$pkg";
}

###############################################################################
=item run_pkg_script ($pkg, $phase, $verbose, $args)

Runs the package script for a specific package

Input:     $pkg: Name of package
         $phase: Phase (see %PHASE possible values above)
       $verbose: verbosity
          $args: args for the script.

Return:  1 if success, 0 else.

=cut
###############################################################################

sub run_pkg_script ($$$$) {
    my ($pkg, $phase, $verbose, $args) = @_;
    my $scripts = $PHASES{$phase};
    oscar_log(5, SUBSECTION, "run_pkg_script for $pkg ($phase)");
    if (!$scripts) {
        oscar_log(5, ERROR, "No such phase '$phase' in OSCAR package API");
        return 0;
    }

    my $pkgdir = get_scripts_dir ($pkg, $phase);
    # If the package does not provide any sripts, the directory won't exist,
    # we exit successfully (nothing to do and this is fine).
    (oscar_log(6, INFO, "No script dir for package $pkg"), return 1)
        unless ((defined $pkgdir) && (-d $pkgdir));

    foreach my $scriptname (@$scripts) {
        my $script = "$pkgdir/$scriptname";
        oscar_log(6, INFO, "Looking for $script...");
        if (-e $script) {
            chmod 0755, $script; # Should be useless.
            $ENV{OSCAR_PACKAGE_HOME} = $pkgdir;
            my $rc = oscar_system("$script $args");
            delete $ENV{OSCAR_PACKAGE_HOME};
            if ($rc) {
                return 0;
            }
        }
    }
    return 1;
}

###############################################################################
=item run_pkg_script_chroot($pkg, $imagedir)

Run a script chrooted in image dir.

Input:        $pkg: package name
         $imagedir: path to image

Return:  1 if success, undef else.

=cut
###############################################################################

sub run_pkg_script_chroot ($$) {
    my ($pkg, $imagedir) = @_;
    my $phase = "post_rpm_install";
    my $scripts = $PHASES{$phase};
    oscar_log(5, SUBSECTION, "run_pkg_script_chroot for $pkg in image $imagedir ($phase)");
    if (!$scripts) {
        oscar_log(5, ERROR, "No such phase 'post_rpm_install' in OSCAR package API");
        return undef;
    }

    my $pkgdir = get_scripts_dir ($pkg, $phase);
    # If the package does not provide any sripts, the directory won't exist,
    # we exit successfully (nothing to do and this is fine).
    (oscar_log(6, INFO, "No script dir for package $pkg"), return 1)
        unless ((defined $pkgdir) && (-d $pkgdir));
    foreach my $scriptname (@$scripts) {
        my $script = "$pkgdir/$scriptname";
        if (-e "$imagedir/$script") {
            chmod 0755, "$imagedir/$script"; # Should be useless.
            $ENV{OSCAR_PACKAGE_HOME} = $pkgdir;
            my $rc = oscar_system("chroot $imagedir $script");
            if ($rc) {
                return undef;
            }
        }
    }
    return 1;
}

###############################################################################
=item run_pkg_user_test ($script, $user, $verbose, $args)

Runs the package test script as a user

Input:   $script: script name.
           $user: username.
        $verbose: verbosity level. (unused)
           $args: arguments to the script.

Return:  1 if success, 0 else.

=cut
###############################################################################

sub run_pkg_user_test ($$$$) {
    my ($script, $user, $verbose, $args) = @_;

    if (-e $script) {
            oscar_log(5, SUBSECTION, "About to run $script as $user");
            my $uid=getpwnam($user);
            my $rc;
            if ($uid == $>) {
                $rc = oscar_system("$script $args");
            } else {
                if( defined($ENV{OSCAR_PACKAGE_TEST_HOME}) ) {
                     # TJN: this EnvVar is used by 'test_user' scripts. 
                    $rc = oscar_system("su --command='OSCAR_TESTPRINT=$ENV{OSCAR_TESTPRINT} OSCAR_HOME=$ENV{OSCAR_HOME} OSCAR_PACKAGE_TEST_HOME=$ENV{OSCAR_PACKAGE_TEST_HOME} $script $args' - $user");
                } else {
                    $rc = oscar_system("su --command='OSCAR_TESTPRINT=$ENV{OSCAR_TESTPRINT} OSCAR_HOME=$ENV{OSCAR_HOME} $script $args' - $user");
                }
            }
            if($rc) {
                return 0;
            }
    }
    return 1;
}


###############################################################################
=item run_pkg_apitest_test ($script, $user, $verbose)

APItest Additions
 This runs an APItest file (or batch file).  Expected that this
 will be run as 'root', but can use another user if needed.

Input:  $script: apitest script
        $user: username
        $verbose: verbosity

Return:  1 if success, 0 else.

TODO Fix work arounds for current release of APItest v0.2.5-1

NOTE: This function is mostly deprecated.

=cut
###############################################################################

sub run_pkg_apitest_test ($$$) {
    use File::Spec;

    my ($script, $user, $verbose) = @_;
    my $apitest = "apitest";
    my $rc = 0;


    if (-e $script) {
        oscar_log(5, INFO, "About to run APItest: $script");

        #FIXME: TJN: work around path problem of APItest that 
        #       dies when called from other location than CWD of file.
        #       So must do: (cd $cpath; apitest test_file)

        my ($vol,$path,$file) = File::Spec->splitpath( $script );
        my $cpath = File::Spec->canonpath( $path );

        my $uid=getpwnam($user);
        if ($uid == $>) {
            #FIXME: work around path problem of APItest
            #$rc = oscar_system("$apitest -T -f $script");
            my $cmd = "(cd $cpath && $apitest -T -f $file)";
            $rc = oscar_system($cmd);
        } else {
            #FIXME: work around path problem of APItest (cd $cpath; ...)
            #$rc = oscar_system("su --command='OSCAR_HOME=$ENV{OSCAR_HOME} $apitest -T -f $script' - $user");
            my $cmd = "su --command='OSCAR_HOME=$ENV{OSCAR_HOME} (cd $cpath && $apitest -T -f $file)' - $user";
            $rc = oscar_system($cmd);
        }
    } else {
        oscar_log_subsection("Warning: not exist '$script' ") if $verbose;
    }

    if($rc) {
        return 0;
    }

    return 1;
}


###############################################################################
=item get_excluded_opkg ()

Get the list of OSCAR packages excluded for the current Linux distribution
i.e., for the end node

Input:   None

Return:  The list of OSCAR packages excluded for the current Linux distribution

TODO: - extend to any systems, not only the headnode (warning for that
        dependences with the headnode has to be managed, we currently 
        have nothing for that.
      - currently the list of excluded opkg for Linux distributions is
        done via files in oscar/share/exclude_pkg_set. It should be 
        nice to be able to do that via config.xml files.

=cut
###############################################################################

sub get_excluded_opkg () {
    my $os = OSCAR::OCA::OS_Detect::open();
    exit(-1) if(!$os);
    my $filename = $ENV{OSCAR_HOME} . "/share/exclude_pkg_set/";
    $filename .= $os->{compat_distro} . "-" . $os->{compat_distrover} . "-" 
                . $os->{arch} . ".txt";
    my @exclude_packages = qw();
    if ( -f $filename ) {
        oscar_log(5, INFO, "File exists, excluding packages...");
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

###############################################################################
=item getConfigurationValues ($package) 

This subroutine takes in the name of an OSCAR package and returns
The configuration values set by the user in Step 3 of the OSCAR
install_cluster script.  These values are completely determined by
each package maintainer in the HTML configuration file (if any).
NOTE: To make things consistent, each value for a given parameter
      is stored in an array.  So to correctly access each value,
      you need to iterate through each hash parameter.  However, if
      you know that a particular parameter can have at most one
      value, you can access the zeroth element of the array. See
      the example in the Usage clause below.

Usage: $configvalues = getConfigurationValues('mypackage');
       $myvalue = $configvalues->{'value'}[0];  # Only one value
       @myvalues = $configvalues->{'happy'};    # Multiple values

Input:   $package: The name of an OSCAR package (directory)

Return:  configuration parameters (hash) or undef if error. 

=cut
###############################################################################

sub getConfigurationValues ($) # ($package) -> $valueshashref
{
    my $package = shift;
    my $values;
    my $filename;

#    my $pkgdir = getOdaPackageDir($package);
#    my $oscar_configurator = OSCAR::ConfigManager->new(
#        config_file => "/etc/oscar/oscar.conf");
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        return undef;
    }
    my $config = $oscar_configurator->get_config();
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

=back

=head1 AUTHORS
    (c) 2001-2002 Sean Dague <japh@us.ibm.com>
                  International Business Machines
                  All rights reserved.
Enhanced and documented by:
    (c) 2013-2014 Olivier Lahaye C<< <olivier.lahaye@cea.fr> >>
                  CEA (Commissariat à l'Énergie Atomique)
                  All rights reserved

=head1 LICENSE
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

42;

__END__

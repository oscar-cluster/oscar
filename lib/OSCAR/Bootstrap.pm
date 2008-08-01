package OSCAR::Bootstrap;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This package provides a set of functions for the OSCAR bootstrap.
#

#
# $Id$
#

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use File::Basename;
use Carp;

@EXPORT = qw (
                bootstrap_stage0
                init_db
                init_file_db
                load_oscar_config
                oscar_bootstrap
             );

# Specify where the install_prereq script is
our $ipcmd;

# Specify where the install_server script is
our $iscmd;


################################################################################
# Bootstrap OSCAR.                                                             #
# The OSCAR bootstrap is composed into three parts:                            #
#   - stage 0, which setup everything to be able to read the configuration     #
#              file,                                                           #
#   - stage 1, which setup everything for a smart installation of binary       #
#              packages,                                                       #
#   - stage 2, which setup the system and install packages for the management  #
#              of clusters.                                                    #
#                                                                              #
# Return 0 if success, -1 else.                                                #
################################################################################
sub oscar_bootstrap ($) {
    my $configurator = shift;

    if (!defined ($configurator)) {
        carp "ERROR: invalid configurator object\n";
        return -1;
    }

    if (bootstrap_stage1($configurator)) {
        carp "ERROR: Impossible to complete stage 1 of the bootstrap.\n";
        return -1;
    }

    if (bootstrap_stage2($configurator)) {
        carp "ERROR: Impossible to complete stage 2 of the bootstrap.\n";
        return -1;
    }
    return 0;
}

################################################################################
# Function that installs a given prereq (i.e., binary packages that compose a  #
# prereq) in smart mode. For that we first check the status of the prereq and  #
# if we need to do something, we install the prereq calling the install_prereq #
# script.                                                                      #
#                                                                              #
# Input: prereq path (i.e., the path of the prereq configuration file.         #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub install_prereq ($$) {
    my ($prereq_path, $prereq_mode) = @_;
    my $cmd;

    # We get the current status of the prereq first
    $cmd = $ipcmd . " --status " . $prereq_path;
    my $prereq_name = basename ($cmd);
    print "Dealing with Prereq $prereq_name\n";
    if (system ($cmd)) {
        print "$prereq_name is not installed.\n";

        # We try to install the prereq
        $cmd = $ipcmd . " --smart " . $prereq_path;
        if (system ($cmd)) {
            carp "ERROR: impossible to install $prereq_name ($cmd).\n";
            return -1;
        }

        # Packman should be installed now
        $cmd = $ipcmd . " --status " . $prereq_path;
        if (system ($cmd)) {
            carp "ERROR: $prereq_name is still not installed\n";
            return -1;
        }
    }

    return 0;
}

################################################################################
# Function that installs a given prereq (i.e., binary packages that compose a  #
# prereq) in dumb mode. For that we first check the status of the prereq and   #
# if we need to do something, we install the prereq calling the install_prereq #
# script.                                                                      #
#                                                                              #
# Input: prereq path (i.e., the path of the prereq configuration file.         #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: some code duplication with the install_prereq function.                #
################################################################################
sub bootstrap_prereqs ($$) {
    my ($prereq_path, $prereq_mode) = @_;
    my $cmd;

    # We get the current status of the prereq first
    $cmd = $ipcmd . " --status " . $prereq_path;
    my $prereq_name = basename ($prereq_path);
    print "Dealing with Prereq $prereq_name ($prereq_path, $prereq_mode)\n";
    if (system ($cmd)) {
        print "$prereq_name is not installed.\n";

        if ($prereq_mode eq "check_and_fix") {
            # We try to install Packman
            $cmd = $ipcmd . " --dumb " . $prereq_path;
            print "Executing $cmd...\n";
            if (system ($cmd)) {
                carp "ERROR: impossible to install $prereq_name ($cmd).\n";
                return -1;
            }

            # Packman should be installed now
            $cmd = $ipcmd . " --status " . $prereq_path;
            print "Executing $cmd...\n";
            if (system ($cmd)) {
                carp "ERROR: $prereq_name is still not installed\n";
                return -1;
            }
        } elsif ($prereq_mode eq "check_only") {
            print "$prereq_name needs to be installed.\n";
            return -1;
        }
    } else {
        print "$prereq_name is already installed, nothing to do.\n";
    }

    return 0;
}

################################################################################
# Initialize the database used by ODA when a real database is used (e.g.,      #
# mysql).                                                                      #
#                                                                              #
# Input: OSCAR configurator object (ConfigManager object).                     #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub init_db ($) {
    my $configurator = shift;
    if (!defined ($configurator)) {
        carp "ERROR: invalid configurator object\n";
        return -1;
    }
    my $config = $configurator->get_config();

    require OSCAR::oda;
    print "Database Initialization\n";
    my (%options, %errors);
    my $database_status = oda::check_oscar_database(
        \%options,
        \%errors);
    print "Database_status: $database_status\n";
    if (!$database_status) {
        print "\tWe need to initialize the database\n";
        my $scripts_path = $config->{'scripts_path'};
    my $cmd = "$scripts_path/make_database_password";
    if (system ($cmd)) {
        carp "ERROR: Impossible to set database password ($cmd)\n";
        return -1;
    }
    $cmd =  "$scripts_path/create_oscar_database";
    if (system ($cmd)) {
        carp "ERROR: Impossible to create the database ($cmd)\n";
        return -1;
    }
        print "\tDatabase created, now populating the database\n";
        $cmd = "$scripts_path/prepare_oda";
        if (system ($cmd)) {
            carp "ERROR: Impossible to populate the database ($cmd)\n";
            return -1;
        }
        # We double-check if the database really exists
        $database_status = oda::check_oscar_database(
            \%options,
            \%errors);
        if (!$database_status) {
            carp "ERROR: The database is supposed to have been created but\n".
                  " we cannot connect to it.\n";
            return -1;
        }
    }
    return 0;
}

################################################################################
# Initialize the database used by ODA when flat files are used (e.g.mysql).    #
#                                                                              #
# Input: None.                                                                 #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub init_file_db () {
    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();
    my $scripts_path = $config->{binaries_path};

    # We just check if the directories exist in /etc/oscar
    my $path = "/etc/oscar/";
    my $opkgs_config_path = $path . "opkgs";
    my $clusters_path = $path . "clusters";

    if ( ! -d $path ) {
        mkdir ($path);
    }
    if ( ! -d $clusters_path ) {
        mkdir ($clusters_path);
    }
    if ( ! -d $opkgs_config_path ) {
        mkdir ($opkgs_config_path);
    }
    print "\tDatabase created, now populating the database\n";
    my $cmd = "$scripts_path/prepare_oda";
    if (system ($cmd)) {
        carp "ERROR: Impossible to populate the database ($cmd)\n";
        return -1;
    }
    return 0;
}

################################################################################
# After the basic bootstrapping, we install everything needed for the OSCAR    #
# headnode, typically initialize the database and install server side core     #
# OSCAR packages.                                                              #
#                                                                              #
# Input: configurator, ConfigManager object that gives the values of the OSCAR #
#                      configuration file.                                     #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: Code duplication with wizard_prep. The code in wizard_prep should be   #
#       removed when we will integrate this bootstrapping mechanism directly   #
#       into the current OSCAR code.                                           #
################################################################################
sub init_server ($) {
    my $configurator = shift;
    if (!defined ($configurator)) {
        carp "ERROR: Invalid configurator object.\n";
        return -1;
    }
    my $oscar_cfg = $configurator->get_config ();

    require OSCAR::Logger;

    my $db_type = $oscar_cfg->{'db_type'};
    if ($db_type eq "db") {
        # We initialize the database if needed
        if (init_db ($configurator)) {
            carp "ERROR: impossible to initialize the database\n";
            return -1;
        }
    } elsif ($db_type eq "file") {
        # We initialize the database if needed
        if (init_file_db ()) {
            carp "ERROR: impossible to initialize the file based database\n";
            return -1;
        }
    }

    # OSCAR::Opkg requires XML::Simple which is not available initially but 
    # after prereq installation
    require OSCAR::Opkg;

    # Get the list of just core packages
    my @core_opkgs = OSCAR::Opkg::get_list_core_opkgs();
    if (scalar (@core_opkgs) == 0) {
        carp "ERROR: Failed to get core packages list";
        return -1;
    }

    OSCAR::Logger::oscar_log_subsection("Identified core packages: " . 
        join(' ', @core_opkgs));

    OSCAR::Logger::oscar_log_section("Installing server core packages");
    if (OSCAR::Opkg::opkgs_install ("server", @core_opkgs)) {
        carp "ERROR: Impossible to install server core packages\n";
        return -1;
    }
    OSCAR::Logger::oscar_log_subsection(
        "Successfully installed server core binary packages");

    return 0;
}

################################################################################
# Stage 0 of the bootstrap: install AppConfig, needed for the parsing of the   #
# OSCAR configuration file. Note that to install this prereq, we need to know  #
# were are the prereqs, information included in the configuration file. In     #
# other terms, we have there a chicken/egg issue. To address the issue, we     #
# implement a simple parsing mechanism that is only looking for few variables  #
# in the configuration file in order to be able to locate and install the      #
# AppConfig prereq. Then we parse the configuration creating a ConfigManager   #
# object.                                                                      #
#                                                                              #
# Input: None.                                                                 #
# Return: a ConfigManager object if success, undef else.                       #
################################################################################
sub bootstrap_stage0 () {
    my $configfile_path = "/etc/oscar/oscar.conf";

    # Tricky situation: the software to parse the configuration file may not be
    # installed and the location of the information to install it is in the 
    # config file. Hopefully we know that the configuration file is 
    # /etc/oscar/oscar.conf (it can be generated setting OSCAR_HOME and then
    # executing $OSCAR_HOME/scripts/oscar-config --generate-config-file.
    if ( ! -f "$configfile_path") {
        carp "ERROR: impossible to find the oscar configuration file";
        return undef;
    }

    # We quickly parse the file to get the lines we are looking for
    open(MYFILE, $configfile_path);
    my $line;
    my ($var, $path, $ippath, $prereq_mode);
    while ($line = <MYFILE>) {
        chomp ($line);
        # delete BOTH leading and trailing whitespace from each line
        if ($line =~ /^([ \t]*)PREREQS_PATH/) {
            ($var, $path) = split ("=", $line);
        }
        if ($line =~ /^([ \t]*)OSCAR_SCRIPTS_PATH/) {
            ($var, $ippath) = split ("=", $line);
        }
        if ($line =~ /^([ \t]*)PREREQ_MODE/) {
            ($var, $prereq_mode) = split ("=", $line);
            require OSCAR::Utils;
            $prereq_mode = OSCAR::Utils::trim ($prereq_mode);
        }
    }
    close (MYFILE);

    # Now that we know where the prereqs are, we try to install AppConfig
    $ipcmd = $ippath . "/install_prereq ";
    print "install_prereq found: $ipcmd\n";
    my $appconfig_path = $path . "/AppConfig";
    if (bootstrap_prereqs ($appconfig_path, $prereq_mode)) {
        carp "ERROR: impossible to install appconfig\n";
        return undef;
    }

    # Then we can load the configuration!
    require OSCAR::ConfigManager;
    my $oscar_configurator = OSCAR::ConfigManager->new(
        config_file => "$configfile_path");
    return $oscar_configurator;
}

################################################################################
# Stage 1 of the bootstrap: install everything we need to be able to install   #
# binary packages "smartly". For that we install packman, yume and rapt (rapt  #
# is installed only on Debian based systems). We also save of binary packages  #
# installed on the system before the installation of OSCAR (except for         #
# AppConfig); this is useful for developers to start over.                     #
#                                                                              #
# Input: configurator, a ConfigManager object representing the content of the  #
#                      OSCAR configuration file.                               #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: the list of pre-oscar binary packages is currently saved in            #
# /etc/oscar, this is not the path were such a file was previously created.    #
################################################################################
sub bootstrap_stage1 ($) {
    my $configurator = shift;
    if (!defined $configurator) {
        carp "ERROR: Invalid configurator object.\n";
        return -1;
    }
    my $config = $configurator->get_config();

    # First we install Packman
    my $packman_path = $config->{'packman_path'};
    if (! defined ($packman_path) || ($packman_path eq "")) {
        carp "ERROR: Impossible to get the Packman path\n";
        return -1;
    }

    my $prereq_mode = $config->{'prereq_mode'};
    if (bootstrap_prereqs ($packman_path, $prereq_mode)) {
        carp "ERROR: Impossible to install Packman\n";
        return -1;
    }

    use lib "$ENV{OSCAR_HOME}/lib";
    require OSCAR::OCA::OS_Detect;
    my $os = OSCAR::OCA::OS_Detect::open();
    if (!defined $os) {
        carp "ERROR: Impossible to detect the local Linux distribution\n";
        return -1;
    }
    # hack...
    # EF: will move to install_prereqs [shell]
    if ($os->{pkg} eq "rpm") {
        system("yum clean all");
    }

    # We save the list of binary packages before to really install stuff
    # This is useful for developers when they want to start over
    # TODO the location of the file we save is hardcoded, this is bad, We should
    # be able to specify that path via the OSCAR configuration file
    my $path = "/etc/oscar";
    mkdir $path if (! -d $path);
    if (save_preoscar_binary_list ($os, $path)) {
        carp "ERROR: Impossible to save the list of preoscar binary ".
             "packages.\n";
        return -1;
    }

    # Then we install YUME (supported on both rpm and deb systems).
    my $yume_path = $config->{'yume_path'};
    if (bootstrap_prereqs ($yume_path, $prereq_mode)) {
        carp "ERROR: Impossible to install Yume\n";
        return -1;
    }

    # Then if the system is a Debian based system, we try to install RAPT
    if ($os->{pkg} eq "deb") {
        my $rapt_path = $config->{'rapt_path'};
        if (bootstrap_prereqs ($rapt_path, $prereq_mode)) {
            carp "ERROR: Impossible to install RAPT\n";
            return -1;
        }
    }

    # Finally, since everything is installed to manage packages in the "smart
    # mode", we prepare all the pools for the local distro.
    require OSCAR::PackageSmart;
    my $pm = OSCAR::PackageSmart::prepare_distro_pools($os);
    if (!defined ($pm)) {
        carp "ERROR: Impossible to prepare pools for the local distro\n";
        return -1;
    }

    return 0;
}

################################################################################
# Stage 2 of the bootstrap: installs base prereqs and the prereqs based on the #
# prereqs.order file, then install the OSCAR headnode (database initialization #
# and so on).                                                                  #
#                                                                              #
# Input: configurator, a ConfigManager object which represents values of the   #
#        OSCAR configuration file.                                             #
# Return: o if success, -1 else.                                               #
#                                                                              #
# TODO: the prereqs.order isntalls also GUI related prereqs which are not used #
# when using only the CLI. The GUI prereqs should be installed separately.     #
################################################################################
sub bootstrap_stage2 ($) {
    my $configurator = shift;
    if (!defined $configurator) {
        carp "ERROR: Invalid configurator object.\n";
        return -1;
    }
    my $config = $configurator->get_config();

    # First we install the basic prereqs
    my $baseprereqs_path = $config->{'prereqs_path'} . "/base";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($baseprereqs_path, $prereq_mode)) {
        carp "ERROR: impossible to install base prereqs ($baseprereqs_path)\n";
        return -1;
    }

    # Then we install other prereqs, based on the ordering file.
    # For that, read in the share/prereqs/prereqs.order file
    # It should contain prerequisite paths relative to $OSCAR_HOME, one per 
    # line.
    my $prereqs_path = $config->{'prereqs_path'};
    my $prereq_mode = $config->{'prereq_mode'};
    my $orderfile = "$prereqs_path/prereqs.order";
    my @ordered_prereqs;
    if (! -f "$orderfile") {
        carp "ERROR: Impossible to find the prereq ordering file".
              " ($orderfile)\n";
        return -1;
    }
    open(MYFILE, $orderfile);
    my $line;
    my @ordered_prereqs;
    while ($line = <MYFILE>) {
        chomp ($line);
        # delete BOTH leading and trailing whitespace from each line
        next if ($line =~ /^([ \t]*)#/);
        push (@ordered_prereqs, $line);
    }
    close (MYFILE);
    foreach my $prereq (@ordered_prereqs) {
        # TODO: ODA is both a prereq and a OPKG, this is a big mess!!!
        my $path;
        if ($prereq ne "packages/oda") {
            $path = "$prereqs_path/" . basename ($prereq);
        } else {
            $path = $prereq;
        }
        if (install_prereq ($path, $prereq_mode)) {
            carp "ERROR: Impossible to install a prereq ($path).\n";
            return -1;
        }
    }

    if ($config->{db_type} eq "db") {
        # we initialize the database if needed
        require OSCAR::Database_generic;
        OSCAR::Database_generic::init_database_passwd($configurator);
    }

    # Then we try to install the server side of OSCAR
    if (init_server ($configurator)) {
        carp "ERROR: Impossible to install the server side of OSCAR\n";
        return -1;
    }
}

################################################################################
# Function that saves the list of currently installed binary packages. Works   #
# for both RPM and Debian based systems. This is used to get the list of       #
# pre-oscar binary packages, used to start over when doing OSCAR testing. If   #
# the file already exists, we skip this phase.                                 #
#                                                                              #
# Input: os, an OS_Detect hash representing the current Linux distribution.    #
#        tmpdir, the path where the file has to be created.                    #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: we create two different files for RPM and Debian based systems. It     #
# does make much sense. We should only create one with a generic name and      #
# check the existence of this file at the very beginning of the function (if   #
# the function exists, just exist).                                            #
################################################################################
sub save_preoscar_binary_list ($$) {
    my ($os, $tmpdir) = @_;

    require OSCAR::Logger;
    # remember all packages which were on the system before OSCAR installation
    # (used by start_over to protect system files)
    if ($os->{pkg} eq "rpm") {
        my $preoscar = "$tmpdir/pre-oscar.rpmlist";
        if (! -f $preoscar) {
            OSCAR::Logger::oscar_log_subsection("Writing pre-oscar rpmlist...");
            system("rpm -q --qf '%{NAME}\n' --all | sort | uniq > $preoscar");
        }
    } elsif ($os->{pkg} eq "deb") {
        my $preoscar = "$tmpdir/pre-oscar.deblist";
        if (! -f $preoscar) {
            my $cmd =  
                "(dpkg -l | grep '^ii' | awk ' { print \$2 } ' | sort | uniq) > $preoscar";
            print "Writing pre-oscar deblist ($preoscar): $cmd...\n";
            OSCAR::Logger::oscar_log_subsection(
                "Writing pre-oscar deblist ($preoscar)...");
            system($cmd);
        }
    } else {
        carp "ERROR: Unknow binary format ($os->{pkg})\n";
        return -1;
    }

    return 0;
}

1;

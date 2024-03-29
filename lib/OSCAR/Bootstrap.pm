package OSCAR::Bootstrap;

#
# Copyright (c) 2007-2008 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use File::Basename;
use OSCAR::Env;
use Carp;

use OSCAR::Opkg;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::SystemServicesDefs;
use OSCAR::Utils;

@EXPORT = qw (
                oscar_bootstrap
                install_prereq
             );
#                load_oscar_config

our $ippath;

our $prereq_mode;

# Specify where the install_prereq script is
our $ipcmd;

# Specify where the install_server script is
our $iscmd;

our $prereq_path;

my $configfile_path = "/etc/oscar/oscar.conf";


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
sub oscar_bootstrap () {

    my $configurator = bootstrap_stage0();
    if (!defined $configurator) {
        oscar_log(1, ERROR, "Failed to complete stage 0 of the bootstrap.");
        return -1;
    }

    if (bootstrap_stage1($configurator)) {
        oscar_log(5, ERROR, "Failed to complete stage 1 of the bootstrap.");
        return -1;
    }

    if (bootstrap_stage2($configurator)) {
        oscar_log(5, ERROR, "Failed to complete stage 2 of the bootstrap.");
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
#        prereq_mode The mode in which is when to deal with prereqs            #
#                    ("check_only" or "check_and_fix").                        #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub install_prereq ($$$) {
    my ($prereq_cmd, $prereq_path, $prereq_mode) = @_;
    my $cmd;

    # We get the current status of the prereq first
    $cmd = $prereq_cmd . " --status " . $prereq_path;
    my $prereq_name = basename ($cmd);
    oscar_log(5, INFO, "Dealing with Prereq $prereq_name");
    require OSCAR::PrereqsDefs;
    my $rc = oscar_system ($cmd);
    if ($rc == OSCAR::PrereqsDefs::PREREQ_MISSING()) {
        OSCAR::Logger::oscar_log_subsection "$prereq_name is not installed.";

        if ($prereq_mode eq "check_only") {
            OSCAR::Logger::oscar_log_subsection "INFO: Please install the ".
                "prereq $prereq_name manually\n";
            return 0;
        }
        # We try to install the prereq
        oscar_log(5, INFO, "Trying to install Prereq $prereq_name.");
        $cmd = $prereq_cmd . " --smart " . $prereq_path;
        if (oscar_system ($cmd)) {
            oscar_log(1, ERROR, "Impossible to install $prereq_name ($cmd).");
            return -1;
        }

        # Packman should be installed now
        $cmd = $prereq_cmd . " --status " . $prereq_path;
        $rc = oscar_system ($cmd);
        if ($rc == OSCAR::PrereqsDefs::PREREQ_MISSING()) {
            oscar_log(1, ERROR, "$prereq_name is still not installed ($rc)");
            return -1;
        }
    } elsif ($rc == OSCAR::PrereqsDefs::PREREQ_INVALID()) {
        oscar_log(1, ERROR, "Prereq $prereq_name not found.");
        oscar_log(5, ERROR, "Impossible to install $prereq_name ($cmd).");
	return -1;
    } elsif ($rc == OSCAR::PrereqsDefs::PREREQ_BADUSE()) {
        oscar_log(1, ERROR, "Failed to run ($cmd). Bad syntax: Please report bug!");
        oscar_log(5, ERROR, "Impossible to install $prereq_name ($cmd).");
	return -1;
    } elsif ($rc == OSCAR::PrereqsDefs::PREREQ_INSTALLED()) {
        oscar_log(2, INFO, "Prereq $prereq_name already installed. Nothing to do.");
        return 0;
    } else {
	oscar_log(1, ERROR, "Unknown return code from ($cmd): $rc");
	oscar_log(1, ERROR, "Please report bug!");
    }

    oscar_log(1, INFO, "Successfully installed Prereq $prereq_name");

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
    my $rc;

    # We get the current status of the prereq first
    $cmd = $ipcmd . " --status " . $prereq_path;
    my $prereq_name = basename ($prereq_path);
    oscar_log(5, INFO, "Dealing with Prereq $prereq_name" .
        "($prereq_path, $prereq_mode)");
    require OSCAR::PrereqsDefs;
    oscar_log(5, ACTION, "About to run: $cmd");
    my $rc = system ($cmd); # Cannot use oscar_system as rc=1 is still OK.
    if ($rc == OSCAR::PrereqsDefs::PREREQ_MISSING()) {
        OSCAR::Logger::oscar_log_subsection "$prereq_name is not installed.";

        if ($prereq_mode eq "check_and_fix") {
            # We try to install Packman
            $cmd = $ipcmd . " --dumb " . $prereq_path;
            oscar_log(5, ACTION, "About to run: $cmd");
            if (system ($cmd)) {
                oscar_log(5, ERROR, "Impossible to install $prereq_name ($cmd).");
                return -1;
            }

            # Packman should be installed now
            $cmd = $ipcmd . " --status " . $prereq_path;
            oscar_log(5, ACTION, "About to run: $cmd");
            my $rc = system ($cmd);
            if ($rc == OSCAR::PrereqsDefs::PREREQ_MISSING()) {
                oscar_log(1, ERROR, "$prereq_name installation failed.");
                return -1;
            } else {
                oscar_log(1, INFO, "$prereq_name installed.")
	    }
        } elsif ($prereq_mode eq "check_only") {
            oscar_log(3, INFO, "$prereq_name needs to be installed.");
            return -1;
        }
    } else {
        oscar_log(1, INFO, "$prereq_name is already installed, nothing to do.");
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
    oscar_log(1, SUBSECTION, "Initializing server...");
    if (!defined ($configurator)) {
        oscar_log(5, ERROR, "Invalid configurator object.");
        return -1;
    }
    my $oscar_cfg = $configurator->get_config ();

    require OSCAR::Logger;

    #
    # First, we need to bootstrap ODA.
    #

    my $db_type = $oscar_cfg->{'db_type'};
    oscar_log(1, INFO, "Bootstrapping ODA using: " . $db_type);

    my $cmd = $oscar_cfg->{'binaries_path'} . "/oda --init ";
    if (defined ($db_type)) {
        $cmd .= "$db_type";
    } else {
        # By default, we still assume that we are using mysql.
        $cmd .= "mysql";
    }
    if (oscar_system ($cmd)) {
        oscar_log(5, ERROR, "Failedto execute $cmd");
        return -1;
    }

    oscar_log(1, INFO, "Successfully Bootstrapped ODA.");

    #
    # Now that ODA is initialized, we can initialize its content.
    #

    # We save data about the NIC used by OSCAR. 
    # Warning! set_global_oscar_value, create_and_populate_basic_node_info and
    # populate_default_package_set must be called in the order described below.

    # The "set_global_oscar_values" scripts populates the following
    # tables: Clusters, Groups, and Status
    oscar_log(1, SUBSECTION, "Setting all the OSCAR global values");
    my $exit_status;
    oscar_log(1, INFO, " - set_global_oscar_values...");
    my $interface = $oscar_cfg->{'nioscar'};
    if (defined $ENV{OSCAR_HOME}) {
        $cmd = "$ENV{OSCAR_HOME}/scripts/set_global_oscar_values ".
               "--interface $interface";
    } else {
        $cmd = $oscar_cfg->{'binaries_path'}."/set_global_oscar_values ".
               "--interface $interface";
    }
    if ($OSCAR::Env::oscar_verbose >= 10) {
        $cmd .= "  --debug";
    }
    $exit_status = oscar_system($cmd);
    if ($exit_status) {
        oscar_log(5, ERROR, "Couldn't initialize the global database values table ".
              "($cmd, $exit_status)");
        return -1;
    }

    oscar_log(1, INFO, " - create_and_populate_basic_node_info...");
    $cmd = $oscar_cfg->{'binaries_path'}."/create_and_populate_basic_node_info";
    if (oscar_system ($cmd)) {
        return -1;
    }

    # Storing data about package sets.
    oscar_log(1, INFO, " - populate_default_package_set...");
    $cmd = $oscar_cfg->{'binaries_path'}."/populate_default_package_set";
    oscar_log(7, ACTION, "About to run: $cmd");
    my $exit_status = oscar_system($cmd);
    if ($exit_status) {
        oscar_log(5, ERROR, "Couldn't set up a default package set ($exit_status)");
        return -1;
    }

    #### NEW OPKG BOOTSTRAP: install all api pkgs so all config.xml files are available
    oscar_log(1, INFO, "Installing all available api packages..");
    require OSCAR::OpkgDB;
    my @all_opkgs = OSCAR::OpkgDB::opkg_list_available(class => "all");
    oscar_log(1, INFO, "Available api opkgs: " . join(' ', @all_opkgs));

    # We install all OPKGs in a raw. In case of failure, opkgs_install is smart enough
    # to collect the error. (Anyway, api opkgs have no deps, so there is no reason for failure.
    return -1 if (OSCAR::Opkg::opkgs_install ("api", @all_opkgs));
 
    oscar_log(1, INFO, "API opkgs installed.");
    #### END NEW OPKG BOOTSTRAP

    oscar_log(2, INFO, "Working on core opkgs.");
    # Get the list of just core packages
    my @core_opkgs = OSCAR::Opkg::get_list_core_opkgs();
    if (scalar (@core_opkgs) == 0) {
        oscar_log(5, ERROR, "Failed to get core packages list");
        return -1;
    }

    oscar_log(4, INFO, "Identified core packages: " . 
        join(' ', @core_opkgs));
    if (scalar (@core_opkgs) == 0) {
        oscar_log(5, ERROR, "No core packages found");
        return -1;
    }
    OSCAR::Utils::print_array (@core_opkgs) if($OSCAR::Env::oscar_verbose >= 9);

    # We install one OPKG at a time so if the installation of one OPKG fails,
    # we can track it in details.
#    my @failed_opkgs;
    # We start with the server side of all core OPKGs
#    foreach my $o (@core_opkgs) {
#        if (OSCAR::Opkg::opkgs_install ("server", $o)) {
#            push (@failed_opkgs, $o);
#        }
#    }
#    if (scalar (@failed_opkgs) > 0) {
#        oscar_log(5, ERROR, "Impossible to install the following core OPKGs (server ".
#             " side): ".join (" ", @failed_opkgs));
#        return -1;
#    }
    # Then we install the API side of all core OPKGs
#    foreach my $o (@core_opkgs) {
#        if (OSCAR::Opkg::opkgs_install ("api", $o)) {
#            push (@failed_opkgs, $o);
#        }
#    }
#    if (scalar (@failed_opkgs) > 0) {
#        oscar_log(5, ERROR, "Impossible to install the following core OPKGs (API ".
#             " side): ".join (" ", @failed_opkgs));
#        return -1;
#    }

    oscar_log(1, INFO, "Marking core packages as always selected...");
    my %selection_data = ();
    # We call ODA_Defs only here to avoid bootstrapping issues.
    # We get the list of OPKGs in the package set
    require OSCAR::PackagePath;
    require OSCAR::PackageSet;
    my $distro = OSCAR::PackagePath::get_distro ();
    my $compat_distro = OSCAR::PackagePath::get_compat_distro ($distro);
    my @available_opkgs
        = OSCAR::PackageSet::get_list_opkgs_in_package_set ('Experimental',
                                                            $compat_distro);
    require OSCAR::ODA_Defs;
    my $selected = OSCAR::ODA_Defs::SELECTED();
    my $unselected = OSCAR::ODA_Defs::UNSELECTED();

    require OSCAR::OCA::OS_Detect;
    my $os = OSCAR::OCA::OS_Detect::open();
    # TODO: Do that in setup script in opkg-rapt and opkg-yume
    #foreach my $opkg (@available_opkgs) {
    #    next if ($os->{pkg} eq "rpm" and $opkg eq 'rapt');  # Done in setup phase of the opkg
    #    next if ($os->{pkg} eq "deb" and $opkg eq 'yume');  # Done in setup phase of the opkg
    #    $selection_data{$opkg} = (grep(/$opkg/,@core_opkgs)?$selected:$unselected);
    #}

    OSCAR::Database::set_opkgs_selection_data (%selection_data);
    # BUG: Check return of above function.
    oscar_log(1, INFO, "Successfully set core opkgs as always selected.");

    oscar_log(1, INFO, "Running opkg setup phase (api-pre-install script).");
    # Run the setup phase to allow opkg to self disable (set itself uninstallable)
    my @failed_opkgs_setup = ();
    foreach my $o (@all_opkgs) {
        if(!OSCAR::Package::run_pkg_script($o, "setup", 1, "")) {
            oscar_log(1, ERROR, "Couldn't run setup script 'api-pre-install' for $o");
            push (@failed_opkgs_setup, $o);
        } else {
            oscar_log(6, INFO, "Setup for opkg-$o completed successfully.");
        }
    }

    if (scalar (@failed_opkgs_setup) > 0) {
        oscar_log(5, ERROR, "Setup script failed for the following OPKGs (API side): " .
		join (" ", @failed_opkgs_setup));
        return -1;
    }

    oscar_log(1, INFO, "API opkgs install and setup phase complete.");

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
    oscar_log(1, SUBSECTION, "Running bootstrap stage 0");
    # Tricky situation: the software to parse the configuration file may not be
    # installed and the location of the information to install it is in the 
    # config file. Hopefully we know that the configuration file is 
    # /etc/oscar/oscar.conf (it can be generated setting OSCAR_HOME and then
    # executing $OSCAR_HOME/scripts/oscar-config --generate-config-file.
    if ( ! -f "$configfile_path") {
        oscar_log(5, ERROR, "OSCAR config file does not exist ($configfile_path)");
        return undef;
    }

    # We quickly parse the file to get the lines we are looking for
    open(MYFILE, $configfile_path);
    my $line;
    my ($var);
    while ($line = <MYFILE>) {
        chomp ($line);
        # delete BOTH leading and trailing whitespace from each line
        if ($line =~ /^([ \t]*)PREREQS_PATH/) {
            ($var, $prereq_path) = split ("=", $line);
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
    oscar_log(3, INFO, "install_prereq found: $ipcmd");
    my $appconfig_path = $prereq_path . "/AppConfig";
    if (bootstrap_prereqs ($appconfig_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Failed to install appconfig");
        return undef;
    }

    # Then we can load the configuration!
    require OSCAR::ConfigManager;
    my $oscar_configurator = OSCAR::ConfigManager->new(
        config_file => "$configfile_path");

    # Then we check if all configuration files /tftpboot are there or not. If
    # not, if create files with the default repositories.
    require OSCAR::PackagePath;
    require OSCAR::OCA::OS_Detect;
    my $os = OSCAR::OCA::OS_Detect::open ();
    if (!defined $os) {
        oscar_log(5, ERROR, "Unable to identify the local distro.");
        return undef;
    }
    my $distro = $os->{distro};
    my $version = $os->{distro_version};
    my $arch = $os->{arch};
    my $distro_id = "$distro-$version-$arch";
    # BUG: OL: Already done in setup-distro?
    if (OSCAR::PackagePath::generate_default_urlfiles ($distro_id) == -1) {
        oscar_log(5, ERROR, "Unable to generate default url files in /tftpboot");
        return undef;
    }

    # Finally we run oscar-updater to be sure that we are in a coherent config
    require OSCAR::ConfigFile;
    my $binaries_path = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf",
                                                      undef,
                                                      "OSCAR_SCRIPTS_PATH");
    my $cmd = "$binaries_path/oscar-updater";
    if (oscar_system ($cmd)) {
        oscar_log(1, ERROR, "Failed to execute oscar-updater");
        exit 1;
    }

    oscar_log(1, INFO, "Bootstrap stage 0 successfull");
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
    oscar_log(1, SUBSECTION, "Running bootstrap stage 1");
    if (!defined $configurator) {
        oscar_log (5, ERROR, "Invalid configurator object.");
        return -1;
    }
    my $config = $configurator->get_config();

    # First we install Packman
    my $packman_path = $config->{'packman_path'};
    if (! defined ($packman_path) || ($packman_path eq "")) {
        oscar_log(5, ERROR, "Impossible to get the Packman path.");
        return -1;
    }

    my $prereq_mode = $config->{'prereq_mode'};
    oscar_log(1, INFO, "Installing packman");
    if (bootstrap_prereqs ($packman_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install Packman.");
        return -1;
    }

    require OSCAR::OCA::OS_Detect;
    my $os = OSCAR::OCA::OS_Detect::open();
    if (!defined $os) {
        oscar_log(5, ERROR, "Impossible to detect the local Linux distribution");
        return -1;
    }
    # hack...
    # EF: will move to install_prereqs [shell]
    if ($os->{pkg} eq "rpm") {
        oscar_system("yum clean all");
    }

    # We save the list of binary packages before to really install stuff
    # This is useful for developers when they want to start over
    # TODO the location of the file we save is hardcoded, this is bad, We should
    # be able to specify that path via the OSCAR configuration file
    # DEPRECATED when using the new startover mechanism
    oscar_log(1, INFO, "Keep track of currently installed packages. (obsolete)");
    my $path = "/etc/oscar";
    mkdir $path if (! -d $path);
    if (save_preoscar_binary_list ($os, $path)) {
        oscar_log(5, ERROR, "Impossible to save the list of preoscar binary ".
             "packages.");
        return -1;
    }

    # Then we install YUME (supported on both rpm and deb systems).
    oscar_log(1, INFO, "Installing yume");
    my $yume_path = $config->{'yume_path'};
    if (bootstrap_prereqs ($yume_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install Yume");
        return -1;
    }

    # Then if the system is a Debian based system, we try to install RAPT
    if ($os->{pkg} eq "deb") {
        oscar_log(1, INFO, "Also installing rapt");
        my $rapt_path = $config->{'rapt_path'};
        if (bootstrap_prereqs ($rapt_path, $prereq_mode)) {
            oscar_log(5, ERROR, "Impossible to install RAPT");
            return -1;
        }
    }

    # Finally, since everything is installed to manage packages in the "smart
    # mode", we prepare all the pools for the local distro.
    oscar_log(1, INFO, "Preparing local distro pools");
    require OSCAR::PackageSmart;
    my $pm = OSCAR::PackageSmart::prepare_distro_pools($os);
    if (!defined ($pm)) {
        oscar_log(5, ERROR, "Impossible to prepare pools for the local distro");
        return -1;
    }

    # Now we try to install ORM
    oscar_log(1, INFO, "Installing ORM");
    my $orm_prereqs_path = $config->{'prereqs_path'} . "/ORM";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $orm_prereqs_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install ORM prereqs ($orm_prereqs_path)");
        return -1;
    }

    # Now we try to install apitest
    oscar_log(1, INFO, "Installing apitest");
    my $apitest_prereqs_path = $config->{'prereqs_path'} . "/apitest";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $apitest_prereqs_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install apitest prereqs ($apitest_prereqs_path)");
        return -1;
    }

   # Now we try to install perl-GUIDeFATE
    oscar_log(1, INFO, "Installing perl-GUIDeFATE.");
    my $selector_prereqs_path = $config->{'prereqs_path'} . "/perl-GUIDeFATE";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $selector_prereqs_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install perl-GUIDeFATE prereqs ".
             "($selector_prereqs_path)");
        return -1;
    }

    # Now we try to install Selector
    oscar_log(1, INFO, "Installing selector.");
    my $selector_prereqs_path = $config->{'prereqs_path'} . "/Selector";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $selector_prereqs_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install Selector prereqs ".
             "($selector_prereqs_path)");
        return -1;
    }

    # Now we try to install Configurator
    oscar_log(1, INFO, "Installing configurator.");
    my $configurator_prereqs_path = $config->{'prereqs_path'} . "/Configurator";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $configurator_prereqs_path, $prereq_mode)) {
        carp "ERROR: impossible to install Configurator prereqs ".
             "($configurator_prereqs_path)\n";
        return -1;
    }

    oscar_log(1, INFO, "Bootstrap stage 1 successfull");
    return 0;
}

################################################################################
# Stage 2 of the bootstrap: installs base prereqs and the prereqs based on the #
# prereqs.order file, then install the OSCAR headnode (database initialization #
# and so on).                                                                  #
#                                                                              #
# Input: configurator, a ConfigManager object which represents values of the   #
#        OSCAR configuration file.                                             #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: the prereqs.order isntalls also GUI related prereqs which are not used #
# when using only the CLI. The GUI prereqs should be installed separately.     #
################################################################################
sub bootstrap_stage2 ($) {
    my $configurator = shift;
    oscar_log(2, SUBSECTION, "Running bootstrap stage 2");
    if (!defined $configurator) {
        oscar_log(5, ERROR, "Invalid configurator object.");
        return -1;
    }
    my $config = $configurator->get_config();

    # First we install the basic prereqs
    oscar_log(1, INFO, "Installing base (core) prereqs");
    my $baseprereqs_path = $config->{'prereqs_path'} . "/base";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $baseprereqs_path, $prereq_mode)) {
        oscar_log(5, ERROR, "Impossible to install base prereqs ($baseprereqs_path)");
        return -1;
    }

    oscar_log(1, INFO, "Installing ODA prereqs.");
    my $odaprereqs_path = $config->{'prereqs_path'} . "/OSCAR-Database";
    my $prereq_mode = $config->{'prereq_mode'};
    if (install_prereq ($ipcmd, $odaprereqs_path, $prereq_mode)) {
        carp "ERROR: impossible to install ODA prereqs ($odaprereqs_path)\n";
        return -1;
    }
    #oscar_log(6, INFO, "Bootstrapping ODA using: " . MYSQL);

 
    # Then we install other prereqs, based on the ordering file.
    # For that, read in the share/prereqs/prereqs.order file
    # It should contain prerequisite paths relative to $OSCAR_HOME, one per 
    # line.
    my $prereqs_path = $config->{'prereqs_path'};
    oscar_log(1, INFO, "Installing other prereqs from $prereqs_path/prereqs.order");
    my $prereq_mode = $config->{'prereq_mode'};
    my $orderfile = "$prereqs_path/prereqs.order";
    my @ordered_prereqs;
    if (! -f "$orderfile") {
        oscar_log(1, ERROR, "Impossible to find the prereq ordering file".
              " ($orderfile)");
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
        oscar_log(1, INFO, "Installing prereq: $prereq");
        my $path = $prereq_path . "/" . basename ($prereq);
        if (install_prereq ($ipcmd, $path, $prereq_mode)) {
            oscar_log(1, ERROR, "Impossible to install a prereq ($path).");
            return -1;
        }
    }

    # Then we try to install the server side of OSCAR
    oscar_log(5, INFO, "Now installing server side of OSCAR.");
    if (init_server ($configurator)) {
        oscar_log(5, ERROR, "Impossible to install the server side of OSCAR");
        return -1;
    }
    oscar_log(1, INFO, "Bootstrap stage 2 successfull");
    return 0;
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
# DEPRECATED by the new startover mechanism.                                   #
################################################################################
sub save_preoscar_binary_list ($$) {
    my ($os, $tmpdir) = @_;

    require OSCAR::Logger;
    # remember all packages which were on the system before OSCAR installation
    # (used by start_over to protect system files)
    if ($os->{pkg} eq "rpm") {
        my $preoscar = "$tmpdir/pre-oscar.rpmlist";
        if (! -f $preoscar) {
            oscar_log(5, INFO, "Writing pre-oscar rpmlist...");
            my $cmd = "rpm -q --qf '%{NAME}\n' --all | sort | uniq > $preoscar";
            if (oscar_system ($cmd)) {
                oscar_log(5, ERROR, "Failed to create the $tmpdir/pre-oscar.rpmlist");
                return -1;
            }
        }
    } elsif ($os->{pkg} eq "deb") {
        my $preoscar = "$tmpdir/pre-oscar.deblist";
        if (! -f $preoscar) {
            oscar_log(5, ERROR, "Writing pre-oscar deblist ($preoscar)...");
            my $cmd =  "(dpkg -l | grep '^ii' | awk ' { print \$2 } ' | sort | uniq) > $preoscar";
            if (oscar_system ($cmd)) {
                oscar_log(5, ERROR, "Failed to create the $tmpdir/pre-oscar.deblist");
                return -1;
            }
        }
    } else {
        oscar_log(5, ERROR, "Unknow binary format ($os->{pkg}).\nCan't backup list of installed packages.");
        return -1;
    }

    return 0;
}

1;

__END__

=head1 NAME

Bootstrap.pm - A set of functions for the OSCAR bootstrapping.

=head1 SYNOPSIS

This Perl modules gathers all functions and mechanisms to be able to bootstrap
OSCAR. Two main functions for that are:
    bootstrap_stage0 and oscar_bootstrap
Typically, bootstrap_stage0 is in charge of installing the minimum software that
is mandatory in order to really start to bootstrap OSCAR and oscar_bootstrap
installs needed software for OSCAR, using basic tools.
Note that the behavior of the bootstrapping is defined by the
/etc/oscar/oscar.conf configuration file: if PREREQ_MODE is set to
"check_and_fix" the prereqs are automatically installed; if PREREQ_MODE is set
to "check_only", the bootstrapping mechanism will display a message to the user
describing what needs to be done.

=head1 bootstrap_stage0

This function does not need any parameter. Since OSCAR is based on a 
configuration file (/etc/oscar/oscar.conf), this function typically installs
software to be able to parse this configuration file (i.e., AppConfig). When
this package is installed, it parses the configuration file (using 
OSCAR::ConfigManager) and returns a reference to a OSCAR::ConfigManager object
(undef in case of errors).
Also note that before to return that reference, basic configuration files are
created if they do not already exist (configuration files in /tftpboot).

=head1 oscar_bootstrap

The actual OSCAR bootstrap is actually composed of 2 stages:

=over 4

=item - stage1: During this stage, we install: packman, yume, rapt and then, based
on these tools, we generate local OSCAR repositories (if local repositories 
exist).

=item - stage2: During this stage, we install "base" prereqs and all prereqs
based on the prereq order from "prereqs.order". Then, we initialize the 
database, installing ODA and initializing the database password. Finally, we
install OSCAR core server packages.

=back

=head1 AUTHOR

Geoffroy Vallee <valleegr@ornl.gov>

=head1 SEE ALSO

perl(1), OSCAR::ConfigManager

=cut

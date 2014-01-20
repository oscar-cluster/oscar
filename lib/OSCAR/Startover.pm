package OSCAR::Startover;

#
# Copyright (c) 2000-2010 Geoffroy Vallee <valleegr at ornl dot gov>
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
# This package provides a set of functions for the OSCAR start_over, it 
# typically does the opposite from the bootstrapping.
# Note that we do not check most of the return code because we typically do not
# know if which state we stand and we want to be sure that we can remove 
# a maximum of OSCAR related stuff, even if in case of errors.

#
# $Id: Bootstrap.pm 7893 2009-01-23 00:26:12Z valleegr $
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
use Carp;

use OSCAR::ConfigManager;
use OSCAR::Logger;
use OSCAR::LoggerDefs;

@EXPORT = qw (
                remove_prereq
                start_over
             );

sub remove_prereq ($$) {
    my ($prereq_cmd, $prereq_path) = @_;
    my $cmd;

    oscar_log(3, SUBSECTION, "Removing prereqs");
    # We get the current status of the prereq first
    $cmd = $prereq_cmd . " --status " . $prereq_path;
    my $prereq_name = basename ($cmd);
    oscar_log(4, INFO, "Dealing with Prereq $prereq_name");
    if (oscar_system ($cmd)) {
        oscar_log(4, INFO, "$prereq_name is not installed.");
        return 0;
    } else {
        # We try to remove the prereq
        $cmd = $prereq_cmd . " --remove " . $prereq_path;
        if (oscar_system ($cmd)) {
            oscar_log(4, ERROR, "Failed to remove $prereq_name");
            return -1;
        }

        # Packman should be installed now
        $cmd = $prereq_cmd . " --status " . $prereq_path;
        if (!oscar_system ($cmd)) {
            oscar_log(4, ERROR, "$prereq_name is still installed");
            return -1;
        }
    }

    oscar_log(3, SUBSECTION, "Prereqs removed");
    return 0;
}

# Return: 0 if success, -1 else.
sub startover_server ($) {
    my $oscar_cfg = shift;

    if (-f $oscar_cfg->{'binaries_path'} . "/oda") {
        # Remove core packages. 
        require OSCAR::Opkg;
        my @core_opkgs = OSCAR::Opkg::get_list_core_opkgs();
        foreach my $o (@core_opkgs) {
            # TODO: We should check the status before to try to remove it.
            OSCAR::Opkg::opkgs_remove ("server", $o);
        }
	    foreach my $o (@core_opkgs) {
            OSCAR::Opkg::opkgs_remove ("api", $o);
        }

        # Remove all selected OPKGs (which does NOT include core OPKGs).
        my @selected = ();
        my %options = ();
        require OSCAR::Database;
        my $rc = OSCAR::Database::get_selected_packages (\@selected,
                                                         \%options,
                                                         undef,
                                                         undef);
        if ($rc != 1) {
            oscar_log(5, ERROR, "Unable to get the list of selected OPKGs");
            return -1;
        }
        foreach my $o (@selected) {
            OSCAR::Opkg::opkgs_remove ("server", $o);
            OSCAR::Opkg::opkgs_remove ("api", $o);
        }

        # Drop the OSCAR database
        my $cmd = $oscar_cfg->{'binaries_path'} . "/oda --reset";
        oscar_system ($cmd);
    } else {
        oscar_log(5, INFO, "ODA is not installed, we skip the ODA reset");
    }
    
    return 0;
}

sub startover_stage2 ($) {
    my $config = shift;
    if (!defined $config) {
        oscar_log(5, ERROR, "Invalid configurator object.");
        return -1;
    }

    # Remove server side of OSCAR
    if (startover_server ($config)) {
        oscar_log(5, ERROR, "Start over of the server side of OSCAR failed");
        return -1;
    }
    
    # Remove prereqs base on prereqs.order
    my $prereqs_path = $config->{'prereqs_path'};
    my $ipcmd = $config->{'binaries_path'}."/install_prereq ";
    my $prereq_mode = $config->{'prereq_mode'};
    my $orderfile = "$prereqs_path/prereqs.order";
    my @ordered_prereqs;
    if (! -f "$orderfile") {
        oscar_log(5, ERROR, "Can't to find the prereq ordering file".
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
        my $path = $prereqs_path . "/" . basename ($prereq);
        remove_prereq ($ipcmd, $path);
    }
    
    # Remove base prereqs
#    my $baseprereqs_path = $config->{'prereqs_path'} . "/base";
#    remove_prereq ($ipcmd, $baseprereqs_path);

    return 0;
}

sub startover_stage1 ($) {
    my $config = shift;
    if (!defined $config) {
        oscar_log(5, ERROR, "Invalid configurator object.");
        return -1;
    }

    use OSCAR::PackagePath;
    use OSCAR::Utils;
    my $distro = OSCAR::PackagePath::get_distro();
    if (!OSCAR::Utils::is_a_valid_string ($distro)) {
        oscar_log(5, ERROR, "Unable to detect the local distro");
        return -1;
    }
    my $compat_distro = OSCAR::PackagePath::get_compat_distro ($distro);
    if (!OSCAR::Utils::is_a_valid_string ($compat_distro)) {
        oscar_log(5, ERROR, "Unable to detect the compat distro");
        return -1;
    }

    my $prereqs_path = $config->{'prereqs_path'};
    my $ipcmd = $config->{'binaries_path'}."/install_prereq ";

    # Remove Configurator
    my $baseprereqs_path = $config->{'prereqs_path'} . "/Configurator";
    remove_prereq ($ipcmd, $baseprereqs_path);

    # Remove OSCAR_Database
    my $baseprereqs_path = $config->{'prereqs_path'} . "/OSCAR-Database";
    remove_prereq ($ipcmd, $baseprereqs_path);

    # Remove ORM
    my $baseprereqs_path = $config->{'prereqs_path'} . "/ORM";
    remove_prereq ($ipcmd, $baseprereqs_path);

    # Remove AppConfig
    my $baseprereqs_path = $config->{'prereqs_path'} . "/AppConfig";
    remove_prereq ($ipcmd, $baseprereqs_path);
    
    # Remove Yume & Rapt
#    my $os = OSCAR::OCA::OS_Detect::open();
#    if (!defined $os) {
#        carp "ERROR: Impossible to detect the local Linux distribution\n";
#        return -1;
#    }
#    if ($os->{pkg} eq "deb") {
#        my $rapt_path = $config->{'rapt_path'};
#        remove_prereq ($ipcmd, $rapt_path);
#    }
#    my $yume_path = $config->{'yume_path'};
#    remove_prereq ($ipcmd, $yume_path);

    # Remove PackMan
    my $packman_path = $config->{'packman_path'};
    if (! defined ($packman_path) || ($packman_path eq "")) {
        oscar_log(5, ERROR, "Unable to get the Packman path");
        return -1;
    }
    remove_prereq ($ipcmd, $packman_path);

    # Remove config file in /tftpboot
    my $file = "/tftpboot/distro/$compat_distro.url";
    if (-f $file) {
        OSCAR::Logger::oscar_log_subsection ("Removing $file...");
        unlink ($file) or (oscar_log(5, ERROR, "Failed to remove $file"),
                           return -1);
    }
    $file = "/tftpboot/oscar/$distro.url";
    if (-f $file) {
        OSCAR::Logger::oscar_log_subsection ("Removing $file...");
        unlink ($file) or (oscar_log(5, ERROR, "Failed to remove $file"),
                           return -1);
    }
    
    # We are done.
    return 0;
}

sub start_over () {
    my $configfile_path = "/etc/oscar/oscar.conf";
    my $oscar_configurator = OSCAR::ConfigManager->new(
        config_file => "$configfile_path");
    if (!defined $oscar_configurator) {
        oscar_log(5, ERROR, "Invalid configurator object.");
        return -1;
    }
    my $config = $oscar_configurator->get_config();
    

    if (startover_stage2 ($config)) {
        oscar_log(5, ERROR, "Failed to execute stage 2 of the start over process");
        return -1;
    }
    if (startover_stage1 ($config)) {
        oscar_log(5, ERROR, "Failed to execute stage 1 of the start over process");
        return -1;
    }
    return 0;
}

1;

package OSCAR::Bootstrap;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
#
#   $Id: ImageMgt.pm 4833 2006-05-24 08:22:59Z bli $
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

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use File::Basename;
use Carp;

@EXPORT = qw (
                bootstrap_stage0
                oscar_bootstrap
                load_oscar_config
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
        print "ERROR: invalid cofnigurator object\n";
        return -1;
    }

    if (bootstrap_stage1($configurator)) {
        print "ERROR: Impossible to complete stage 1 of the bootstrap.\n";
        return -1;
    }

    if (bootstrap_stage2($configurator)) {
        print "ERROR: Impossible to complete stage 2 of the bootstrap.\n";
        return -1;
    }
    return 0;
}

sub install_prereq ($) {
    my $prereq_path = shift;
    my $cmd;

    # We get the current status of the prereq first
    $cmd = $ipcmd . " --status " . $prereq_path;
    my $prereq_name = basename ($cmd);
    print "Dealing with Prereq $prereq_name\n";
    if (system ($cmd)) {
        print "$prereq_name is not installed.\n";

        # We try to install Packman
        $cmd = $ipcmd . " --smart " . $prereq_path;
        if (system ($cmd)) {
            print "ERROR: impossible to install $prereq_name ($cmd).\n";
            return -1;
        }

        # Packman should be installed now
        $cmd = $ipcmd . " --smart " . $prereq_path;
        if (system ($cmd)) {
            print "ERROR: $prereq_name is still not installed\n";
            return -1;
        }
    }

    return 0;
}


sub bootstrap_prereqs ($) {
    my $prereq_path = shift;
    my $cmd;

    # We get the current status of the prereq first
    $cmd = $ipcmd . " --status " . $prereq_path;
    my $prereq_name = basename ($cmd);
    print "Dealing with Prereq $prereq_name\n";
    if (system ($cmd)) {
        print "$prereq_name is not installed.\n";

        # We try to install Packman
        $cmd = $ipcmd . " --dumb " . $prereq_path;
        if (system ($cmd)) {
            print "ERROR: impossible to install $prereq_name ($cmd).\n";
            return -1;
        }

        # Packman should be installed now
        $cmd = $ipcmd . " --status " . $prereq_path;
        if (system ($cmd)) {
            print "ERROR: $prereq_name is still not installed\n";
            return -1;
        }
    }

    return 0;
}


# Code duplication with wizard_prep
sub init_server ($) {
    my $configurator = shift;

    # We initialize the database if needed
    require OSCAR::oda; # WARNING: it seems this is working only w/ 
                               # mysql.
                               # TODO: do something more generic.
    my (%options, %errors);
    my $database_status = oda::check_oscar_database(
        \%options,
        \%errors);
    if (!$database_status) {
        print "We need to initialize the database\n";
        my $scripts_path = $configurator->get_scripts_path();
        my $cmd =  "$scripts_path/create_oscar_database";
        if (system ($cmd)) {
            print "ERROR: Impossible to create the database ($cmd)\n";
            return -1;
        }
        print "Database created, now populating the database\n";
        $cmd = "$scripts_path/package_config_xmls_to_database";
        if (system ($cmd)) {
            print "ERROR: Impossible to populate the database ($cmd)\n";
            return -1;
        }
        # We double-check if the database really exists
        $database_status = oda::check_oscar_database(
            \%options,
            \%errors);
        if (!$database_status) {
            print "ERROR: The database is supposed to have been created but\n".
                  " we cannot connect to it.\n";
            return -1;
        }
    }

    require OSCAR::Logger;
    require OSCAR::Database;

    # Get the list of just core packages
    my (@results, %options, @errors);
    if (!OSCAR::Database::get_packages_with_class("core",
                                             \@results,
                                             \%options,
                                             \@errors)) {
        print "ERROR: Failed to get core packages list";
        return -1;
    }
    my @packages = map { $_->{package} } @results;

    OSCAR::Logger::oscar_log_subsection("Identified core packages: " . 
        join(' ', @packages));

    # OSCAR::Opkg requires XML::Simple which is not available initially but 
    # after prereq installation
    require OSCAR::Opkg;

    OSCAR::Logger::oscar_log_subsection("Installing server core packages");
    if (OSCAR::Opkg::opkgs_install_server (@packages)) {
        print "ERROR: Impossible to install server core packages\n";
        return -1;
    }
    OSCAR::Logger::oscar_log_subsection(
        "Successfully installed server core binary packages");

    return 0;
}

sub bootstrap_stage0 () {
    my $configfile_path;

    # Tricky situation: the software to parse the configuration file may not be
    # installed and the location of the information to install it is in the 
    # config file. We try to guess where is the config file (not that difficult)
    # and then we try to get the info we need
    if (defined($ENV{OSCAR_HOME}) 
        && $ENV{OSCAR_HOME} ne "" 
        && -f "$ENV{OSCAR_HOME}/share/oscar.conf") {
        $configfile_path = "$ENV{OSCAR_HOME}/share/oscar.conf";
    } elsif ( -f "/etc/oscar/oscar.conf") {
        $configfile_path = "$ENV{OSCAR_HOME}/share/oscar.conf";
    } else {
        print "ERROR: impossible to find the oscar configuration file";
        return undef;
    }

    # We quickly parse the file to get the lines we are looking for
    open(MYFILE, $configfile_path);
    my $line;
    my ($var, $path, $ippath);
    while ($line = <MYFILE>) {
        chomp ($line);
        # delete BOTH leading and trailing whitespace from each line
        if ($line =~ /^([ \t]*)PREREQS_PATH/) {
            ($var, $path) = split ("=", $line);
        }
        if ($line =~ /^([ \t]*)OSCAR_SCRIPTS_PATH/) {
            ($var, $ippath) = split ("=", $line);
        }
    }
    close (MYFILE);

    # Now that we know where the prereqs are, we try to install AppConfig
    $ipcmd = $ippath . "/install_prereq ";
    my $appconfig_path = $path . "/AppConfig";
    if (bootstrap_prereqs ($appconfig_path)) {
        print "ERROR: impossible to install appconfig\n";
        return undef;
    }

    # Then we can load the configuration!
    require OSCAR::ConfigManager;
    my $oscar_configurator = OSCAR::ConfigManager->new(
        config_file => "$configfile_path");
    return $oscar_configurator;
}

sub bootstrap_stage1 ($) {
    my $configurator = shift;
    if (!defined $configurator) {
        print "ERROR: Invalid configurator object.\n";
        return -1;
    }

    # First we install Packman
    my $packman_path = $configurator->get_packman_path ();
    if (bootstrap_prereqs ($packman_path)) {
        print "ERROR: Impossible to install Packman\n";
        return -1;
    }

    use lib "$ENV{OSCAR_HOME}/lib";
    require OSCAR::PackagePath;
    my $os = OSCAR::PackagePath::distro_detect_or_die();
    if (!defined $os) {
        print "ERROR: Impossible to detect the local Linux distribution\n";
        return -1;
    }

    # We save the list of binary packages before to really install stuff
    # This is useful for developers when they want to start over
    # TODO the location of the file we save is hardcoded, this is bad, We should
    # be able to specify that path via the OSCAR configuration file
    my $path = "/etc/oscar";
    if (save_preoscar_binary_list ($os, $path)) {
        print "ERROR: Impossible to save the list of preoscar binary packages.\n";
        return -1;
    }

    # Then we install YUME (supported on both rpm and deb systems).
    my $yume_path = $configurator->get_yume_path ();
    if (bootstrap_prereqs ($yume_path)) {
        print "ERROR: Impossible to install Yume\n";
        return -1;
    }

    # Then if the system is a Debian based system, we try to install RAPT
    if ($os->{pkg} eq "deb") {
        my $rapt_path = $configurator->get_rapt_path ();
        if (bootstrap_prereqs ($rapt_path)) {
            print "ERROR: Impossible to install RAPT\n";
            return -1;
        }
    }

    return 0;
}

sub bootstrap_stage2 ($) {
    my $configurator = shift;
    if (!defined $configurator) {
        print "ERROR: Invalid configurator object.\n";
        return -1;
    }

    # First we install the basic prereqs
    my $baseprereqs_path = $configurator->get_prereqs_path() . "/base";
    if (install_prereq ($baseprereqs_path)) {
        print "ERROR: impossible to install base prereqs\n";
        return -1;
    }

    # Then we install other prereqs, based on the ordering file.
    # For that, read in the share/prereqs/prereqs.order file
    # It should contain prerequisite paths relative to $OSCAR_HOME, one per 
    # line.
    my $prereqs_path = $configurator->get_prereqs_path();
    my $orderfile = "$prereqs_path/prereqs.order";
    my @ordered_prereqs;
    if (! -f "$orderfile") {
        print "ERROR: Impossible to find the prereq ordering file".
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
        if (install_prereq ($prereq)) {
            print "ERROR: Impossible to install a prereq ($prereq).\n";
            return -1;
        }
    }

    # we initialize the database if needed
    require OSCAR::Database_generic;
    OSCAR::Database_generic::init_database_passwd($configurator);

    # Then we try to install the server side of OSCAR
    if (init_server ($configurator)) {
        print "ERROR: Impossible to install the server side of OSCAR\n";
        return -1;
    }
}

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
        print "ERROR: Unknow binary format ($os->{pkg})\n";
        return -1;
    }

    return 0;
}

1;

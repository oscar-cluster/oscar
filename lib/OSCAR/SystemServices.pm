package OSCAR::SystemServices;

#
# Copyright (c) 2008 Geoffroy Vallee <valleegr@ornl.gov>
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
# This package provides a set of functions for the management of system
# services.
#

#
# $Id$
#

use strict;
use OSCAR::Utils;
use OSCAR::SystemServicesDefs;
use File::Basename;
use Carp;

use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw (
             enable_system_services
             );

# Parse the output of the chkconfig --list <service_id> command.
#
# Input: the output of the chkconfig command.
# Return: an array with the status for each run-level (n elt of the array =
#         level-n of execution.
sub parse_chkconfig_output ($) {
    my $output = shift;

    my @data = split (" ", $output);
    my @status;
    foreach my $d (@data) {
        $d = OSCAR::Utils::trim($d);
        if ($d =~ /^[0-9]\:(.*)$/) {
            push (@status, $1)
        }
    }
    return @status;
}

# Check the status of a single system service.
#
# Input: absolute path to access the service binary, e.g., /etc/init.d/sshd
# Return: SERVICE_ENABLED or SERVICE_DISABLED; see the SystemServiceDefs file.
#         undef if error.
sub system_service_status ($) {
    my $service = shift;

    $service = File::Basename::basename ($service);
    my $output = `/sbin/chkconfig --list $service`;
    my @status = parse_chkconfig_output ($output);

    # We only care about the runlevels 2, 3, 4, and 5
    if ($status[2] eq "off" && $status[3] eq "off" && $status[4] eq "off"
        && $status[5] eq "off") {
        return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
    } else {
        return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
    }

    return undef;
}

# Input: a list of services (absolute path to access the service binary, e.g.,
#        /etc/init.d/sshd).
# Return: 0 if success, -1 else.
sub enable_system_services (@) {
    my @services = @_;
    my @failed_services;

    # chkconfig is a RPM specific command, so we do not use it on Debian-like
    # systems. Moreover, services are automatically added into rc2.d on Debian
    my $os = OSCAR::OCA::OS_Detect::open();
    my $binary_format = $os->{'pkg'};
    if ($binary_format eq "rpm") {
        # On RPM based systems, we deal by default with runlevels 2, 3, 4, and 5
        foreach my $service (@services) {
            my $s = File::Basename::basename ($service);
            print ("Enabling service $s... ");
            # First we check if the service is already enable (chkconfig has
            # some weird return code policies, if we try to enable a service
            # that already has been enabled, we get errors
            my $status = system_service_status ($service);

            if ($status eq OSCAR::SystemServicesDefs::SERVICE_DISABLED()) {
                system("/sbin/chkconfig $s on");
                my $status = system_service_status ($service);
                if ($status eq OSCAR::SystemServicesDefs::SERVICE_DISABLED()) {
                    carp ("ERROR: Failed to enable $s");
                    push (@failed_services, $s);
                }
            } else {
                print "[INFO] The service is already enabled\n";
            }
            print ("done\n");
        }
    }

    if (scalar(@failed_services) > 0) {
        carp "ERROR: Impossible to enable some services\n";
        OSCAR::Utils::print_array (@failed_services);
        return -1;
    }

    return 0;
}

1;
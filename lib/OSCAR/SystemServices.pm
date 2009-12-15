package OSCAR::SystemServices;

#
# Copyright (c) 2008-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
# Copyright (c) 2009 CEA (Commissariat à l'Énergie Atomique)
#                    Olivier Lahaye <olivier.lahaye@cea.fr>
#                    All rights reserved
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::Logger;
use OSCAR::OCA::OS_Settings;
use OSCAR::SystemServicesDefs;
use OSCAR::Utils;
use File::Basename;
use Carp;

use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw (
             enable_system_services
             system_service
             get_system_services
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
    my $output = `LC_ALL=C /sbin/chkconfig --list $service`;
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

# Abstraction of the underlying tool for system service management (such as 
# chkconfig).
#
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

################################################################################
# is_system_service_running: tels if a service is running                      #
#                                                                              #
# input: service name                                                          #
#        action                                                                #
# output: 0 Success                                                            #
#         non 0: Error                                                         #
################################################################################

sub system_service ($$) {
    my ($service, $action) = @_;

    # We get the daemon path
    my $path = OSCAR::OCA::OS_Settings::getitem ($service . "_daemon");

    # /sbin/service is a RPM specific command, so we do not use it on Debian-like
    # systems. It allows to start a service with a non polluted environment.
    my $os = OSCAR::OCA::OS_Detect::open();
    my $binary_format = $os->{'pkg'};
    my $cmd;
    if ($binary_format eq "rpm") { # RPM based distro
        $cmd = File::Basename::basename ($path);
        print ("starting service $cmd... ");
        $cmd = "/sbin/service $cmd ";
    } else { # Non RPM based distro.
        my $cmd = "$path ";
    }

    if ($action eq OSCAR::SystemServicesDefs::START()) {
        if (system_service ($service, OSCAR::SystemServicesDefs::STATUS())) { # not running
            $cmd .= "start";
        } else { # already running, we restart to avoid errors (bad init stripts)
            $cmd .= "restart"; # systemimager-server-monitord is not LSB.
        }
    } elsif ($action eq OSCAR::SystemServicesDefs::STOP()) {
        $cmd .= "stop";
    } elsif ($action eq OSCAR::SystemServicesDefs::RESTART()) {
        $cmd .= "restart";
    } elsif ($action eq OSCAR::SystemServicesDefs::STATUS()) {
        $cmd .= "status";
    } else {
        carp "ERROR: Unknow system service action ($action)";
        return -1;
    }
    OSCAR::Logger::oscar_log_subsection "Executing: $cmd";

    # start returns 0 if start ok or already running
    # stop returns 0 is deamon running and succesfully stopped (else error)
    # retart: same as start
    # status: 0 if running 3 or 1 if not.
    # command not found: 127
    # unknown service: 1

    my $ret_code = system ($cmd);
    OSCAR::Logger::oscar_log_subsection ("[SystemService] Return code: $ret_code");

    return $ret_code;
}

# Give the list of system services OSCAR knows how to deal with.
#
# Input: None.
# Return: a hash where the key is the id the service if the value the actual
#         path to deal with the service.
sub get_system_services () {
    # We get the list of all entries in OS_Settings
    my $config = OSCAR::OCA::OS_Settings::getconf ();
    if (!defined $config || ref($config) ne "HASH") {
        carp "ERROR: Impossible to get the config from OS_Settings";
        return undef;
    }

    my %services;
    # We sort the services
    foreach my $k (keys(%{$config})) {
        if ($k =~ m/_daemon$/) {
            $services{$k} = $config->{$k};
        }
    }

    # We return the result
    return %services;
}

1;

__END__

=head1 Exported Functions

=over 4

=item enable_system_services

=item system_service

Peform an action on a given system service. For example: my $rc = SystemServices (OSCAR::SystemServicesDefs::DHCP(), OSCAR::SystemServicesDefs::STOP()); stops the dhcp deamon. Note that we use macros to be sure we correctly identify the service and the action.

=item list_system_services

Give the list of system services OSCAR knows how to deal with. Example:
my %services = list_system_services();

=back

=cut

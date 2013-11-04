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
use Switch 'Perl5', 'Perl6';

use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw (
             enable_system_services
             disable_system_services
             system_service
             remote_system_service
             system_service_status
             get_system_services
             );

=encoding utf8

=head1 NAME

OSCAR::SystemServices -- System services management abstraction module

=head1 SYNOPSIS

use OSCAR::SystemServices;
use OSCAR::SystemServicesDefs;

=head1 DESCRIPTION

This module provides a collection of fuctions to provide an abstraction
layer to system services management.

Depending on Linux distro, services are managed by systemd, initscripts
commands (chkconfig, service) or manually (run the /etc/init.d script
directly or enabling it manually as well). This module allows to forget
those differences when managing services.

=head2 Functions

=over 4

=cut
###############################################################################
=item parse_chkconfig_output( $output )

Parse the output of the chkconfig --list <service_id> command.

Input:  the output of the chkconfig command.
Return: an array with the status for each run-level (n elt of the array =
        level-n of execution.
Exported: NO

=cut 
###############################################################################

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

###############################################################################
=item system_service_status( $service )

Check the status of a single system service.

 Input: service name (either MACRO, generic name or real name)
Return: SERVICE_ENABLED or SERVICE_DISABLED; see the SystemServiceDefs file.
        undef if error.

Examples: system_service_status(HTTP())   => Prefered method
          system_service_status("http")
          system_service_status("httpd")  => Avoid if name is not the same on
                                            all distros (httpd, apache2, ...).
         => Note: HTTP() points to "http" (SystemServiceDefs.pm) which in turn
            allow to point to the real service name when appending _service
            (variable http_service from OS_Settings/{default,...})

Exported: YES

=cut
###############################################################################

sub system_service_status ($) {
    my $service = shift;

    my $os = OSCAR::OCA::OS_Detect::open();
    my $service_mgt = $os->{service_mgt}; # (systemd, initscripts, manual)

    # Get the real daemon name (example: http_service can be httpd or apache2)
    my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

    # If undefined, we assume that the $service is the exact name.
    $service_name = "$service" if (not defined $service_name);

    # Can't use switch/case here: for unknown reason, switch/given keyword is not recognized...
    if ($service_mgt eq "systemd") {
        open SYSTEMCTL, "LC_ALL=C /bin/systemctl status $service_name |"
            or (carp "ERROR: Could not run: $!", return undef);
        while (<SYSTEMCTL>) {
            if (/Loaded:.*\.service; enabled/) {
                close SYSTEMCTL;
                return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
            }
            if (/Loaded:.*\.service; disabled/) {
                close SYSTEMCTL;
                return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
            }
        }
        # The service is more than disabled (unknown, not loaded unknown from systemd, ...)
        close SYSTEMCTL;
        return undef;
    } elsif ($service_mgt eq "initscripts") {
        my $output = `LC_ALL=C /sbin/chkconfig --list $service_name`;
        my @status = parse_chkconfig_output ($output);

        # We only care about the runlevels 2, 3, and 5
        if ($status[2] eq "off" && $status[3] eq "off" && $status[5] eq "off") {
            return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
        } else {
            return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
        }
    } elsif ($service_mgt eq "manual") {
        my $initrd_path= OSCAR::OCA::OS_Settings::getitem('init');
        my @run_levels = ('rc2.d','rc3.d','rc5.d');
        foreach my $run_level (@run_levels) {
            system("/bin/ls $initrd_path/../$run_level/$service");
            if ($? != 0) {
                # Missing entry: service not enabled (at least not for this run level)
                return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
            }
        }
        # Still here? This means we found all entries in required run levels: service is enabled.
        return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
    }
    return undef;
}

###############################################################################
=item enable_system_services( $service )

Enable multiple system services to automatically start at boot.

 Input: a list of services (either MACROS, generic names or real names)
Return:  0: Success.
        -1: Error.

Example: enable_system_services((HTTP(),GANGLIA_GMOND(),GANGLIA_GMETAD()))

Exported: YES

=cut
###############################################################################

sub enable_system_services (@) {
    OSCAR::Logger::oscar_log_subsection("Unabling services:");
    return set_system_services(OSCAR::SystemServicesDefs::SERVICE_ENABLED(),@_);
}

###############################################################################
=item disable_system_services( $service )

Disable multiple system services to automatically start at boot.

 Input: a list of services (either MACROS, generic names or real names)
Return:  0: Success.
        -1: Error.

Example: enable_system_services((SI_BITTORRENT(),SI_FLAMETHROWER()))

Exported: YES

=cut
###############################################################################

sub disable_system_services (@) {
    OSCAR::Logger::oscar_log_subsection("Disabling services:");
    return set_system_services(OSCAR::SystemServicesDefs::SERVICE_DISABLED(),@_);
}

###############################################################################
=item set_system_services( $service )

Configure multiple system services start behavior at boot.

 Input: - START() or STOP()
        - a list of services (either MACROS, generic names or real names)
Return:  0: Success.
        -1: Error.

Example: set_system_services(SERVICE_ENABLED(),(SI_BITTORRENT(),SI_FLAMETHROWER()))

Exported: YES

=cut
###############################################################################

sub set_system_services ($@) {
    my $config = shift;
    my @services = @_;
    my @failed_services;

    # chkconfig is a RPM specific command, so we do not use it on Debian-like
    # systems. Moreover, services are automatically added into rc2.d on Debian

    my $os = OSCAR::OCA::OS_Detect::open();
    my $service_mgt = $os->{service_mgt}; # (systemd, initscripts, manual)
    given ($service_mgt) {
        when "systemd" {
            my $command = "enable";
            $command = "disable" if ($config eq OSCAR::SystemServicesDefs::SERVICE_DISABLED());
            foreach my $service (@services) {
                OSCAR::Logger::oscar_log_subsection("Setting service $service to ".$command."d...");
                my $status = system_service_status ($service);
                # If status is not what we want, then perform the change.
                if ($status ne $config) {
                    # Need to get the real service name (example: http can be either httpd or apache2)
                    my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                    # If undefined, we assume that the $service is the exact name.
                    $service_name = "$service" if (not defined $service_name);

                    system("LC_ALL=C /bin/systemctl $command $service_name");
                    my $status = system_service_status ($service);
                    if ($status ne $config) {
                        OSCAR::Logger::oscar_log_subsection ("[ERROR] Failed to $command $service");
                        carp ("ERROR: Failed to $command $service");
                        push (@failed_services, $service);
                    } else {
                        OSCAR::Logger::oscar_log_subsection ("[SUCCESS] $service ".$command."d");
                    }
                } else {
                    OSCAR::Logger::oscar_log_subsection "[INFO] The service is already ".$command."d";
                }
            }
        }
        when "initscripts" {
            my $command = "on";
            $command = "off" if ($config eq OSCAR::SystemServicesDefs::SERVICE_DISABLED());
            foreach my $service (@services) {
                OSCAR::Logger::oscar_log_subsection("Setting service $service to $command... ");
                # First we check if the service is already enabled (chkconfig has
                # some weird return code policies, if we try to enable a service
                # that already has been enabled, we get errors
                my $status = system_service_status ($service);
                # If status is not what we want, then perform the change.
                if ($status ne $config) {
                    # Need to get the real service name (example: http can be either httpd or apache2)
                    my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                    # If undefined, we assume that the $service is the exact name.
                    $service_name = "$service" if (not defined $service_name);

                    system("/sbin/chkconfig $service_name $command");
                    my $status = system_service_status ($service);
                    if ($status ne $config) {
                        OSCAR::Logger::oscar_log_subsection ("[ERROR] Failed to set $service to $command");
                        carp ("ERROR: Failed to set $service to $command");
                        push (@failed_services, $service);
                    } else {
                        OSCAR::Logger::oscar_log_subsection ("[SUCCESS] $service set to $command");
                    }
                } else {
                    OSCAR::Logger::oscar_log_subsection "[INFO] The service is already $command";
                }
            }
        }
        when "manual" {
            my $command = "start 20 2";
            $command = "remove" if ($config eq OSCAR::SystemServicesDefs::SERVICE_DISABLED());
            #my $initrd_path="/etc/init.d";
            my $initrd_path= OSCAR::OCA::OS_Settings::getitem('init');
            foreach my $service (@services) {
                OSCAR::Logger::oscar_log_subsection("Setting service $service to ".$command."d...");
                my $status = system_service_status ($service);
                # If status is not what we want, then perform the change.
                if ($status ne $config) {
                    my @run_levels = ('rc2.d','rc3.d','rc5.d');
                    foreach my $run_level (@run_levels) {
                        # Need to get the real service name (example: http can be either httpd or apache2)
                        my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                        # If undefined, we assume that the $service is the exact name.
                        $service_name = "$service" if (not defined $service_name);

                        # OL: Also, use /sbin/update-rc.d when possible.
                        #system("/bin/ln -s $initrd_path/$service_name $initrd_path/../$run_level/$service_name");
                        system("/usr/sbin/update-rc.d -f $service_name $command");
                        # OL: BUG: need to prepend #order before linkname.
                        if ($? != 0) {
                            OSCAR::Logger::oscar_log_subsection ("[ERROR] Failed to $command $service");
                            carp ("ERROR: Failed to $command $service");
                            push (@failed_services, $service);
                        } else {
                            OSCAR::Logger::oscar_log_subsection ("[SUCCESS] $service ".$command."d");
                        }
                    }
                } else {
                    OSCAR::Logger::oscar_log_subsection "[INFO] The service is already ".$command."d";
                }
            }
        }
    }

    if (scalar(@failed_services) > 0) {
        carp "ERROR: Impossible to enable some services\n";
        OSCAR::Utils::print_array (@failed_services);
        return -1;
    }

    return 0;
}

###############################################################################
=item system_service( $service , $action )

Perform an action on a service: START, STOP, RESTART, STATUS

 Input: - service (either MACRO, generic name or real name)
        - action (START(), STOP(),RESTART(),STATUS())

Return:     0: Success.
        non 0: Error.

Examples: system_service(HTTP(),RESTART()) # Prefered method
          system_service("http","restart")
          system_service("httpd","restart")
          => HTTP() points to "http" (SystemServiceDefs.pm) which in turn
             allow to point to the real service name when appending _service
             (http_service from OS_Settings/{default,...})

Exported: YES

=cut
###############################################################################

sub system_service ($$) {
    my $service = shift;
    my $action = shift;
    return remote_system_service($service,$action,undef);
}

###############################################################################
=item remote_system_service( $service , $action , $remote_cmd)

Perform an action on a remote service: START, STOP, RESTART, STATUS

 Input: - service (either MACRO, generic name or real name)
        - action (START(), STOP(),RESTART(),STATUS())
        - remote command (typically: /usr/bin/ssh $host or /usr/bin/cexec)

Return:     0: Success.
        non 0: Error.

Examples: remote_system_service(GANGLIA_GMOND(),RESTART(),"/usr/bin/cexec")
          remote_system_service(GANGLIA_GMOND(),RESTART(),"/usr/bin/ssh $node")

Exported: YES

=cut
###############################################################################

sub remote_system_service($$$) {
    my ($service, $action, $remote_cmd) = @_;

    # If remote command is defined but is not executable or is a directory => Problem.
    if (defined $remote_cmd and ( not -x $remote_cmd or -d $remote_cmd )) {
        carp "ERROR: remote command ($remote_cmd) not an executable.\n Can't perform remote action $action on remote service $service";
        return -1;
    } elsif ( not defined $remote_cmd ) {
        $remote_cmd = "";
    }
    my $os = OSCAR::OCA::OS_Detect::open();
    my $service_mgt = $os->{service_mgt}; # (systemd, initscripts, manual)

    # Get the real daemon name (example: http service can be httpd or apache2)
    my $service_name = OSCAR::OCA::OS_Settings::getitem ($service . "_service");
    # If undefined, we assume that $service is the exact name.
    $service_name = $service if (not defined $service_name);

    my $cmd="";
    my $cmd_action="";

    if ($action eq OSCAR::SystemServicesDefs::START()) {
        if (system_service ($service, OSCAR::SystemServicesDefs::STATUS())) { 
            # not running
            $cmd_action = "start";
        } else { 
            # already running, we restart to avoid errors (bad init stripts)
            $cmd_action = "restart"; # systemimager-server-monitord is not LSB.
        }
    } elsif ($action eq OSCAR::SystemServicesDefs::STOP()) {
        $cmd_action = "stop";
    } elsif ($action eq OSCAR::SystemServicesDefs::RESTART()) {
        $cmd_action = "restart";
    } elsif ($action eq OSCAR::SystemServicesDefs::STATUS()) {
        $cmd_action = "status";
    } else {
        carp "ERROR: Unknow system service action ($action)";
        return -1;
    }

    OSCAR::Logger::oscar_log_subsection ("Performing '$cmd_action' on service $service_name ($service)... ");
    given ($service_mgt) {
        when "systemd" {
            $cmd = "/bin/systemctl ".$cmd_action." ".$service_name;
            last
        }
        when "initscripts" {
            $cmd = "/sbin/service ".$service_name." ".$cmd_action;
            last
        }
        when "manual" {
            $cmd = OSCAR::OCA::OS_Settings::getitem('init')." ".$cmd_action;
            last
        }
    }

    OSCAR::Logger::oscar_log_subsection "Executing: $cmd";

    # start returns 0 if start ok or already running
    # stop returns 0 is deamon running and succesfully stopped (else error)
    # retart: same as start
    # status: 0 if running 3 or 1 if not.
    # command not found: 127
    # unknown service: 1

    my $ret_code = system ("LC_ALL=C $remote_cmd $cmd");
    $ret_code = $ret_code/256 if ($ret_code > 255);
    OSCAR::Logger::oscar_log_subsection ("[SystemService] Return code: $ret_code");

    return $ret_code;
}

###############################################################################
=item get_system_services()

Give the list of system services OSCAR knows how to deal with.

 Input: none
Output: a hash where the key is the id the service if the value the actual
        service name eg. http => apache2.

Examples: my %services = list_system_services();

Exported: YES

=cut
###############################################################################

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
        if ($k =~ m/_service$/) {
            $services{$k} = $config->{$k};
        }
    }

    # We return the result
    return %services;
}

=back

=head1 TO DO

 * Add support for remotely enable/disable services.

=head1 SEE ALSO

L<OSCAR::SystemServicesDefs>

=head1 AUTHORS
Origially written by:
    (c) 2008-2009 Geoffroy Vallee C<< <valleegr@ornl.gov> >>
                  Oak Ridge National Laboratory
                  All rights reserved.
Mostly rewritten and documented by:
    (c) 2009-2013 Olivier Lahaye C<< <olivier.lahaye@cea.fr> >>
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

1;

__END__

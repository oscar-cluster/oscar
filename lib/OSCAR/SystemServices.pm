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
use OSCAR::LoggerDefs;
use OSCAR::OCA::OS_Settings;
use OSCAR::SystemServicesDefs;
use OSCAR::Utils;
use File::Basename;
use Carp;
use v5.10.1;
use Switch 'Perl5', 'Perl6';
# Avoid smartmatch warnings when using given
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw (
             enable_system_services
             enable_system_sockets
             disable_system_services
             system_service
             system_socket
             remote_system_service
             remote_system_socket
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
commands (chkconfig, service) upstart commands (start, stop, restart, ...)
or manually (run the /etc/init.d script directly or enabling it manually
as well). This module allows to forget those differences when managing
services.

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

    given ($service_mgt) {
        when ("systemd") {
            open SYSTEMCTL, "LC_ALL=C /bin/systemctl --no-reload is-enabled $service_name.service |"
                or (oscar_log(6, ERROR, "Could not run: $!"), return undef);
            while (<SYSTEMCTL>) {
                if (/^enabled/) {
                    close SYSTEMCTL;
                    return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
                }
                if (/^disabled/) {
                    close SYSTEMCTL;
                    return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
                }
            }
            # The service is more than disabled (unknown, not loaded unknown from systemd, ...)
            close SYSTEMCTL;
            return undef;
            last;
        }
        when ("initscripts") {
            my $output = `LC_ALL=C /sbin/chkconfig --list $service_name`;
            my @status = parse_chkconfig_output ($output);

            # We only care about the runlevels 2, 3, and 5
            if ($status[2] eq "off" && $status[3] eq "off" && $status[5] eq "off") {
                return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
            } else {
                return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
            }
            last;
        }
        when ("upstart") {
            open( INITCTL, "LC_ALL=C initctl show-config $service_name |" );
            while (<INITCTL>) {
                if (/^\s*start.*\[.*23.*5\]$/) {
                    return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
                }
            }
            return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
            last;
        }
        when ("manual") {
            my $initrd_path= OSCAR::OCA::OS_Settings::getitem('init');
            my @run_levels = ('rc2.d','rc3.d','rc5.d');
            foreach my $run_level (@run_levels) {
                oscar_system("/bin/ls $initrd_path/../$run_level/$service");
                if ($? != 0) {
                    # Missing entry: service not enabled (at least not for this run level)
                    return OSCAR::SystemServicesDefs::SERVICE_DISABLED();
                }
            }
            # Still here? This means we found all entries in required run levels: service is enabled.
            return OSCAR::SystemServicesDefs::SERVICE_ENABLED();
            last;
        }
        default {
            oscar_log(5, ERROR, "Unknwon SystemService Mgt method: $service_mgt");
            return undef;
        }
    } # end given
#    return undef;
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
#    OSCAR::Logger::oscar_log_message(3, "Unabling services");
    return set_system_services(OSCAR::SystemServicesDefs::SERVICE_ENABLED(),@_);
}

###############################################################################
=item enable_system_socketss( $service )

Enable multiple system socket services to automatically start at boot.

 Input: a list of services (either MACROS, generic names or real names)
Return:  0: Success.
        -1: Error.

Example: enable_system_sockets((TFTP()))

Exported: YES

=cut
###############################################################################

sub enable_system_sockets (@) {
#    OSCAR::Logger::oscar_log_subsection("Unabling socket services:");
    return set_system_sockets(SERVICE_ENABLED(),@_);
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
#    OSCAR::Logger::oscar_log_subsection("Disabling services:");
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
        when ("systemd") {
            my $command = "enable";
            $command = "disable" if ($config eq SERVICE_DISABLED());
            foreach my $service (@services) {
                oscar_log(6, INFO, "Setting service $service to ".$command."d...");
                my $status = system_service_status ($service);
                # If status is not what we want, then perform the change.
                if ($status ne $config) {
                    # Need to get the real service name (example: http can be either httpd or apache2)
                    my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                    # If undefined, we assume that the $service is the exact name.
                    $service_name = "$service" if (not defined $service_name);

                    my $cmd = "LC_ALL=C /bin/systemctl --no-reload $command $service_name.service";
                    # FIXME: would be better to handle return code for system() call below.
                    oscar_system($cmd);
                    my $status = system_service_status ($service);
                    if ($status ne $config) {
                        oscar_log(5, ERROR, "Failed to $command $service\n");
                        push (@failed_services, $service);
                    } else {
                        oscar_log(3, INFO, "$service successfully ".$command."d");
                    }
                } else {
                    oscar_log(6, INFO, "$service is already ".$command."d");
                }
            }
            last;
        }
        when ("initscripts") {
            my $command = "on";
            $command = "off" if ($config eq SERVICE_DISABLED());
            foreach my $service (@services) {
                oscar_log(6, INFO, "Setting service $service to ".$command."...");
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

                    my $cmd = "/sbin/chkconfig $service_name $command";
                    # FIXME: would be better to handle return code for system() call below.
                    oscar_system($cmd);
                    my $status = system_service_status ($service);
                    if ($status ne $config) {
                        oscar_log (5, ERROR, "Failed to set $service to $command");
                        push (@failed_services, $service);
                    } else {
                        oscar_log(3, INFO, "$service successfully set to ".$command);
                    }
                } else {
                    oscar_log(6, INFO, "$service is already ".$command);
                }
            }
            last;
        }
        when ("upstart") { # same as manual
            my $command = "start 20 2 3 5";
            $command = "remove" if ($config eq SERVICE_DISABLED());
            foreach my $service (@services) {
                oscar_log(5, INFO, "Setting service $service to ".$command."d...");
                my $status = system_service_status ($service);
                # If status is not what we want, then perform the change.
                if ($status ne $config) {
                    my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");
                    # If undefined, we assume that the $service is the exact name.
                    $service_name = "$service" if (not defined $service_name);
                    my $cmd = "/usr/sbin/update-rc.d -f $service_name $command";
                    # FIXME: would be better to handle return code for system() call below.
                    oscar_system($cmd);
                    if ($? != 0) {
                        oscar_log(5, ERROR, "Failed to $command $service");
                        push (@failed_services, $service);
                    } else {
                        oscar_log(3, INFO, "$service successfully ".$command."d");
                    }
                } else {
                    oscar_log(6, INFO, "$service is already ".$command."d");
                }
            }
            last;
        }
        when ("manual") {
            my $command = "start 20 2 3 5";
            $command = "remove" if ($config eq SERVICE_DISABLED());
            #my $initrd_path="/etc/init.d";
            my $initrd_path= OSCAR::OCA::OS_Settings::getitem('init');
            foreach my $service (@services) {
                oscar_log(5, INFO, "Setting service $service to ".$command."d...");
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

                        my $cmd = "/usr/sbin/update-rc.d -f $service_name $command";
                        # FIXME: would be better to handle return code for system() call below.
                        oscar_system($cmd);
                        # OL: BUG: need to prepend #order before linkname.
                        if ($? != 0) {
                            oscar_log(5, ERROR, "Failed to $command $service");
                            push (@failed_services, $service);
                        } else {
                            oscar_log(3, INFO, "$service successfully ".$command."d");
                        }
                    }
                } else {
                    oscar_log(6, INFO, "$service is already ".$command."d");
                }
            }
            last;
        }
    }

    if (scalar(@failed_services) > 0) {
        oscar_log(5, ERROR, "Failed to enable some services.");
        OSCAR::Utils::print_array (@failed_services) if ($OSCAR::Env::oscar_verbose >= 5);
        return -1;
    }

    return 0;
}

###############################################################################
=item set_system_sockets( $service )

Configure multiple system sockets (xinetd or equivalent service start behavior at boot).

 Input: - SERVICE_ENABLED() or SERVICE_DISABLED()
        - a list of services (either MACROS, generic names or real names)
Return:  0: Success.
        -1: Error.

Example: set_system_sockets(SERVICE_ENABLED(),(TFTP()))

Exported: YES

=cut
###############################################################################

sub set_system_sockets ($@) {
    # OL FIXME: Fix return codes in all calls.
    my $config = shift;
    my @services = @_;
    my @failed_services;

    # chkconfig is a RPM specific command, so we do not use it on Debian-like
    # systems.

    my $os = OSCAR::OCA::OS_Detect::open();
    my $service_mgt = $os->{service_mgt}; # (systemd, initscripts, manual)
    given ($service_mgt) {
        when "systemd" {
            my $command = "disable";
            $command = "enable" if ($config eq SERVICE_ENABLED());
            foreach my $service (@services) {
                oscar_log(5, INFO, "Setting socket service $service to ".$command."d...");
                # Need to get the real service name (example: http can be either httpd or apache2)
                my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                # If undefined, we assume that the $service is the exact name.
                $service_name = "$service" if (not defined $service_name);

                my $cmd;
                $cmd = "LC_ALL=C /bin/systemctl $command $service_name.socket";
                oscar_system($cmd);
                # FIXME: what about checking return code?

                $cmd = "LC_ALL=C systemctl daemon-reload";
                oscar_system("LC_ALL=C systemctl daemon-reload");
                # FIXME: what about checking return code?
            }
            last;
        }
        when "initscripts" {
            my $command = "off";
            if ($config eq SERVICE_ENABLED()) {
                $command = "on";
                # When enabling a xinetd service, we also need to enable xinetd.
                set_system_services(SERVICE_ENABLED(), (XINETD()));
            }
            foreach my $service (@services) {
                oscar_log(5, INFO, "Setting xinetd service $service to $command... ");
                # Need to get the real service name (example: http can be either httpd or apache2)
                my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                # If undefined, we assume that the $service is the exact name.
                $service_name = "$service" if (not defined $service_name);

                my $cmd;
                $cmd = "/sbin/chkconfig $service_name $command";
                oscar_system($cmd);
                # FIXME: what about checking return code?
            }
            # FIXME: check return codes.
            system_service(XINETD(), RESTART());
            last;
         }
        when ("upstart") {
            oscar_log(1, ERROR, "OSCAR::SystemServices:set_system_sockets() not implemented for 'upstart'");
            last;
        }
        when ("manual") {
            my $command = "no";
            $command = "yes" if ($config eq SERVICE_DISABLED());
            my $xinetd_path= OSCAR::OCA::OS_Settings::getitem('xinetd_dir');
            foreach my $service (@services) {
                oscar_log(5, INFO, "Setting ixinetd service $service to ".$command."d...");
                # Need to get the real service name (example: http can be either httpd or apache2)
                my $service_name = OSCAR::OCA::OS_Settings::getitem($service . "_service");

                # If undefined, we assume that the $service is the exact name.
                $service_name = "$service" if (not defined $service_name);

                # FIXME: OL: To be tested. Also note that if line disabled = does not exists,
                # the service config will not change.
                my $cmd;
                $cmd = "sed -i -e 's/\(.*disabled.*:\).*\$/\1 $command' $xinetd_path/$service_name";
                oscar_system($cmd);
                # FIXME: what about checking return code?
            }
            last;
        }
    }
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
=item system_socket( $service , $action )

Perform an action on a service: START, STOP, RESTART, STATUS

 Input: - service (either MACRO, generic name or real name)
        - action (START(), STOP(),RESTART(),STATUS())

Return:     0: Success.
        non 0: Error.

Examples: system_socket(TFTP(),RESTART()) # Prefered method
          system_socket("tftp","restart")
          system_ssocket("atftpd","restart")
          => TFTP() points to "tftp" (SystemServiceDefs.pm) which in turn
             allow to point to the real service name when appending _service
             (tftp_service from OS_Settings/{default,...})

Exported: YES

=cut
###############################################################################

sub system_socket ($$) {
    my $service = shift;
    my $action = shift;
    return remote_system_socket($service,$action,undef);
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
        oscar_log(5, ERROR, "Remote command ($remote_cmd) not an executable.\n Can't perform remote action $action on remote service $service");
        return -1;
    } elsif ( not defined $remote_cmd ) {
        oscar_log(5, INFO, "Performing $action on $service service.");
        $remote_cmd = "";
    } else {
        $remote_cmd = "LC_ALL=C $remote_cmd"; 
        oscar_log(5, INFO, "Using '$remote_cmd' to perfome '$action' on '$service' service.");
    }

    my $os = OSCAR::OCA::OS_Detect::open();
    my $service_mgt = $os->{service_mgt}; # (systemd, initscripts, upstart, manual)

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
    } elsif ($action eq OSCAR::SystemServicesDefs::RELOAD()) {
        $cmd_action = "reload";
    } else {
        oscar_log(6, ERROR, "Unknow system service action ($action)");
        return -1;
    }

#    OSCAR::Logger::oscar_log_subsection ("Performing '$cmd_action' on service $service_name ($service)... ");
    given ($service_mgt) {
        when "systemd" {
            $cmd = "LC_ALL=C /bin/systemctl ".$cmd_action." ".$service_name.".service";
            last
        }
        when "initscripts" {
            $cmd = "LC_ALL=C /sbin/service ".$service_name." ".$cmd_action;
            last
        }
        when "upstart" {
            $cmd = "LC_ALL=C /sbin/initctl ".$cmd_action." ".$service_name;
            last
        }
        when "manual" {
            $cmd = OSCAR::OCA::OS_Settings::getitem('init')." ".$service_name." "..$cmd_action;
            last
        }
    }

    # start returns 0 if start ok or already running
    # stop returns 0 is deamon running and succesfully stopped (else error)
    # retart: same as start
    # status: 0 if running 3 or 1 if not.
    # command not found: 127
    # unknown service: 1

    my $ret_code = oscar_system ("$remote_cmd $cmd");
    $ret_code = $ret_code/256 if ($ret_code > 255);
    oscar_log (7, INFO, "Return code: $ret_code") if($ret_code > 0);

    return $ret_code;
}

###############################################################################
=item remote_system_socket( $service , $action , $remote_cmd)

Perform an action on a remote service: START, STOP, RESTART, STATUS

 Input: - service (either MACRO, generic name or real name)
        - action (START(), STOP(),RESTART(),STATUS())
        - remote command (typically: /usr/bin/ssh $host or /usr/bin/cexec)

Return:     0: Success.
        non 0: Error.

Exported: YES

=cut
###############################################################################

sub remote_system_socket($$$) {
    my ($service, $action, $remote_cmd) = @_;

    # If remote command is defined but is not executable or is a directory => Problem.
    if (defined $remote_cmd and ( not -x $remote_cmd or -d $remote_cmd )) {
        oscar_log(5, ERROR, "Remote command ($remote_cmd) not an executable.\n Can't perform remote action $action on remote socket service $service");
        return -1;
    } elsif ( not defined $remote_cmd ) {
        $remote_cmd = "";
        oscar_log(5, INFO, "Performing $action on $service socket service.");
    } else {
        oscar_log(5, INFO, "Using $remote_cmd to perfome $action on $service socket service.");
    }

    my $os = OSCAR::OCA::OS_Detect::open();
    my $service_mgt = $os->{service_mgt}; # (systemd, initscripts, upstart, manual)

    # Get the real daemon name (example: http service can be httpd or apache2)
    my $service_name = OSCAR::OCA::OS_Settings::getitem ($service . "_service");
    # If undefined, we assume that $service is the exact name.
    $service_name = $service if (not defined $service_name);

    my $cmd="";
    my $cmd_action="";

    if ($action eq START()) {
        if (system_socket ($service, STATUS())) { 
            # not running
            $cmd_action = "start";
        } else { 
            # already running, we restart to avoid errors (bad init stripts)
            $cmd_action = "restart";
        }
    } elsif ($action eq STOP()) {
        $cmd_action = "stop";
    } elsif ($action eq RESTART()) {
        $cmd_action = "restart";
    } elsif ($action eq STATUS()) {
        $cmd_action = "status";
    } else {
        oscar_log(5, ERROR, "Unknow system socket service action ($action)");
        return -1;
    }

#    OSCAR::Logger::oscar_log_subsection ("Performing '$cmd_action' on socket service $service_name ($service)... ");
    given ($service_mgt) {
        when "systemd" {
            $cmd = "LC_ALL=C /bin/systemctl ".$cmd_action." ".$service_name.".socket ; /bin/systemctl daemon-reload";
            last
        }
        when "initscripts" {
            $service_name = OSCAR::OCA::OS_Settings::getitem (XINETD() . "_service");
            # we won't stop xinetd as it would stop all xinetd services.
            system_service($service_name, $cmd_action) if ($cmd_action ne STOP());
            $cmd="";
            last
        }
        when "upstart" {
            $service_name = OSCAR::OCA::OS_Settings::getitem (XINETD() . "_service");
            # we won't stop xinetd as it would stop all xinetd services.
            system_service($service_name, $cmd_action) if ($cmd_action ne STOP());
            $cmd="";
            last
        }
        when "manual" {
            $service_name = OSCAR::OCA::OS_Settings::getitem (XINETD() . "_service");
            # we won't stop xinetd as it would stop all xinetd services.
            system_service($service_name, $cmd_action) if ($cmd_action ne STOP());
            $cmd="";
            last
        }
    }

    # FIXME: OL: should init return code with above system_service real return code.
    my $ret_code = 0;
    if ($cmd ne "") {

        # start returns 0 if start ok or already running
        # stop returns 0 is deamon running and succesfully stopped (else error)
        # retart: same as start
        # status: 0 if running 3 or 1 if not.
        # command not found: 127
        # unknown service: 1

        $ret_code = oscar_system ("LC_ALL=C $remote_cmd $cmd");
        $ret_code = $ret_code/256 if ($ret_code > 255);
    }
    oscar_log (7, INFO, "Return code: $ret_code") if($ret_code > 0);

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
        oscar_log(6, ERROR, "Impossible to get the config from OS_Settings");
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

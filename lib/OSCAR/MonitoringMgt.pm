package OSCAR::MonitoringMgt;

# Copyright (c) 2014 CEA (Commissariat A l'Energie Atomique et aux Energies Alternatives)
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
# This package provides a set of functions for the management of Naemon monitoring systems
# (nagios fork)
#

#
# $Id: MonitoringMgt.pm 00000 2014-06-16 18:51:37Z olahaye74 $
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
use v5.10.1; # Switch
# Avoid smartmatch warnings when using given
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw (
             init_naemon_config_dir
             write_oscar_contact_cfg
             write_oscar_contactgroup_cfg
             write_oscar_command_cfg
             write_oscar_service_cfg
             write_oscar_host_cfg
             write_oscar_hostgroup_cfg
             );

=encoding utf8

=head1 NAME

OSCAR::MonitoringMgt -- Naemon/Nagios configuration file generation

=head1 SYNOPSIS

use OSCAR::MonitoringMgt;

=head1 DESCRIPTION

This module provides a collection of fuctions to write naemon configuration
files.

=head2 Functions

=over 4

=cut
###############################################################################
=item init_naemon_config_dir ()

Create the naemon directory structure for configuration related to OSCAR.

Exported: YES

=cut 
###############################################################################

sub init_naemon_config_dir() {
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");
    if (! -d $naemon_configdir) {
        oscar_log(1, ERROR, "Naemon configuration directory not found!");
        return 1;
    }

    # Create oscar configuration sub directories.

    for my $subdir ("", "/hosts", "/contacts", "/services", "/commands") {
        my $config_dir = "$naemon_configdir/conf.d/oscar$subdir";
        return 1 unless(-e $config_dir or mkdir $config_dir);
    }

    return 0;
}

=cut
###############################################################################
=item write_oscar_contact_cfg ($name, $alias, $email)

Write the contact.cfg file and the contact groups.

Exported: YES

=cut 
###############################################################################

sub write_oscar_contact_cfg ($$$) {
    my ($contact_name,$contact_alias, $contact_email) = @_;
    # TODO: Check valid string and valid IP.
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");
    my $contact_cfg = "$naemon_configdir/conf.d/oscar/contacts/contact_$contact_name.cfg";
    open CMD, ">", $contact_cfg
        or (oscar_log(1, ERROR, "Can't create $contact_cfg"), return 1);

# Trick to avoid rhel6 buggy rpm automatic dep  generator to require: perl();
my $use = "use";

    print CMD <<EOF;
# $contact_name contact definition
define contact {
  contact_name                   $contact_name
  alias                          $contact_alias
  ${use}                            generic-contact
  email                          $contact_email
}
EOF
    close CMD;

    return 0;
}
#
###############################################################################
=item write_oscar_contactgroup_cfg($contactgroup_name, $contactgroup_description, $members_ref)

Write an oscar command file in the following format:

# '$contact_group_description' contactgroup definition
define contactgroup {
  contactgroup_name              $contactgroup_name
  alias                          $contactgroup_description
  members                        @members
}

Exported: YES

=cut
###############################################################################

sub write_oscar_contactgroup_cfg ($$$) {
    my ($contactgroup_name, $contactgroup_description, $members_ref) = @_;
    # TODO: Check valid string.
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");

    my $members="";
    if(defined($members_ref)) {
        if(scalar(@{$members_ref}) > 0) {
           $members = "  members                        ".join(',',@{$members_ref})."\n";
        }
    }

    my $contactgroup_cfg = "$naemon_configdir/conf.d/oscar/contacts/contactgroup_$contactgroup_name.cfg";
    open CMD, ">", $contactgroup_cfg
        or (oscar_log(1, ERROR, "Can't create $contactgroup_cfg"), return 1);

    print CMD <<EOF;
# $contactgroup_name contactgroup definition
define contactgroup {
  contactgroup_name              $contactgroup_name
  alias                          $contactgroup_description
$members}
EOF
    close CMD;
    return 0;
}


###############################################################################
=item write_oscar_command_cfg($command_name, command_line)

Write an oscar command file in the following format:

# '$command_name' command definition
define command {
  command_name                   $command_name
  command_line                   $command_line
}

Exported: YES

=cut
###############################################################################

sub write_oscar_command_cfg ($$) {
    my ($command_name,$command_line) = @_;
    # TODO: Check valid string.
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");
    my $command_cfg = "$naemon_configdir/conf.d/oscar/commands/command_$command_name.cfg";
    open CMD, ">", $command_cfg
        or (oscar_log(1, ERROR, "Can't create $$command_cfg"), return 1);

    print CMD <<EOF;
# $command_name command definition
define command {
  command_name                   $command_name
  command_line                   $command_line
}
EOF
    close CMD;
    return 0;
}

###############################################################################
=item write_oscar_service_cfg($service_description,$hostgroup_name,$check_command)

Write an oscar command file in the following format:

# '$service_description' service definition
define service {
  service_description            $service_description
  hostgroup_name                 $hostgroup_name
  use                            local-service
  check_command                  $check_command
}

Exported: YES

=cut
###############################################################################

sub write_oscar_service_cfg ($$$$) {
    my ($service_name,$type, $hostgroup_name,$check_command) = @_;
    # TODO: Check valid string.
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");
    my $service_cfg = "$naemon_configdir/conf.d/oscar/services/service_$service_name.cfg";
    open CMD, ">", $service_cfg
        or (oscar_log(1, ERROR, "Can't create $service_cfg"), return 1);

# Trick to avoid rhel6 buggy rpm automatic dep  generator to require: perl();
my $use = "use";

    print CMD <<EOF;
# $service_name service definition
define service {
  service_description            $service_name
  ${type}_name                 $hostgroup_name
  ${use}                            local-service
  check_command                  $check_command
}
EOF
    close CMD;
    return 0;
}

###############################################################################
=item write_oscar_hostgroup_cfg($hostgroup_name, $hostgroup_description, $members_ref, $hostgroup_members_ref)

Write an oscar command file in the following format:

# '$hostgroup_description' hostgroup definition
define hostgroup {
  hostgroup_name                 $hostgroup_name
  alias                          $hostgroup_description
  members                        @members
  hostgroup_members              @hostgroup
}

Exported: YES

=cut
###############################################################################

sub write_oscar_hostgroup_cfg ($$$$) {
    my ($hostgroup_name, $hostgroup_description, $members_ref, $hostgroup_members_ref) = @_;
    # TODO: Check valid string.
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");

    my $members="";
    if(defined($members_ref)) {
        if(scalar(@{$members_ref}) > 0) {
           $members = "  members                        ".join(',',@{$members_ref})."\n";
        }
    }
    if(defined($hostgroup_members_ref)) {
        if(scalar(@{$hostgroup_members_ref})) {
           $members .= "  hostgroup_members              ".join(',',@{$hostgroup_members_ref})."\n";
        }
    }

    my $hostgroup_cfg = "$naemon_configdir/conf.d/oscar/hosts/hostgroup_$hostgroup_name.cfg";
    open CMD, ">", $hostgroup_cfg
        or (oscar_log(1, ERROR, "Can't create $hostgroup_cfg"), return 1);

    print CMD <<EOF;
# $hostgroup_name hostgroup definition
define hostgroup {
  hostgroup_name                 $hostgroup_name
  alias                          $hostgroup_description
$members}
EOF
    close CMD;
    return 0;
}




###############################################################################
=item write_oscar_host_cfg($host_name,$host_alias, $host_ip)

Write an oscar host file in the following format:

define host {
  host_name                      $nodename
  alias                          oscarnode#
  address                        @IP
  use                            linux-server
  notification_period            24x7
}

Exported: YES

=cut
###############################################################################

sub write_oscar_host_cfg ($$$) {
    my ($host_name,$host_alias, $host_ip) = @_;
    # TODO: Check valid string and valid IP.
    my $naemon_configdir = OSCAR::OCA::OS_Settings::getitem(NAEMON()."_configdir");

    my $host_cfg = "$naemon_configdir/conf.d/oscar/hosts/host_$host_name.cfg";
    open CMD, ">", $host_cfg
        or (oscar_log(1, ERROR, "Can't create $host_cfg"), return 1);

# Trick to avoid rhel6 buggy rpm automatic dep  generator to require: perl();
my $use = "use";

    print CMD <<EOF;
# $host_name host definition
define host {
  host_name                      $host_name
  alias                          $host_alias
  address                        $host_ip
  ${use}                            linux-server
  notification_period            24x7
}
EOF
    close CMD;
    return 0;
}



=back

=head1 TO DO

 * Effectively write the functions


=head1 AUTHORS
    (c) 2014 Olivier Lahaye C<< <olivier.lahaye@cea.fr> >>
             CEA (Commissariat A l'Energie Atomique et aux Energie Alternatives)
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

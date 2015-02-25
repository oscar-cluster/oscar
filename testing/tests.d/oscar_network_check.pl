#!/usr/bin/perl
#############################################################################
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
#   Copyright (c) 2006-2007 Oak Ridge National Laboratory.
#                      All rights reserved.
#   Copyright (C) 2006-2007 Geoffroy Vallee
#                      All rights reserved.
#   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
#                            aux Energies Alternatives
#                      All rights reserved.
#   Copyright (C) 2013-2014 Olivier LAHAYE <olivier.lahaye@cea.fr>
#                      All rights reserved.
#
# $Id: $
#
#############################################################################

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use warnings;
use English '-no_match_vars';
use POSIX;
use OSCAR::Network;
use OSCAR::ConfigFile;

my $rc = 0;
my $host_file = "/etc/hosts";

$ENV{LANG}="C";

my $oscar_if;
$oscar_if = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf",
                                          undef,
                                          "OSCAR_NETWORK_INTERFACE");
# If an env variable is set, it overwrites the value from the config file.
$oscar_if = $ENV{OSCAR_HEAD_INTERNAL_INTERFACE} 
    if defined $ENV{OSCAR_HEAD_INTERNAL_INTERFACE};

# we check now the IP assgned to the interface used by OSCAR
my $oscar_ip = get_host_ip ("oscar-server");
if ($oscar_ip eq "" || $oscar_ip eq "0.0.0.0") {
    print <<EOF;
 ----------------------------------------------------
 ERROR: oscar-server is not defined in $host_file.
 Please run "oscar-config --bootstrap"
 ----------------------------------------------------
EOF
    $rc++;
}

my $oscar_if_ip = `env LC_ALL=C /sbin/ip addr show $oscar_if | grep '$oscar_ip'`;
chomp ($oscar_if_ip);
#
#if ($oscar_ip ne "" and ($oscar_ip ne $oscar_if_ip)) {
if ($oscar_ip ne "" and ($oscar_if_ip eq "")) {
    print <<EOF;
 ----------------------------------------------------
 ERROR: it seems the interface used ($oscar_if) is not
 configured with oscar-server ip in $host_file.
 Please check your network configuration and
 /etc/oscar/oscar.conf before retrying.
 ----------------------------------------------------
EOF
    $rc++;
}

exit $rc;

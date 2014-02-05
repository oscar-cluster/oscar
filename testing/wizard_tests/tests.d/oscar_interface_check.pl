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
# if a env variable is set, it overwrites the value from the config file.
$oscar_if = $ENV{OSCAR_HEAD_INTERNAL_INTERFACE} 
    if defined $ENV{OSCAR_HEAD_INTERNAL_INTERFACE};
my %nics;
open IN, "netstat -nr | awk \'/\\./{print \$NF}\' | uniq |"
    || die "ERROR: Unable to query NICs\n";
while( <IN> ) {
    next if /^\s/ || /^lo\W/;
    chomp;
    s/\s.*$//;
    $nics{$_} = 1;
}
close IN;

if (! ($oscar_if and exists $nics{$oscar_if}) ) {
    if (!defined($oscar_if) || $oscar_if eq "") {
        $oscar_if = "<None>";
    }
    print " ------------------------------------------------------\n";
    print " WARNING: A valid NIC must be specified for the cluster\n";
    print " private network.\n";
    print " Valid NICs: ".join( ", ", sort keys %nics )."\n\n";
    print " You tried to use: " . $oscar_if . ".\n";
    print " This may be normal if this is the first time you \n";
    print " execute OSCAR.\n";
    print " ------------------------------------------------------\n";
    $rc++;
}

# we check now the IP assgned to the interface used by OSCAR
my $oscar_ip = get_host_ip ("oscar_server");
if ($oscar_ip eq FAILURE) {
    print " ----------------------------------------------------\n";
    print " WARNING: oscar_server is not defined in $host_file. \n";
    print " This may be normal if this is the first time you \n";
    print " execute OSCAR.\n";
    print " ----------------------------------------------------\n";
    $rc++;
}
#my $oscar_if_ip = `env LC_ALL=C /sbin/ifconfig $oscar_if | grep "inet addr:" | awk '{ print \$2 }' | sed -e 's/addr://'`;
my $oscar_if_ip = `env LC_ALL=C /sbin/ip addr show $oscar_if | grep '$oscar_ip'`;
chomp ($oscar_if_ip);
# the first time we execute OSCAR, /etc/hosts is not updated, it is 
# normal
#if ($oscar_ip ne "" and ($oscar_ip ne $oscar_if_ip)) {
if ($oscar_ip ne "" and ($oscar_if_ip eq "")) {
    print " ----------------------------------------------------\n";
    print " WARNING: it seems the interface used is not the one \n";
    print " assigned to OSCAR in $host_file. \n";
    print " This may be normal if this is the first time you \n";
    print " execute OSCAR.\n";
    print " ----------------------------------------------------\n";
    $rc++;
}

exit $rc;

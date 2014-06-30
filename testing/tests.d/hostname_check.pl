#!/usr/bin/perl -w
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

my $rc = 0;
my $host_file = "/etc/hosts";

$ENV{LANG}="C";

my $hostname = (uname)[1];
if ($hostname eq "") {
    print " ---------------------------------------\n";
    print " ERROR: Localhost name seems to be empty\n";
    print " ---------------------------------------\n";
    $rc++;
}
my ($shorthostname) = split(/\./,$hostname,2);
if ($shorthostname eq "") {
    print " --------------------------------------\n";
    print " ERROR: shorthostname seems to be empty\n";
    print " --------------------------------------\n";
    $rc++;
}
my $dnsdomainname = `dnsdomainname`;
chomp ($dnsdomainname);
if ($shorthostname eq "localhost") {
    print " -----------------------------------\n";
    print " ERROR: hostname cannot be localhost\n";
    print " -----------------------------------\n";
    $rc++;
}

# the value of hostname should not to be assigned to the loopback
# interface
my $hostname_ip = get_host_ip ($hostname);
if ($hostname_ip eq "" || $hostname_ip eq "0.0.0.0") {
    print " ----------------------------------------------\n";
    print " ERROR: Impossible get the IP for the hostname ($hostname) \n";
    print " ----------------------------------------------\n";
    $rc++;
}
if ($hostname_ip eq "127.0.0.1") {
    print " -------------------------------------------------\n";
    print " ERROR: your hostname ($hostname) is assigned to  \n";
    print " the loopback interface\n";
    print " Please assign it to your public network interface\n";
    print " updating $host_file\n";
    print " -------------------------------------------------\n";
    $rc++;
}

exit $rc;

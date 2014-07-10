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
# $Id:$
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
    my $valid_nics=join( ", ", sort keys %nics );
    print <<EOF;
 ------------------------------------------------------
 ERROR: A valid NIC must be specified for the cluster
 private network.
 Valid NICs: $valid_nics
 You tried to use: $oscar_if
 Please set a valid NIC for OSCAR_NETWORK_INTERFACE
 in /etc/oscar/oscar.conf
 ------------------------------------------------------
EOF
    $rc++;
}

exit $rc;

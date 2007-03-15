package OSCAR::Network;

#   $Id$

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#   Copyright 2002 International Business Machines
#                  Sean Dague <japh@us.ibm.com>

use strict;
use vars qw($VERSION @EXPORT);
use Carp;
use base qw(Exporter);
@EXPORT = qw(interface2ip);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# package scoped regex for an ip address.  If we ever need to support
# ipv6, we just need to change it here
my $ipregex = '\d+\.\d+\.\d+\.\d+';

#
# interface2ip - returns the ip addr, broadcast, and netmask of an interface
#

sub interface2ip {
    my $interface = shift;
    my ($ip, $broadcast, $net);

    # open pipes are better for controlling output than backticks
    open(IFCONFIG,"/sbin/ifconfig $interface |") or (carp("Couldn't run 'ifconfig $interface'"), return undef);
    while(<IFCONFIG>) {
        if(/^.*:($ipregex).*:($ipregex).*:($ipregex)\s*$/o) {
            ($ip, $broadcast, $net) = ($1,$2,$3);
            last;
        }
    }
    close(IFCONFIG);
    return ($ip, $broadcast, $net);
}

1;

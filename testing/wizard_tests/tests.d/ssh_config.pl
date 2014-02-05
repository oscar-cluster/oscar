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
#   Copyright (c) 2006 Oak Ridge National Laboratory.
#                      All rights reserved.
#   Copyright (c) 2006 Geoffroy Vallee
#                      All rights reserved.
#   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
#                            aux Energies Alternatives
#                      All rights reserved.
#   Copyright (c) 2013-2014 Olivier LAHAYE <olivier.lahaye@cea.fr>
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

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = FAILURE;

# We first test if the file /etc/ssh/sshd_config exists or not.
# If the file does not exist, it should be because it is the first time
# OSCAR runs, so we skip the sanity check
# If the file exists, we check the configuration.
if (!-e "/etc/ssh/sshd_config") {
    print "FYI the file does /etc/ssh/sshd_config not exists, it is not \
possible to check the sshd configuration. It is normal, most probably \
your Linux distribution does not install sshd by default, OSCAR will do it \
for you.";
    $rc = SUCCESS;
    }
else {
    my $ssh_config = `grep \"PermitRootLogin\" /etc/ssh/sshd_config | grep -v \"^\\s\*\#\" | awk ' { print \$2} '`;
    chomp ($ssh_config);
    if ( $ssh_config eq "yes" ) {
    	$rc = SUCCESS;
    } else {
    	print " ----------------------------------------------\n";
    	print "  $0 \n";
    	print "  Option PermitRootLogin in /etc/ssh/sshd_config should be \'yes\'\n";
    	print "  Current value is \'$ssh_config\'\n";
        print "  For users that compiled their own version of ssh, please be sure \
the configuration file matches the ssh configuration. The configuration file is \
our only way to check the ssh configuration\n";
    	print " ----------------------------------------------\n";

    	$rc = FAILURE;  
    }
}

exit($rc);

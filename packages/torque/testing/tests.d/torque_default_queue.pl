#!/usr/bin/perl 
#############################################################################
####
####   This program is free software; you can redistribute it and/or modify
####   it under the terms of the GNU General Public License as published by
####   the Free Software Foundation; either version 2 of the License, or
####   (at your option) any later version.
####
####   This program is distributed in the hope that it will be useful,
####   but WITHOUT ANY WARRANTY; without even the implied warranty of
####   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
####   GNU General Public License for more details.
####
####   You should have received a copy of the GNU General Public License
####   along with this program; if not, write to the Free Software
####   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
####
####   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
####                            aux Energies Alternatives
####                            All rights reserved.
####   Copyright (C) 2013-2014  Olivier LAHAYE <olivier.lahaye@cea.fr>
####                            All rights reserved.
####
#### $Id: $
####
################################################################################

use strict;
use warnings;

use OSCAR::Logger;
use OSCAR::LoggerDefs;

my $qmgr_cmd;
if (-x '/usr/bin/qmgr') {
   $qmgr_cmd='/usr/bin/qmgr';
} else {
   $qmgr_cmd='/opt/pbs/bin/qmgr';
}

my $default_queue_count = `$qmgr_cmd -c "l s" | grep -c 'default_queue'`;
if ($?) {
    oscar_log(5, ERROR, "Failed to run: $qmgr_cmd. Can't check default_queue. Aborting");
    exit 1;
}

chomp ($default_queue_count);
if ($default_queue_count != 1) {
    oscar_log(5, ERROR, "We should have one default_queue. We have $default_queue_count default_queues.");
    exit 1;
}

exit 0;

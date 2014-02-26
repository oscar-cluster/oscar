#!/usr/bin/perl -w
#############################################################################
###
###   This program is free software; you can redistribute it and/or modify
###   it under the terms of the GNU General Public License as published by
###   the Free Software Foundation; either version 2 of the License, or
###   (at your option) any later version.
###
###   This program is distributed in the hope that it will be useful,
###   but WITHOUT ANY WARRANTY; without even the implied warranty of
###   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
###   GNU General Public License for more details.
###
###   You should have received a copy of the GNU General Public License
###   along with this program; if not, write to the Free Software
###   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
###
###   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
###                            aux Energies Alternatives
###                            All rights reserved.
###   Copyright (C) 2013-2014  Olivier LAHAYE <olivier.lahaye@cea.fr>
###                            All rights reserved.
###
### $Id: $
###
###############################################################################

use strict;
use warnings;
use Carp;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

# FIXME: Need to check that services are up and running on head at least.

exit 0;

#!/bin/bash
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
#   Copyright (c) 2013-2014 CEA - Commissariat à l'énergie atomique et
#                            aux énergies alternatives
#                            All rights reserved.
#   Copyright (C) 2013-2014  Olivier LAHAYE <olivier.lahaye@cea.fr>
#                            All rights reserved.
#
# $Id: $
#
#############################################################################
SOME_NODES_ARE_DOWN=0
for node in $(/usr/lib/oscar/testing/helpers/oscar_nodes.sh)
do
    if ! ping -c1 $node >/dev/null 2>&1
    then
        echo "$node is down"
        SOME_NODES_ARE_DOWN=1
    fi
done
exit $SOME_NODES_ARE_DOWN

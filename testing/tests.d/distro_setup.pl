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
use OSCAR::PackagePath;
use OSCAR::Utils;

# We Get the detected distro id.
my $distro_id = get_distro();
if (!OSCAR::Utils::is_a_valid_string ($distro_id)) {
    die "ERROR: Impossible to detect the local distro ID";
}

# We check that our detected distro id is in the configured distros.
my @setup_distros = OSCAR::PackagePath::get_list_setup_distros ();
if (scalar (@setup_distros) == 0 ||
    !OSCAR::Utils::is_element_in_array ($distro_id, @setup_distros)) {
    die "ERROR: The local distro is not setup, please run \"oscar-config ".
        "--setup-distro &lt;distro_id&gt;\" first (see man oscar-config for more ".
        "details";
}

exit(0);

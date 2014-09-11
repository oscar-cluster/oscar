#!/usr/bin/perl 
#===============================================================================
#
#         FILE: Check_ganglia_head_services.pl
#
#        USAGE: ./check_ganglia_head_services.pl  
#
#  DESCRIPTION: check that gmetad and gmond are up on head so further testing can
#               be done.
#
#       AUTHOR: Olivier LAHAYE (olivier.lahaye@cea.fr), 
# ORGANIZATION: CEA
#      VERSION: 1.0
#      CREATED: 11/09/2014 17:44:24
#===============================================================================

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This script checks that ganglia services are enabled on head.
#
#  Copyright (c) 2014   Commissariat à L'Énergie Atomique et
#                       aux Énergies Alternatives
#                       Olivier Lahaye <olivier.lahaye@cea.fr>
#                       All rights reserved.
#
use strict;
use warnings;

use OSCAR::SystemServices;
use OSCAR::SystemServicesDefs;
use OSCAR::Logger;
use OSCAR::LoggerDefs;

my $return_code = 0;

if ( system_service_status(GANGLIA_GMETAD) == SERVICE_ENABLED ) {
    oscar_log(5, INFO, "OK: Ganglia gmetad is enabled on head.");
} else {
    $return_code++;
}

if ( system_service_status(GANGLIA_GMOND) == SERVICE_ENABLED ) {
    oscar_log(5, INFO, "OK: Ganglia gmond is enabled on head.");
} else {
    $return_code++;
}

exit $return_code;

#!/usr/bin/perl 
#===============================================================================
#
#         FILE: Check_slurm_head_services.pl
#
#        USAGE: ./check_slurm_head_services.pl  
#
#  DESCRIPTION: check that slurmctld are enabled and up on head so further testing can
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

# Check that service is enabled.
if ( system_service_status(SLURMCTLD) == SERVICE_ENABLED ) {
    oscar_log(5, INFO, "slurmctld is enabled on head.");
} else {
    oscar_log(5, ERROR, "slurmctld is not enabled on head.");
    $return_code++;
}

# Check that service is up

open (SCONTROL,"scontrol ping|")
    or (oscar_log(1, ERROR, "Can't run 'scontrol ping': $!"), exit 1);
if (<SCONTROL> !~ m/^Slurmctld.*UP\//) {
    oscar_log(5, ERROR, "slurmctld not seen by scontrol ping");
    $return_code++;
} else {
    oscar_log(5, INFO, "slurmctld UP (at least on master head node)");
}

close(SCONTROL);

exit $return_code;

#!/usr/bin/perl -w
#############################################################################
##
##   This program is free software; you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##   the Free Software Foundation; either version 2 of the License, or
##   (at your option) any later version.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU General Public License for more details.
##
##   You should have received a copy of the GNU General Public License
##   along with this program; if not, write to the Free Software
##   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##
##   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
##                            aux Energies Alternatives
##                            All rights reserved.
##   Copyright (c) 2013-2014  Olivier LAHAYE <olivier.lahaye@cea.fr>
##                            All rights reserved.
##
## $Id: $
##
##############################################################################

use strict;
use warnings;
use Carp;
use OSCAR::Package;
use OSCAR::Testing;
use OSCAR::Utils;
use OSCAR::Logger;
use OSCAR::LoggerDefs;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

my $datadir = get_data_dir('torque');
my $testuser = get_test_user();
my $i_am = getpwuid($<) || "unknown";

# Test that we are running as a normal user.
if ( "$testuser" ne "$i_am" ) {
	oscar_log(1, ERROR, "Test must run under the OSCAR test user");
    oscar_log(1, ERROR, "I am: $i_am and should be: $testuser");
    exit 1;
}

# Try to chdir to HOMEDIR
return 1 unless chdir;

# cleanup old stuffs if any.
unlink glob "shelltest.*";

# Get the PBS test script
my $pbs_script = "$datadir/pbs_script.shell";
if ( ! -r "$pbs_script" ) {
    oscar_log(1, ERROR, "Can't read $pbs_script");
    exit 1;
}

my $torque_bin="/usr/bin";
$torque_bin="/opt/pbs/bin" if (-x '/opt/pbs/bin/qsub');

my $cmd = "$torque_bin/qsub $pbs_script";

!oscar_system($cmd)
    or exit 1;

# 10 seconds to get the answer should be far sufficient.
for( my $retry=0; $retry <= 10; $retry++) {
    last if ( -f "shelltest.out" );
    sleep 1;
}

# Check that we got some output.
if (! -f "shelltest.out") {
    oscar_log(1, ERROR, "Timout: no result after 10 seconds.");
    oscar_log(1, ERROR, "Content of the queue:");
    oscar_system("$torque_bin/qstat -a");
    exit 1;
}

# Check that shelltest.err is an empty file.
my $err_output_size = -s "shelltest.err";
if ( -s "shelltest.err" ) {
    oscar_log(1, ERROR, "shelltest.err is not empty, there was a problem. Check ~$testuser/shelltest.*");
    exit 1;
}

# Check that the output contains the Hello word.
if (! open FH, "<", "shelltest.out") {
    oscar_log(1, ERROR, "Failed to read the shelltest.out file");
    exit 1;
}

my @seen = grep {/Hello/} <FH>;
if (scalar (@seen) == 0) {
    oscar_log(1, ERROR, "shelltest.out doesn't contain the Hello word. something is wrong.");
    exit 1;
}

# Cleanup (no errors, thus useless output files).
unlink glob "shelltest.*";

exit 0;

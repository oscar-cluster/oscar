#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# This script performs some very basic test(s) of 'system-sanity'.
#
# Outline:
#  [Test1]
#    1. Create a simple 'always-fail' test
#    2. Run the 'system-sanity' tool (will see a FAILURE)
#    3. Remove the 'always-fail' test (cleanup)
#         

use warnings;
use strict;

BEGIN {
 # Display an error if OSCAR_HOME not set, 
 # put in BEGIN block to avoid interpreter errors
 die "\nError: OSCAR_HOME not defined\n\n" unless (defined($ENV{OSCAR_HOME}));
}

use lib "$ENV{OSCAR_HOME}/lib"; 
use OSCAR::Logger;

my $system_sanity_dir = "$ENV{OSCAR_HOME}/scripts/system-sanity.d";


# ------------ [Test1] ------------
oscar_log_section("Start TEST1: 'alway-fail' - should see a FAILURE");

my $test1_body = <<EOF;
#!/usr/bin/perl
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# 'always-fail.pl'

use warnings;
use lib "\$ENV{OSCAR_HOME}/lib";
use OSCAR::SystemSanity;

print " ----------------------------------------------\\n";
print "    \\'always-fail\\' test driver...It Always Fails! \\n";
print " ----------------------------------------------\\n";

exit(FAILURE);
EOF

 #
 # 1. Create a simple 'always-fail' test
 #
my $test1_file = $system_sanity_dir . "/" . "always-fail.pl";

oscar_log_subsection("Create file: \'$test1_file\'");

open(FH, ">$test1_file") or die "Error: creating file \'$test1_file\'";
print FH $test1_body;
close(FH);
chmod(0755, $test1_file);

 #
 # 2. Run the 'system-sanity' tool 
 #
oscar_log_subsection("Run system-sanity tool:");

if ( system("$ENV{OSCAR_HOME}/scripts/system-sanity") ) {
        print "ERROR: There are basic system configuration issues.\n";
	print " ** Notice: Continue b/c we are just testing! ;) **\n\n";
}

 #
 # 3. (cleanup) Remove the 'always-fail' test 
 #
oscar_log_subsection("Remove file: \'$test1_file\'");
unlink($test1_file);

oscar_log_subsection("TEST1 Complete");


exit(0);


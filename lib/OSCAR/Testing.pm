package OSCAR::Testing;

#   $Id: $

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

#   Copyright 2014 CEA Commissariat a l'Energie Atomique et aux Energies Alternatives
#                       Olivier LAHAYE <olivier.lahaye@cea.fr>

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);
use OSCAR::Tk;

@EXPORT = qw(
                display_apitest_results
                run_apitest
            );

$VERSION = sprintf("r%d", q$Revision: 7332 $ =~ /(\d+)/);

# Open a window with the apitests results.
sub display_apitest_results {
    my ($window, $test_name, $test_results) = @_;
    my $apitestwin = $window->Toplevel();
    $apitestwin->withdraw;
    $apitestwin->title("Testing: $test_name");
    my $apitestp = $apitestwin->Scrolled("ROText",-scrollbars=>"e",-wrap=>"word",
                                 -width=>80,-height=>25);
    $apitestp->grid(-sticky=>"nsew");
    my $cl_b = $apitestwin->Button(-text=>"Close",
                                -command=> sub {$apitestwin->destroy},-pady=>"8");
    $apitestwin->bind("<Escape>",sub {$cl_b->invoke()});
    $cl_b->grid(-sticky=>"nsew",-ipady=>"4");
    $apitestp->delete("1.0","end");


    # Display tests results.
    $apitestp->insert("end",$test_results);

    OSCAR::Tk::center_window( $apitestwin );
}

################################################################################
# Run an apitest script or batch.
# 
# input:  $window : main window
#         $test_name : test filename (without path)
#
# output: 0 => success.
#         non 0 => error (and displays a window with the errors)
################################################################################
sub run_apitest {
    my ($window, $test_name) = @_;
    my $apitests_path="/usr/lib/oscar/testing/wizard_tests";
    my $cmd = "LC_ALL=C /usr/bin/apitest -T -v -f $apitests_path/$test_name";
    my $test_output = "";
    my $rc = 0 ; # SUCCESS

    # Test that test file exists.
    if ( ! -f "$apitests_path/$test_name" ) {
        $rc = 255; # File not found.
        $test_output = "ERROR: Test $apitests_path/$test_name not found";
        display_apitest_results($window, $test_name, $test_output);
        return($rc);
    }

    # Run the test and collect the output if any.
    if(open CMD, "$cmd |") {
        # Problem: can't run the command.
        $rc = $!;
        $test_output = "ERROR: Can't run $cmd";
        display_apitest_results($window, $test_name, $test_output);
        return($rc);
    }
    while (my $line = <CMD>) {
        chomp($line);
        $test_output .= "$line\n";
    }
    close CMD; # to get the exit code.
    $rc = $?;
    # if $rc is not 0, we need to display the result tests.
    if ($rc != 0) {
        display_apitest_results($window, $test_name, $test_output);
    }
    exit($rc);
}

1;


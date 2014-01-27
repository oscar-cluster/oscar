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
use OSCAR::Env;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::Tk;
use OSCAR::Package;
use OSCAR::Database;
use Tk::ROTextANSIColor;


@EXPORT = qw(
                display_apitest_results
                display_ANSI_results
                run_apitest
                run_multiple_tests
                test_cluster
                step_test
            );


$VERSION = sprintf("r%d", q$Revision: 7332 $ =~ /(\d+)/);

=encoding utf8

=head1 NAME

OSCAR::Testing - Set of functions to ease OSCAR testing.

=head1 SYNOPSIS

use OSCAR::Testing;

=head1 DESCRIPTION

This module provides a collection of fuctions to easy OSCAR testing.

It is based on APItest, a portable testing framework developed at
Sandia National Laboratories to address some of the development challenges
inherent in distributed systems software for massively parallel processing (MPP)
machines.

=head2 Functions

=over 4

=cut
################################################################################
=item display_apitest_results($window, $test_name, $test_results)

Open a window with the apitests results.

 Input:       $window : Main window
               $title : Test short description.
        $test_results : text output of the test.
Return: none

Exported: YES

=cut
################################################################################
sub display_apitest_results($$$) {
    my ($window, $title, $test_results) = @_;
    my $apitestwin = $window->Toplevel();
    $apitestwin->withdraw;
    $apitestwin->title("Testing: $title");
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
=item display_ANSI_results($window, $test_name, $test_results)

Open a window with the apitests results. (Honoring color ANSI codes)

 Input:       $window : main window
               $title : Test short description.
        $test_results : text output of the test.
Return: none

Exported: YES

=cut
################################################################################
sub display_ANSI_results($$$) {
    my ($window, $title, $test_results) = @_;
    my $apitestwin = $window->Toplevel();
    $apitestwin->withdraw;
    $apitestwin->title("Testing: $title");
    my $apitestp = $apitestwin->ROTextANSIColor(-width=>80,-height=>25);
    $apitestp->grid(-sticky=>"nsew");
    my $cl_b = $apitestwin->Button(-text=>"Close",
                                -command=> sub {
                                                  $window->Unbusy();
                                                  $apitestwin->destroy},
                                -pady=>"8");
    $apitestwin->bind("<Escape>",sub {$cl_b->invoke()});
    $cl_b->grid(-sticky=>"nsew",-ipady=>"4");
    $apitestp->delete("1.0","end");

    # Display tests results.
    # We need to keep TextANSIColor quiet. (it whine about unknown ANSI codes)
    # Thus we redirect stdout (after keeping track of it)
    open OLDOUT, '>&STDOUT';
    {
        local *STDOUT;
        open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
        $apitestp->insert("end",$test_results);
        $apitestp->update;
        close STDOUT;
    }
    # Restore stdout (don't die if it fails, we need to close OLDOUT anyway).
    open STDOUT, '>&OLDOUT' or oscar_log(5, ERROR, "Can't restore stdout: $!");
    # Avoid leaks by closing the independent copies.
    close OLDOUT or oscar_log(5, ERROR, "Can't close OLDOUT: $!");

    OSCAR::Tk::center_window( $apitestwin );
}

## FIXME: use OSCAR::Tk for that.
sub display_cluster_test_succed($) {
    my $window = shift;
    my $title = "Cluster test SUCCESS";
    oscar_log(1, INFO, $title);
    OSCAR::Tk::done_window($window, $title, sub { $window->Unbusy() });
    #$window->Unbusy();
}

################################################################################
=item run_apitest($test_name)

Run an apitest script or batch.

 Input:  $test_name : test filename (without path)
Return: $test_output: The text output of the test.
        $rc: The return code of the test.

Exported: YES
=cut
################################################################################
sub run_apitest($) {
    my $test_name = shift;
    my $apitests_path="/usr/lib/oscar/testing/wizard_tests";
    my $apitest_options = "-T";
    if($OSCAR::Env::oscar_verbose >= 10) { # debug option
        $apitest_options = "-o /var/log/oscar -v";
    } elsif ($OSCAR::Env::oscar_verbose >= 5) { # verbose option
        $apitest_options = "-T -v";
    }
    my $cmd = "cd $apitests_path; LC_ALL=C /usr/bin/apitest $apitest_options -f $test_name";
    my $test_output = "";
    my $rc = 0 ; # SUCCESS

    # Test that test file exists.
    if ( ! -f "$apitests_path/$test_name" ) {
        $rc = 255; # File not found.
        $test_output = "Test $apitests_path/$test_name not found";
        return($test_output, $rc);
    }

    # Run the test and collect the output if any.
    oscar_log(7, ACTION, "About to run: $cmd");
    if(! open CMD, "$cmd |") {
        # Problem: can't run the command.
        $rc = $!;
        $test_output = "Can't run $cmd ($rc)";
        oscar_log(5, ERROR, "Failed to run: $cmd");
        return($test_output, $rc);
    }
    my $quoted_test_name = quotemeta $test_name;
    while (my $line = <CMD>) {
        chomp($line);
        my $pattern = ".*FAIL.*".$quoted_test_name."\$";
        my $reqgexp = qr/$pattern/;
        if ( $line =~ $reqgexp ) {
            $rc = 1;
        }
        $test_output .= "$line\n";
    }
    close CMD; # to get the exit code.
    my $cmd_rc = $?/256;
    oscar_log(5,ERROR, "Bad exit ($cmd_rc) from $cmd") if ($cmd_rc > 0);

    if ($rc > 0) {
        oscar_log(5, ERROR, "Test $test_name failed.");
        oscar_log(6, ERROR, "apitest result was:\n$test_output") if ($rc > 0);
    } else {
        oscar_log(5, INFO, "Test $test_name succeeded.");
    }
    $rc += $cmd_rc;

    return($test_output, $rc);
}

################################################################################
=item run_multiple_tests(@apitests_to_run)

Run a set of apitests and display an error window if needed.

 Input: @apitests_to_run: the list of apitests to run.
Return: 1 if an arror occured
        0 if test ran without error.

Exported: YES

=cut
################################################################################
sub run_multiple_tests(@) {
    my @apitests_to_run = @_;
    my $test_output;
    my $rc;
    my $all_output = "";
    my $all_rc = 0;
    for my $test_to_run ( @apitests_to_run ) {
        ($test_output, $rc) = run_apitest($test_to_run);
        $all_output .= "Processing test: $test_to_run\n================================================================================\n";
        if($rc > 0) {
            $all_output .= "=> FAILED!\n$test_output\n\n";
            $all_rc = 1; # Keep track that at least one test failed.
#            oscar_log(5, ERROR, $all_output);
        } else {
            $all_output .= "=> PASSED\n\n";
        }
    }
#    if ($all_rc == 0) {
#        oscar_log(5, INFO, "Successfully passed the following tests: ".join(" ",@apitests_to_run));
#    }
    return($all_output, $all_rc);
}

################################################################################
=item test_cluster()


 Input: $window: the parent window to attach to.
Return: 0: upon success (displays a success dialog box)
        1: upon error (displays test results)

=cut
################################################################################
sub test_cluster($) {
    my $window = shift;
    my $apitests_path="/usr/lib/oscar/testing/wizard_tests";
    my @tests_to_run = ( 'base_system_validate.apb' );
    my @pkgs_hash = list_selected_packages();
    my $output = "";
    my $rc = 0;

    # 1st, create oscar testing environment.
    oscar_log(5, INFO, "Creating oscartst user if needed");
    my $cmd = "$apitests_path/helpers/create_oscartst.sh";
    oscar_log(7, ACTION, "About to run: $cmd");
    !system($cmd)
        or oscar_log(5, ERROR,"Cant create oscartst user");

    # FIXME: Copy files to oscartst user if needed.
    oscar_log(5, INFO, "Copying files for oscartst user (FIXME: NOT IMPLEMENTED)");

    # Add packages tests to the list of tests.
    oscar_log(5, INFO, "Querying tests to run for opkgs.");
    foreach my $pkg_name (@pkgs_hash) {
        if ( -f "$apitests_path/$pkg_name"."_validate.apb" ) {
            push @tests_to_run, "$pkg_name"."_validate.apb";
            oscar_log(6, INFO, "Adding test: $pkg_name"."_validate.apb to the test list");
        }
    }

    # Run all the tests.
    oscar_log(5, INFO, "About to perform the following tests: \n  - " .
                        join("\n  - ", @tests_to_run) . "\n");
    ($output,$rc) = run_multiple_tests(@tests_to_run);
    if( $rc > 0) {
        display_ANSI_results($window, "Cluster validation", $output);
    } else {
        display_cluster_test_succed($window);
    }
    return ($rc);
}

################################################################################
=item step_test()


 Input:    $window: The parent window to attach to.
        $test_name: The name of the test to be run.
Return: 0: upon success
        1: upon error and displays test results in a dialog box.

=cut
################################################################################
sub step_test($$) {
    my ($window, $step_name ) = @_;
    my $test_name="before_".$step_name.".apb";
    my $output= "";
    my $rc=0;
    ($output,$rc) = run_multiple_tests($test_name);
    if( $rc > 0) {
        $output = "Requirements for step '$step_name' are not met.\nPlease fix problems before retrying.\n\n".$output;
        display_ANSI_results($window, $test_name, $output);
        oscar_log(1, INFO, "Refusing to enter step \"$step_name\" (Requirements not met).");
    } else {
        oscar_log(5, INFO, "Ready to enter step \"$step_name\"");
    }
    return ($rc);
}

=back

=head1 TO DO

 * Add color support in output (display window)
 * Add HTML or XML browser for diagnostics instead of launching a web browser.
   (Directly browsing xml output, thus avoid using apitest httpd,
    could be a good improvement).

=head1 SEE ALSO

L<OSCAR::Packages>

=head1 AUTHORS

Written and documented by:
    (c) 2014      Olivier Lahaye C<< <olivier.lahaye@cea.fr> >>
                  CEA (Commissariat à l'Énergie Atomique)
                  All rights reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

1;

__END__

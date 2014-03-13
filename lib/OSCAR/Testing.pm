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
use OSCAR::Utils;
use OSCAR::OCA::OS_Settings;
use Tk::ROTextANSIColor;
use XML::Simple;
use File::Basename;
use File::Path qw(remove_tree);

@EXPORT = qw(
                display_apitest_results
                display_ANSI_results
                run_apitest
                run_multiple_tests
                test_cluster
                step_test
                apitest_xml_to_text
                get_user_home
                get_test_user
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

 Input:        $window : main window
                $title : Test short description.
         $test_results : text output of the test.
        $error_details : Details of the failed tests.
Return: none

Exported: YES

=cut
################################################################################
sub display_ANSI_results($$$$) {
    my ($window, $title, $test_results, $error_details) = @_;
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
        $apitestp->insert("end",$test_results."\n========\nDetails:========\n\n".$error_details);
        $apitestp->update;
        close STDOUT;
    }
    # Restore stdout (don't die if it fails, we need to close OLDOUT anyway).
    open STDOUT, '>&OLDOUT' or oscar_log(5, ERROR, "Can't restore stdout: $!");
    # Avoid leaks by closing the independent copies.
    close OLDOUT or oscar_log(5, ERROR, "Can't close OLDOUT: $!");

    OSCAR::Tk::center_window( $apitestwin );
}

=cut
################################################################################
=item get_failed_tests_from_batch_log($test_full_name)

Parse test xml output and returns an array of failed tests.

 Input:       $result_file:  apitest batch log.
Return:       @failed_tests: array of failed tests.

Exported: NO

=cut
################################################################################
sub get_failed_tests_from_batch_log($)
{
    my $result_file = shift;
    my $xml = new XML::Simple;
    my $parsed_hash = $xml->XMLin($result_file);
    my @failed_tests = ();
    my @sub_tests;

    if( ref($parsed_hash->{child}) ne 'ARRAY') {
        push(@sub_tests,$parsed_hash->{child});
    } else {
        @sub_tests = @{$parsed_hash->{child}};
    }
    for my $test (@sub_tests) {
        if ($test->{status} ne "PASS") { # Test failed or had problem.
            push (@failed_tests, $test->{file})
                if($parsed_hash->{filename} ne $test->{file}); # Avoid pushing self
        }
    }
    return(@failed_tests);
}

=cut
################################################################################
=item apitest_xml_to_text($test_full_name)

Parse test xml output and display as normal test.

 Input:       $testlog_full_name: The full path name of the test log (apt or apf)
Return:       $error_output:      Formatted test error message.

Exported: NO

=cut
################################################################################
sub apitest_xml_to_text($); # Prototype to avaid warning at runtime.
sub apitest_xml_to_text($) {
    my $test_full_name = shift;
    return("Missing test file: $test_full_name\n")
        if( ! -f $test_full_name );
    my $test_file_name = basename($test_full_name);
    my $test_name;
    my $test_type;
    my $error_output = "";
    if ($test_file_name =~ /(.*)\.ap(.)/) {
        $test_name = $1;
        $test_type = $2;
    }  else {
        oscar_log(5, ERROR, "API Error: $test_name is not an apitest test or batch script");
        return "API Error: $test_name is not an apitest test or batch script";
    }
    my $apitests_logdir=OSCAR::OCA::OS_Settings::getitem('oscar_apitests_logdir');
    my @result_file = glob("$apitests_logdir/run.*/$test_type*$test_name.out");
    if ( -s $result_file[0] ) {
       if ( $test_type eq "b" ) {
           my @failed_tests = get_failed_tests_from_batch_log($result_file[0]);
           for my $test (@failed_tests) {
               $error_output .= apitest_xml_to_text($test);
           }
       } elsif ( $test_type eq "t" ) {
           my $xml = new XML::Simple;
           my $parsed_hash = $xml->XMLin($result_file[0]);
           if ($parsed_hash->{status} eq "FAIL") {
               $error_output .= "Failed script: $test_name.apt\n";
               if ($parsed_hash->{output}->{ERROR}) {
                   chomp($parsed_hash->{output}->{ERROR}->{actual});
                   $error_output .= "=> Apitest ERROR:\n$parsed_hash->{output}->{ERROR}->{actual}\n";
               }
               if ($parsed_hash->{output}->{status}->{matched} eq "NO") {
                   chomp($parsed_hash->{output}->{stdout}->{actual});
                   $error_output .= "=> Unexpected return code: $parsed_hash->{output}->{status}->{actual}\n";
               }
               if ($parsed_hash->{output}->{stdout}->{matched} eq "NO") {
                   chomp($parsed_hash->{output}->{stdout}->{actual});
                   $error_output .= "=> Unexpected stdout:\n$parsed_hash->{output}->{stdout}->{actual}\n";
               }
               if ($parsed_hash->{output}->{stderr}->{matched} eq "NO") {
                   chomp($parsed_hash->{output}->{stderr}->{actual});
                   $error_output .= "=> Unexpected stderr:\n$parsed_hash->{output}->{stderr}->{actual}\n";
               }
               $error_output .= "--------------\n";
           } # Else FAILDEP (no error to display (done before) and no usefull things to tell to user).
       }
    } else {
        oscar_log(5, ERROR, "No output for test $test_full_name.");
        oscar_log(5, ERROR, "file not found.") if ( ! -f $test_full_name );
    }
    return($error_output);
}

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
        $error_details: error explanation if error occured or "".

Exported: YES
=cut
################################################################################
sub run_apitest($) {
    my $test_name = shift;
    my $test_output = "";
    my $rc = 0 ; # SUCCESS
    my $error_details = "";
    my $olddir = Cwd::cwd();

    my $testing_path = OSCAR::OCA::OS_Settings::getitem('oscar_testing_path');
    if ( -d "$testing_path") {
        chdir $testing_path; # We are working on relative path. Need to move in oscar_testing_path.
     } else {
        $test_output = "$testing_path not found.";
        $error_details = "Can't run tests, no $testing_path\n";
        oscar_log(5, ERROR, "$test_output");
        return($test_output, $rc, $error_details);
    }
    #my $apitests_path = "apitests.d";
    my $apitests_logdir = OSCAR::OCA::OS_Settings::getitem('oscar_apitests_logdir');
    my $apitest_options = "-o $apitests_logdir";
    if($OSCAR::Env::oscar_verbose >= 10) { # debug option
        $apitest_options .= " -v";
    } elsif ($OSCAR::Env::oscar_verbose >= 5) { # verbose option
        $apitest_options .= " -v";
    }
    # Cleaing up apitest previous logs.
    remove_tree($apitests_logdir);
    my $cmd = "LC_ALL=C /usr/bin/apitest $apitest_options -f apitests.d/$test_name";

    # Test that test file exists.
    if ( ! -f "apitests.d/$test_name" ) {
        $rc = 255; # File not found.
        $test_output = "Test apitests.d/$test_name not found";
        $error_details = "$test_output\n";
        chdir($olddir);
        return($test_output, $rc, $error_details);
    }

    # Run the test and collect the output if any.
    oscar_log(7, ACTION, "About to run: $cmd");
    if(! open CMD, "$cmd |") {
        # Problem: can't run the command.
        $rc = $!;
        $test_output = "Can't run $cmd ($rc)";
        $error_details = "$test_output\n";
        oscar_log(5, ERROR, "$test_output");
        chdir($olddir);
        return($test_output, $rc, $error_details);
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
        oscar_log(6, ERROR, "apitest result was:\n$test_output");
        $error_details = apitest_xml_to_text("apitests.d/$test_name");
        oscar_log(1, ERROR, "Error details:\n$error_details");
    } else {
        oscar_log(5, INFO, "Test $test_name succeeded.");
    }
    $rc += $cmd_rc;

    chdir($olddir);
    return($test_output, $rc, $error_details);
}

################################################################################
=item run_multiple_tests(@apitests_to_run)

Run a set of apitests and display an error window if needed.

 Input: @apitests_to_run: the list of apitests to run.
Return: $all_output:        output from apitest.
        $all_rc:            1 if an arror occured 0 if test ran without error.
        $all_error_details: details off tests errors.

Exported: YES

=cut
################################################################################
sub run_multiple_tests(@) {
    my @apitests_to_run = @_;
    my $test_output;
    my $rc;
    my $all_output = "";
    my $all_rc = 0;
    my $error_details;
    my $all_error_details = "";
    for my $test_to_run ( @apitests_to_run ) {
        ($test_output, $rc, $error_details) = run_apitest($test_to_run);
        $all_output .= "Processing test: $test_to_run\n================================================================================\n";
        if($rc > 0) {
            $all_output .= "=> FAILED!\n$test_output\n\n";
            $all_error_details .= $error_details;
            $all_rc = 1; # Keep track that at least one test failed.
#            oscar_log(5, ERROR, $all_output);
        } else {
            $all_output .= "=> PASSED\n\n";
        }
    }
#    if ($all_rc == 0) {
#        oscar_log(5, INFO, "Successfully passed the following tests: ".join(" ",@apitests_to_run));
#    }
    return($all_output, $all_rc, $all_error_details);
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
    my $testing_path = OSCAR::OCA::OS_Settings::getitem('oscar_testing_path');
    my $apitests_path = $testing_path . "/apitests.d";
    my @tests_to_run = ( 'base_system_validate.apb' );
    my @pkgs_hash = list_selected_packages();
    my $output = "";
    my $error_details = "";
    my $rc = 0;

    # 1st, create oscar testing environment.
    oscar_log(5, INFO, "Creating oscartst user if needed");
    my $cmd = "$testing_path/helpers/create_oscartst.sh";
    !oscar_system($cmd)
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
    ($output,$rc,$error_details) = run_multiple_tests(@tests_to_run);
    if( $rc > 0) {
        display_ANSI_results($window, "Cluster validation", $output, $error_details);
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
    my $error_details = "";
    my $rc=0;
    ($output,$rc, $error_details) = run_multiple_tests($test_name);
    if( $rc > 0) {
        $output = "Requirements for step '$step_name' are not met.\nPlease fix problems before retrying.\n\n".$output;
        display_ANSI_results($window, $test_name, $output, $error_details);
        oscar_log(1, INFO, "Refusing to enter step \"$step_name\" (Requirements not met).");
    } else {
        oscar_log(5, INFO, "Ready to enter step \"$step_name\"");
    }
    return ($rc);
}

##############################################################################
=item get_user_home ($user)

Return return the home directory for a giver user.

Input:  The name of the user

Return: Path of the user or undef.

=cut
###############################################################################

sub get_user_home ($) {
    my $user = shift;
    if (! defined($user)) {
        oscar_log(5, ERROR, "user undefined");
        return undef;
    }
    my $getent=`getent passwd $user`;
    if ($? >0) {
        oscar_log(5, ERROR, "Failed to getent passwd $user");
        return undef;
    }
    my @entries = split(":", $getent);
    my $path = $entries[5];
    chomp($path);
    return ($path);
}

##############################################################################
=item get_test_user ()

Return return the user name that should be used for testing

Input:  None.

Return: OSCAR test username

=cut
###############################################################################

sub get_test_user () {
    return OSCAR::OCA::OS_Settings::getitem('oscar_test_user');
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

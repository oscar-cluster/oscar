package OSCAR::FrontPanel;

#   $Id: FrontPanel.pm,v 1.15 2002/10/15 05:41:40 jsquyres Exp $

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

#   Copyright 2001-2002 International Business Machines
#                       Sean Dague <japh@us.ibm.com>

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use Net::Netmask;
use vars qw($VERSION @EXPORT);
use Tk;
use Tk::Tree;
use Carp;
use File::Copy;
use base qw(Exporter);
use OSCAR::Logger;
use OSCAR::Tk;
@EXPORT = qw(frontpanel_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/);

my %MAC = (); # mac will be -1 for unknown, machine name for known
my $COLLECT = 0;
my $PINGPID = undef;

# Text and values for the two MPI's that are currently included in
# OSCAR.  These will someday change/be moved elsewhere when we have
# proper MPI package detection.

my $lam_text = "LAM/MPI 6.5.6";
my $lam_value = "lam-6.5.6";
my $mpich_text = "MPICH 1.2.4";
my $mpich_value = "mpich-1.2.4";

# Globals to the module

my ($parent_window, $fp_window);
my ($setupbutton, $exitbutton);
my ($lambutton, $mpichbutton, $mpivalue);
my $have_run_successfully = 0;
my $vars;

#
# Initial front panel window code.  Set the parent window to busy and
# sanity check to see if we have already run step 1.
#

sub frontpanel_window {
    $parent_window = shift;
    $vars = shift;

    oscar_log_section("Running step 1 of the OSCAR wizard");

    # Make the top-level OSCAR wizard window busy so that the user
    # can't click in another step while this one is running.

    $parent_window->Busy(-recurse => 1);

    # Before we do anything else, see if we have already run this step

    if ($have_run_successfully) {
	oscar_log_subsection("Warning: have already run this step");
	yesno_window($parent_window,
		     "Re-run step?",
		     "WARNING: You have already run this step.  " .
		     "Do you really want to run it again?",
		     \&fp_yes, \&fp_no);
	return 1;
    } else {
	return do_fp_work();
    }
}


#
# Entry point for where we have already run step 1, yet the user
# selects to run it again.
#

sub fp_yes {
    do_fp_work();
    return 1;
}


#
# Entry point for where we have already run step 1, and the user
# selects to *not* run it again.
#

sub fp_no {
    $parent_window->Unbusy();
    return 1;
}


#
# Entry point to create the actual frontpanel window
#

sub do_fp_work {
    # Make a new window for this step

    $fp_window = $parent_window->Toplevel;
    $fp_window->title("OSCAR Server Prepartation");
    
    my $instructions = 
	$fp_window->Message(-aspect => 500, 
			    -text => "Welcome to the OSCAR Cluster Installer.  Before we get started we need to ask you a couple of questions.\n");

    my $mpitext = 
	$fp_window->Message(-aspect => 400, 
			    -text => "Which MPI Implementation do you wish to use by default? If you don't know, the default value should be appropriate.");

    $lambutton = $fp_window->Radiobutton(-text => $lam_text, 
					 -value => $lam_value,
					 -variable => \$mpivalue, 
					 -command => \&set_mpi);
    $mpichbutton = $fp_window->Radiobutton(-text => $mpich_text, 
					   -value => $mpich_value,
					   -variable => \$mpivalue, 
					   -command => \&set_mpi);

    $exitbutton = 
	$fp_window->Button(-text => "Close",
			   -command => \&fp_window_close);
    $setupbutton = 
	$fp_window->Button(-text => "Prepare Server for OSCAR",
			   -command => [\&server_prep]);

    $instructions->grid("-",-sticky => "ew");
    $mpitext->grid("-");
    $lambutton->grid($mpichbutton);
    $setupbutton->grid("-",-sticky => "ew");
    $exitbutton->grid("-",-sticky => "ew");

    # Set LAM as the default

    $mpivalue = $lam_value;
}


#
# Entry point for when one of the MPI buttons is set.  Really only for
# the purposes of printing out.
#

sub set_mpi {
    my ($button) = @_;
    oscar_log_subsection("Step 1: MPI selected: $mpivalue\n");
}


#
# Do the actual work of step 1.
#

sub server_prep {
    # Make this window busy so that the user can't click on anything
    # while this step is running.

    $fp_window->Busy(-recurse => 1);

    my $cmd = "./server_prep $$vars{interface}";
    oscar_log_subsection("Step 1: Running: $cmd");
    open(OUTPUT,"$cmd |") or (carp("Couldn't run command $cmd"), 
                              error_window($fp_window,
					   "Couldn't run command $cmd",
					   sub { $fp_window->Unbusy() }),
			      return undef);

    while(<OUTPUT>) {
        print $_;
        $fp_window->update();
    }

    close(OUTPUT) or (carp("Couldn't run command $cmd"), 
                      error_window($fp_window,
				   "Couldn't run command $cmd",
				   sub { $fp_window->Unbusy() }),
		      return undef);

    oscar_log_subsection("Step 1: Successfully ran command");

    $cmd = "bash -c 'switcher mpi --add-attr default $mpivalue --force --system'";
    oscar_log_subsection("Step 1: Running: $cmd");
    !system("$cmd") or
        (carp("Couldn't run command $cmd"),
         error_window($fp_window, "Couldn't run command $cmd", 
		      sub { $fp_window->Unbusy() }),
	 return undef);

    oscar_log_subsection("Step 1: Successfully ran command");
    oscar_log_subsection("Step 1: Completed successfully");

    done_window($fp_window,
		"Successfully prepared server for OSCAR installation",
		\&fp_window_close);

    # Mark it so that we know that we have already run this step

    $have_run_successfully = 1;

    return 1;
}


#
# When we close the frontpanel window, do some cleanup
#

sub fp_window_close {

    # Destroy this step's window, and make the top-level OSCAR wizard
    # window unbusy.

    $fp_window->destroy();
    $parent_window->Unbusy();
}


1;

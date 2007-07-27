package OSCAR::AddNode;

# Copyright (c) 2003, The Board of Trustees of the University of Illinois.
#                     All rights reserved.

#   $Id$

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
#
#   Copyright (c) 2002 The Trustees of Indiana University.  
#                      All rights reserved.
# 

use strict;
use vars qw($VERSION @EXPORT);
use Tk;
use Carp;
use POSIX;
use SystemInstaller::Tk::Common;
use base qw(Exporter);
use SIS::Image;
@EXPORT = qw(addnode_window);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

our $pid;

sub addnode_window {
    my ($parent, $interface) = @_;
    my $step_number = 1;

    my $window = $parent->Toplevel;
    $window->withdraw;
    $window->title("Add OSCAR Clients");
    my $inst = $window->Label(-text => "Perform the following steps to add nodes to your OSCAR cluster",-relief=>"groove");
    $inst->grid("-","-",-sticky=>"nsew");
    &main::oscar_button($window, "Step $step_number:", "Define OSCAR Clients...", 
			[\&main::build_oscar_clients, $window, $step_number,

			 $interface], 'addclients');
    $step_number++;
    &main::oscar_button($window, "Step $step_number:", "Setup Networking...",
			[\&main::mac_window, $window, $step_number,
			 {interface => $interface}], 'netboot');

    # Monitor Cluster Deployment
    our $monitor_button = &main::oscar_button($window, "", "Monitor Cluster Deployment",
             [\&monitor_deployment, $window], 'monitor_deployment');

    my $boot=$window->Label (-text=>"Before continuing, network boot all of your nodes. 
    Once they have completed installation, reboot them from 
    the hard drive. Once all the machines and their ethernet
    adaptors are up, move on to the next step.",-relief=>"groove");
    $boot->grid("-","-",-sticky=>"nsew");

    $step_number++;
    &main::oscar_button($window, "Step $step_number:",
			"Complete Cluster Setup",
			[\&main::run_post_install, $window, $step_number],
			'post_install');

    my $exitbutton = $window->Button(
                                     -text => "Close",
                                     -command => sub {kill "HUP" => $pid if $pid; $window->destroy},
                                    );

    $exitbutton->grid("-","-",-sticky => "ew");
    OSCAR::Tk::center_window( $window );

}

# Pop up si_monitortk from SystemImager
sub monitor_deployment {
    my ($window) = @_;
    our $pid;
    our $monitor_button;

    my $cmd = "/usr/sbin/si_monitortk --progress";
    $monitor_button->configure(-state => 'disabled');

    my $pipe = new FileHandle;
    $pid = $pipe->open("$cmd |") or die "Cannot fork: $!";

    $window->fileevent($pipe, 'readable', [\&stop_monitor_deployment, $window, $pipe]);
    return 1;
}

# Unfreeze the "Monitor Cluster Deployment" button in "Add OSCAR Clients" widget
sub stop_monitor_deployment {
    my ($window, $pipe) = @_;
    our $pid;
    our $monitor_button;

    waitpid($pid, WNOHANG);

    $monitor_button->configure(-state => 'normal') if Tk::Exists($monitor_button);
    $window->fileevent($pipe, 'readable', "");
}

1;

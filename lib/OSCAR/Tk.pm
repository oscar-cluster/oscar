package OSCAR::Tk;

# Copyright (c) 2003, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
#   $Id: Tk.pm,v 1.6 2003/06/27 15:16:53 brechin Exp $

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
use vars qw($VERSION @EXPORT);
use Tk;
use Carp;
use base qw(Exporter);
use OSCAR::Logger;
use OSCAR::Tk;
@EXPORT = qw(yesno_window done_window error_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

# Module-specific variables

my $parent_window;
my $yn_window;
my ($on_yes, $on_no);
#our $destroyed = 0;

sub yesno_window {
    $parent_window = shift;
    my $title = shift;
    my $label = shift;
    $on_yes = shift;
    $on_no = shift;
    my @args = @_;

    # Make the parent window busy
    
#    $parent_window->Busy(recurse => 1);

    # Make the new yes/no window

    $yn_window = $parent_window->Toplevel;
#    $yn_window->bind('<Destroy>', sub { 
#      if ( $destroyed == 0 ) {
#	$destroyed = 1;
#	$parent_window->Unbusy(); return; 
#      }
#				      } );

    # Fill in the widgets

    if (!$title) {
	$title = "Are you sure?";
    }
    if (!$label) {
	$label = $title;
    }
    $yn_window->title($title);
    my $label_widget = $yn_window->Message(-aspect => 500,
					   -text => $label,
					   -foreground => "blue");
    my $yes_button = $yn_window->Button(-text => "Yes",
					-command => [\&yesno_close, 1, @args]);
    my $no_button = $yn_window->Button(-text => "No",
				       -command => [\&yesno_close, 0, @args]);

    $label_widget->grid("-", -sticky => "ew");
    $yes_button->grid($no_button);
}


sub yesno_close {
    my $value = shift;
    my @args = @_;

    $yn_window->destroy;
    $parent_window->Unbusy();

    if ($value == 0 && ref($on_no) eq "CODE") {
	&$on_no(@args);
    } elsif ($value == 1 && ref($on_yes) eq "CODE") {
	&$on_yes(@args);
    }

    1;
}

#
# These two subs stolen from SystemImager/Tk/Common.pm because we need
# the ordering of close_after to be different -- destroy the "done"
# window, and *then* invoke the callbacks.
#

sub done_window {
    my ($window, $message, $onclose, @args) = @_;
    my $done = $window->Toplevel();
    $done->title("Done!");

    my $label = $done->Message(-text => $message, 
                               -foreground => "blue");
    $label->grid();

    my $button = $done->Button(-text=>"Close",
                               -command=> [\&window_close, $done,
					   $onclose, @args],
                               -pady => 8,
                               -padx => 8);
    $button->grid();

    1;
}


sub window_close {
    my ($window, $onclose, @args) = @_;
    $window->destroy;

    if(ref($onclose) eq "CODE") {
        &$onclose(@args);
    }

    1;
}


sub error_window {
    my ($window, $message, $onclose, @args) = @_;
    my $done = $window->Toplevel();
    $done->title("ERROR!");
    my $label = $done->Message(-text => $message, 
                               -foreground => "red",
                              );
    $label->grid();
    my $button = $done->Button(
                               -text=>"Close",
                               -command=> [\&window_close, $done, 
					   $onclose, @args],
                               -pady => 8,
                               -padx => 8,
                              );
    $button->grid();
}

1;

package OSCAR::FrontPanel.pm;

#   $Id: FrontPanel.pm,v 1.1 2002/02/18 23:09:21 sdague Exp $

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
use Net::Netmask;
use vars qw($VERSION @EXPORT);
use Tk;
use Tk::Tree;
use Carp;
use SystemInstaller::Tk::Common;
use File::Copy;
use base qw(Exporter);
@EXPORT = qw(mac_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

my %MAC = (); # mac will be -1 for unknown, machine name for known
my $COLLECT = 0;
my $PINGPID = undef;

sub frontpanel_window {
    my ($parent, $vars) = @_;

    my $window = $parent->Toplevel;
    $window->title("OSCAR Server Prepartation");
    
    my $instructions = $window->Message(-text => "We need to ask you some questions about you preferences for the cluster.");
    my $setupbutton = $window->Button(
                                      -text => "Prepare Server for OSCAR",
                                      -command => [\&server_prep, $vars, $window],
                                     );
    my $exitbutton = $frame->Button(
                                     -text => "Close",
                                     -command => sub {$window->destroy},
                                    );
    $instructions->grid()
    $setupbutton->grid(-sticky => "ew");
    $exitbutton->grid(-sticky => "ew");
}

sub server_prep {
    my $vars = shift;
    my $window = shift;
    $window->Busy(-recurse => 1);
    my $cmd = "./server_prep $$vars{interface}";
    open(OUTPUT,"$cmd |") or (carp("Couldn't run command $cmd"), 
                              error_window($window,"Couldn't run command $cmd"),
                              $window->Unbusy(), return undef);

    while(<OUTPUT>) {
        print $_;
        $window->update();
    }

    close(OUTPUT) or (carp("Couldn't run command $cmd"), 
                      error_window($window,"Couldn't run command $cmd"),
                      $window->Unbusy(), return undef);

    
    done_window($window,"Successfully prepared server for OSCAR installation"),
    $window->Unbusy();
    return 1;
}

1;

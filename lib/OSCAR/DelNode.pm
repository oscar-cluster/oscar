package OSCAR::DelNode;

#   $Id: DelNode.pm,v 1.4 2002/05/21 20:37:39 mchasal Exp $

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
use SystemInstaller::Tk::Common;
use base qw(Exporter);
use SIS::Client;
@EXPORT = qw(delnode_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

sub delnode_window {
    my ($parent, $vars) = @_;

    my $window = $parent->Toplevel;
    $window->title("Delete Oscar Nodes");
    my $inst=$window->Label (-text=>"In order to delete OSCAR clients from your cluster, select the nodes you wish to delete and press the Delete Clients button.");

    my $listbox = $window->ScrlListbox(
                                       -selectmode => 'multiple',
                                       -background => "white",
                                      );

    $listbox->grid("-");
    fill_listbox($listbox);

    
    my $deletebutton = $window->Button(
                                      -text => "Delete clients",
                                      -command => [\&delnodes, $window, $listbox],
                                     );
    my $exitbutton = $window->Button(
                                     -text => "Close",
                                     -command => sub {$window->destroy},
                                    );

    $deletebutton->grid($exitbutton,-sticky => "ew");
}

sub fill_listbox {
        my $listbox=shift;
        my @elements;
        my @clients = clientList();
        foreach my $client (@clients) {
                push (@elements,$client->{NAME});
        }
        $listbox->delete(0,'end');
        $listbox->insert(0,@elements);
        $listbox->update;
        return 1;
}

sub delnodes {
        my $window=shift;
        my $listbox=shift;
        my @clients;
        my @elements=$listbox->curselection;
        foreach my $index (@elements) {
                push @clients,$listbox->get($index);
        }
        my $clientstring=join(",",@clients);
        if (system("mksimachine --Delete --name $clientstring")) {
                carp("Failed to delete machines $clientstring");
                fill_listbox($listbox);
                error_window($window,"Failed to delete requested clients.");
                return 0;
        } else {
                my $fail=0;
                print "Executing post_clients phase\n";
                if (system("./post_clients")) {
                        carp("post_clients phase failed.");
                        $fail++;
                }
                print "Executing post_install phase\n";
                if (system("./post_install")) {
                        carp("post_install phase failed.");
                        $fail++;
                }
                fill_listbox($listbox);
                if ($fail) {
                        error_window($window,"Clients deleted, but reconfiguration failed.");
                        return 0;
                } else {
                        done_window($window,"Clients deleted.");
                        return 1;
                }
        }

}





1;

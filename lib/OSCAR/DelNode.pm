
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
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2006 Erich Focht <efocht@hpce.nec.com>
#                    All rights reserved.
# Copyright (c) 2007-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#                         

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use lib "/usr/lib/systeminstaller";
use vars qw($VERSION @EXPORT);
use Tk;
use Carp;
use SystemInstaller::Tk::Common;
use base qw(Exporter);
use SIS::Client;
use SIS::Adapter;
use SIS::NewDB;
use OSCAR::Database;
use OSCAR::Logger;
use OSCAR::Network;
use OSCAR::Package;
use OSCAR::ConfigManager;
use OSCAR::oda;
use OSCAR::Utils;

@EXPORT = qw(delnode_window);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

sub delnode_window {
    my ($parent, $vars) = @_;

    my $window = $parent->Toplevel;
    $window->withdraw;
    $window->title("Delete Oscar Clients");
    my $inst=$window->Label (-text=>"In order to delete OSCAR clients 
from your cluster, select the nodes
you want to delete and press the 
\"Delete Selected Clients\" button.",-relief=>"groove");
    $inst->grid("-",-sticky=>"nsew");

    my $listbox = $window->ScrlListbox(
                                       -selectmode => 'multiple',
                                       -background => "white",
                                      );

    $listbox->grid("-",-sticky=>"nsew");
    fill_listbox($listbox);

    my $selectallbutton = $window->Button(
                                      -text => "Select All Clients",
                                      -command => [\&selectallnodes, $window, $listbox],
                                      -state => "active",
                                     );

    my $deletebutton = $window->Button(
                                      -text => "Delete Selected Clients",
                                      -command => [\&delnodes, $window, $listbox],
                                      -state => "disabled",
                                     );
    my $exitbutton = $window->Button(
                                     -text => "Close",
                                     -command => sub {$window->destroy},
                                    );

    $selectallbutton->grid("-","-",-sticky=>"nsew",-ipady=>"4");
    $deletebutton->grid($exitbutton,-sticky => "ew");

    $listbox->bind( "<ButtonRelease>",
            [ sub { my ($lb,$b) = @_;
                    $b->configure( -state => ( defined $lb->curselection ) ? "normal" : "disabled" );
                  }, $deletebutton
            ]
        );
    $selectallbutton->bind( "<ButtonRelease>",
            [ sub { my ($lb,$b) = @_;
                    $b->configure( -state => "active" );
                  }, $deletebutton
            ]
        );

    OSCAR::Tk::center_window( $window );
}
 
# Use Schwartzian transform to sort clients by node names alphabetically and numerically.
# Names w/o numeric suffix precede those with numeric suffix.
sub sortclients(@) {
	return map { $_->[0] }
	       sort { $a->[1] cmp $b->[1] || ($a->[2]||-1) <=> ($b->[2]||-1) }
	       map { [$_, $_->{name} =~ /^([\D]+)([\d]*)$/] }
	       @_;
}

sub fill_listbox {
        my $listbox=shift;
        my @elements;
        my @clients = sortclients SIS::NewDB::list_client();
        foreach my $client (@clients) {
                push (@elements,$client->{name});
        }
        $listbox->delete(0,'end');
        $listbox->insert(0,@elements);
        $listbox->update;
        return 1;
}





# Return: 1 if success, 0 else.
sub delnodes {
    my $window=shift;
    my $listbox=shift;
    my @clients;
    my @elements=$listbox->curselection;
    foreach my $index (@elements) {
            push @clients,$listbox->get($index);
    }

    require OSCAR::NodeMgt;
    my $fail = OSCAR::NodeMgt::delete_clients (@clients);
        
    fill_listbox($listbox);
    if ($fail) {
      OSCAR::Tk::error_window($window,"Clients deleted, but reconfiguration ".
                              "failed.");
      return 0;
    } else {
        &delete_client_node_opkgs(@clients);
        OSCAR::Tk::done_window($window,"Clients deleted.");
    }

    # Update the /etc/hosts file
    my @data = ();
    if (OSCAR::FileUtils::find_block_from_file ("/etc/hosts", 
                                                "OSCAR hosts",
                                                \@data)) {
        carp "ERROR: Impossible to extract OSCAR block from /etc/hosts";
        return 0;
    }
    for (my $i = 0; $i < scalar (@data); $i++) {
        foreach my $c (@clients) {
            if (defined $c && defined $data[$i]) {
                if ($data[$i] =~ m/$c/) {
                    delete $data[$i];
                }
            }
        }
    }
    if (OSCAR::FileUtils::replace_block_in_file ("/etc/hosts",
                                                 "OSCAR hosts",
                                                 \@data)) {
        carp "ERROR: Impossible to replace OSCAR hosts block in /etc/hosts";
        return 0;
    }
    
    return 1;
}

sub selectallnodes {
    my $window = shift;
    my $listbox = shift;

    my $size = $listbox->size;
    $listbox->selectionSet(0, $size);
    
    return 1;
}

#
# NEST
#
# This script deletes the client node records from Group_Nodes
# Nodes, Node_Packages, and Node_Package_Status tables with a
# node name.
#
# delete_node is a subroutine to delete the record about client
# nodes.
#

sub delete_client_node_opkgs {
    my @nodes = @_;
    foreach my $node (@nodes){
       if (!OSCAR::Database::delete_node($node, undef, undef)) {
          carp("Failed to delete the records for node_config_revs and config_opkgs");
       }
    }
}

1;

__END__

=head1 DESCRIPTION

This Perl module is used by the GUI. The backend code for client deletion is in the OSCAR::NodeMgt Perl module.

=head1 EXPORTED FUNCTIONS

=over 4

=item delnode_window

=back

=cut

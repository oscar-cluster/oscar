package OSCAR::DelNode;

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

use strict;
use vars qw($VERSION @EXPORT);
use lib "$ENV{OSCAR_HOME}/lib";
use Tk;
use Carp;
use SystemInstaller::Tk::Common;
use base qw(Exporter);
use SIS::Client;
use SIS::DB;
use OSCAR::Database;
use OSCAR::Package;
use OSCAR::oda;


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

    
    my $deletebutton = $window->Button(
                                      -text => "Delete Selected Clients",
                                      -command => [\&delnodes, $window, $listbox],
                                      -state => "disabled",
                                     );
    my $exitbutton = $window->Button(
                                     -text => "Close",
                                     -command => sub {$window->destroy},
                                    );

    $deletebutton->grid($exitbutton,-sticky => "ew");

    $listbox->bind( "<ButtonRelease>",
            [ sub { my ($lb,$b) = @_;
                    $b->configure( -state => ( defined $lb->curselection ) ? "normal" : "disabled" );
                  }, $deletebutton
            ]
        );

    center_window( $window );
}
 
# Use Schwartzian transform to sort clients by node names alphabetically and numerically.
# Names w/o numeric suffix precede those with numeric suffix.
sub sortclients(@) {
	return map { $_->[0] }
	       sort { $a->[1] cmp $b->[1] || ($a->[2]||-1) <=> ($b->[2]||-1) }
	       map { [$_, $_->name =~ /^([\D]+)([\d]*)$/] }
	       @_;
}

sub fill_listbox {
        my $listbox=shift;
        my @elements;
        my @clients = sortclients list_client();
        foreach my $client (@clients) {
                push (@elements,$client->name);
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
    my $fail=0;

    my @generic_services=();
    my @server_services=();
    my $print_error=1;

    # get the list of generic services
    get_packages_servicelists(\@generic_services,"");
    
    # get the list of services for servers
    get_packages_servicelists(\@server_services,"oscar_server");
    
    print ">> Turning off generic services\n";
    foreach my $services_ref (@generic_services) {
        my $generic_service = $$services_ref{service};
        if (system("/etc/init.d/$generic_service stop")) {
            carp("generic_services phase failed.");
            $fail++;
        }
        foreach my $client (@clients) {
            print "[$client]\n";
            if (system("/usr/bin/ssh $client /etc/init.d/$generic_service stop")) {
                carp("client_services phase failed.");
                $fail++;
            }
        }
    }

    if (system("mksimachine --Delete --name $clientstring")) {
      carp("Failed to delete machines $clientstring");
      $fail++;
    }

    print ">> Executing post_clients phase\n";
    if (system("./post_clients")) {
      carp("post_clients phase failed.");
      $fail++;
    }
    print ">> Executing post_install phase\n";
    if (system("./post_install")) {
      carp("post_install phase failed.");
      $fail++;
    }

    print ">> Re-starting generic services\n";
    foreach my $services_ref (@generic_services) {
        my $generic_service = $$services_ref{service};
        if (system("/etc/init.d/$generic_service restart")) {
            carp("server_services generic phase failed.");
            $fail++;
        }
    }
    print ">> Re-starting server services\n";
    foreach my $services_ref (@server_services) {
        my $server_service = $$services_ref{service};
        if (system("/etc/init.d/$server_service restart")) {
            carp("server_services server phase failed.");
            $fail++;
        }
    }
    
    print ">> Updating C3 configuration file\n";
    if (system("$ENV{OSCAR_HOME}/packages/c3/scripts/post_clients")) {
        carp("C3 configuration file update phase failed.");
        $fail++;
    }
                                                                            
    print ">> Re-starting client services on remaining nodes\n";
    foreach my $services_ref (@generic_services) {
        my $generic_service = $$services_ref{service};
        if (system("/opt/c3-4/cexec /etc/init.d/$generic_service restart")) {
                carp("client_services restart phase failed.");
                $fail++;
        }
    }

    fill_listbox($listbox);
    if ($fail) {
      error_window($window,"Clients deleted, but reconfiguration failed.");
      return 0;
    } else {
        &delete_client_node_opkgs(@clients);
        done_window($window,"Clients deleted.");
        return 1;
    }
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
       if (!delete_node($node)) {
          carp("Failed to delete the records for node_config_revs and config_opkgs");
       }
    }
}

1;

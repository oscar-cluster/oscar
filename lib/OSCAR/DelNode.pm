package OSCAR::DelNode;

#   $Id: DelNode.pm,v 1.7 2003/12/04 20:38:15 brechin Exp $

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
use lib "$ENV{OSCAR_HOME}/lib/OSCAR";
use Tk;
use Carp;
use SystemInstaller::Tk::Common;
use base qw(Exporter);
use SIS::Client;
use SIS::DB;
use OSCAR::Database;
use OSCAR::Package;
@EXPORT = qw(delnode_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

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

# Use Schwartzian transform to sort node names alphabetically and numerically.
# Names w/o numeric suffix preceed those with numeric suffix.
sub sortnodes(@) {
	return map { $_->[0] }
	       sort { $a->[1] cmp $b->[1] || ($a->[2]||-1) <=> ($b->[2]||-1) }
	       map { [$_, /^([\D]+)([\d]*)$/] }
	       @_;
}

sub fill_listbox {
        my $listbox=shift;
        my @elements;
        my @clients = sortnodes( list_client() );
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

        # get the list of services for clients
        database_execute_command("list_services NULL", \@generic_services, $print_error);

        # get the list of services for servers
        database_execute_command("list_services oscar_server", \@server_services, $print_error);

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

        print ">> Turning off client services\n";
        foreach my $client (@clients) {
                foreach my $generic_service (@generic_services) {
			print "[$client]\n";
                        if (system("/usr/bin/ssh $client /etc/init.d/$generic_service stop")) {
                                carp("client_services phase failed.");
                                $fail++;
                        }
                }
        }

        print ">> Re-starting server services\n";
	foreach my $generic_service (@generic_services) {
        	if (system("/etc/init.d/$generic_service restart")) {
                	carp("server_services generic phase failed.");
                        $fail++;
                }
        }
        foreach my $server_service (@server_services) {
                if (system("/etc/init.d/$server_service restart")) {
			carp("server_services server phase failed.");
			$fail++;
		}
        }
        
        if (system("mksimachine --Delete --name $clientstring")) {
          carp("Failed to delete machines $clientstring");
          $fail++;
	}

        # Modifier : DongInn Kim (dikim@osl.iu.edu)
        # It is added to update the oda database corresponding to the 
        # the sis database.
        # post_clients in sis package runs the delete_node, an oda shortcut,
        # to update all related tables.
        if(!run_pkg_script("sis","post_clients",1)) {
                    carp("Couldn't run post_clients script for SIS");
        }

        print ">> Updating C3 configuration file\n";
        if (system("$ENV{OSCAR_HOME}/packages/c3/scripts/post_clients")) {
                carp("C3 configuration file update phase failed.");
                $fail++;
        }
                                                                                
        print ">> Re-starting client services on remaining nodes\n";
        foreach my $generic_service (@generic_services) {
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
	  &delete_client_config_opkgs(@clients);
          done_window($window,"Clients deleted.");
          return 1;
        }
  

}

#
# NEST
#
# This script deletes the records from node_config_revs and config_opkgs
# tables with a node name.
#
# del_node_config_opkgs is a shortcut to delete the record about node_config_revs
# and config_opkgs.
#

sub delete_client_config_opkgs {
    my @nodes = @_;
    foreach my $node (@nodes){
       if (system("oda del_node_config_opkgs $node")) {
          carp("Failed to delete the records for node_config_revs and config_opkgs");
       }
    }
}

1;

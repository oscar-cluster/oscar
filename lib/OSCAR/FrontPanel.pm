package OSCAR::FrontPanel;

#   $Id: FrontPanel.pm,v 1.7 2002/05/09 22:15:42 mchasal Exp $

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
@EXPORT = qw(frontpanel_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

my %MAC = (); # mac will be -1 for unknown, machine name for known
my $COLLECT = 0;
my $PINGPID = undef;

my ($lambutton, $mpichbutton, $mpivalue);

sub frontpanel_window {
    my ($parent, $vars) = @_;

    my $window = $parent->Toplevel;
    $window->title("OSCAR Server Prepartation");
    
    my $instructions = $window->Message(-aspect => 500, -text => "Welcome to the OSCAR Cluster Installer.  Before we get started we need to ask you a couple of questions.\n");

    my $mpitext = $window->Message(-aspect => 400, -text => "Which MPI Implementation do you wish to use by default? If you don't know, the default value should be appropriate.");

    $lambutton = $window->Radiobutton(-text => "LAM/MPI 6.5.6", -value => "lam-6.5.6",
                                      -variable => \$mpivalue, -command => \&set_mpi);
    $mpichbutton = $window->Radiobutton(-text => "MPICH 1.2.1", -value => "mpich-1.2.1",
                                      -variable => \$mpivalue, -command => \&set_mpi);

    my $setupbutton = $window->Button(
                                      -text => "Prepare Server for OSCAR",
                                      -command => [\&server_prep, $vars, $window],
                                     );
    my $exitbutton = $window->Button(
                                     -text => "Close",
                                     -command => sub {$window->destroy},
                                    );

    $instructions->grid("-",-sticky => "ew");
    $mpitext->grid("-");
    $lambutton->grid($mpichbutton);
    $setupbutton->grid("-",-sticky => "ew");
    $exitbutton->grid("-",-sticky => "ew");
    # set lam as the default
    $mpivalue = "lam-6.5.6";
}

sub set_mpi {
    my ($button) = @_;
    print $mpivalue,"\n";
    
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

    !system("bash -c 'switcher mpi --add-attr default $mpivalue --force --system'") or
        (carp("Couldn't run command $cmd"),
         error_window($window,"Couldn't run command $cmd"),
         $window->Unbusy(), return undef);

    done_window($window,"Successfully prepared server for OSCAR installation"),
    $window->Unbusy();
    return 1;
}

1;

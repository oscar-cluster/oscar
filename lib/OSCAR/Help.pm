package OSCAR::Help;

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

use strict;
use vars qw(%Help $VERSION @EXPORT);
use base qw(Exporter);
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Tk;

@EXPORT = qw(open_help);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# Help messages for the OSCAR GUI.

sub open_help {
    my ($window, $section) = @_;
    my $helpwin = $window->Toplevel();
    $helpwin->withdraw;
    $helpwin->title("Help");
    my $helpp = $helpwin->Scrolled("ROText",-scrollbars=>"e",-wrap=>"word",
                                 -width=>40,-height=>15);
    $helpp->grid(-sticky=>"nsew");
    my $cl_b = $helpwin->Button(-text=>"Close",
                                -command=> sub {$helpwin->destroy},-pady=>"8");
    $helpwin->bind("<Escape>",sub {$cl_b->invoke()});
    $cl_b->grid(-sticky=>"nsew",-ipady=>"4");
    $helpp->delete("1.0","end");
    $helpp->insert("end",$Help{$section});

    OSCAR::Tk::center_window( $helpwin );
}

%Help = (
         install_server => "This button installs several OSCAR packages on your server and configures them for use as the server OSCAR node.",
         build_image => "This button allows you define and build your OSCAR client image.  The defaults should work for most situations.",
         addclients => "This button lets you define the client nodes to be installed with OSCAR.",
         netboot => "This button enables you to assign specific client nodes (identified via their MAC addresses) to hostnames for installation.",
         post_install => "This button runs a series of post installation scripts that complete your OSCAR installation.",
         test_install => "This button runs test scripts that test your OSCAR installation for basic functionality.",
         add_nodes => "This button enables you to add new client nodes to your RUNNING OSCAR cluster.",
         delete_nodes => "This button deletes client nodes from your RUNNING OSCAR cluster.",
         select_packages => "This button lets you select the packages you want installed on your OSCAR client nodes.",
         configure_packages => "This button allows you to configure packages that you have selected for installation on your OSCAR client nodes.  If a package does not have any configuration options, it will not appear in the list.",
         download_packages => "This button allows you to download packages not included in the main tarball or updated packages from well-known or user-specified OSCAR repositories.  This step is optional.",
         install_uninstall_packages => "This button lets you update your cluster by selecting the OSCAR packages you want to install/uninstall from your current system.",
         monitor_deployment => "This button runs a daemon which monitors the progress of compute node installations in real-time.",
         netbootmgr => "This button runs the Network Boot Manager which allows you to change the boot action for compute nodes managed by OSCAR.  Supported actions are \"Install\", \"Localboot\", \"Memtest\", etc.",
         ganglia => "This button brings up the Ganglia status page via a web browser.",
        );
1;


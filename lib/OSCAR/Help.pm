package OSCAR::Help;

#   $Id: Help.pm,v 1.8 2003/06/27 21:50:59 brechin Exp $

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

@EXPORT = qw(open_help);

$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

# Help messages for the OSCAR GUI.

sub open_help {
    my ($window, $section) = @_;
    my $helpwin = $window->Toplevel();
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
}

%Help = (
         install_server => "This button will install several OSCAR packages on your server, and configure them for use as the server OSCAR node.",
         build_image => "This button will launch a panel which will let you define and build your OSCAR client image.  The defaults specified should work for most situations.",
         addclients => "This button will launch a panel which lets you define what clients are going to be installed with OSCAR.",
         netboot => "This button will launch the MAC Address Collection Tool which will enable you to assign specific MAC addresses to clients for installation.  Please follow the instructions on the MAC Address Collection Panel",
         post_install => "Pressing this button will run a series of post installation scripts which will complete your OSCAR installation.",
         test_install => "Pressing this button will set up the test scripts so that you can test to see if your OSCAR installation is working.",
         add_nodes => "Use this button to perform the steps required to add new clients to your running OSCAR cluster.",
         delete_nodes => "Use this button to perform the steps required to delete clients from your running OSCAR cluster.",
         select_packages => "This button will launch a panel which lets you select the packages you want included in your OSCAR client image.  Be sure to click the 'Save and Exit' button if you have made any changes.",
         configure_packages => "This button will launch a panel that will allow you to configure any packages that you have selected for installation in your OSCAR client image.  If a package selected for installation does not have any configuration options, then it will not appear in the list.",
	download_packages => "This button will open up a GUI interface to OPD, the OSCAR Package Downloader.  It will allow you to download packages not included in the main tarball or updated packages.  This step is optional.",
        );
1;

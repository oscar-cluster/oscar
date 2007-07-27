package OSCAR::GUI_MAC;

# Copyright (c) 2004    The Board of Trustees of the University of Illinois.
#                       All rights reserved.
#           Jason Brechin <brechin@ncsa.uiuc.edu>
# Copyright (C) 2006,2007 Bernard Li <bernard@vanhpc.org>
#                    All rights reserved.
# Copyright (C) 2006    Oak Ridge National Laboratory
#                       Geoffroy Vallee <valleegr@ornl.gov>
#
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

# Description: this is the GUI code for network stuff, especially stuff
# related to MAC addresses. The library code is in lib/OSCAR/MAC.pm

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use lib "/usr/lib/systeminstaller";
use Tk;
use Tk::Tree;
use SystemImager::Client;
use File::Copy;
use SIS::Adapter;
use SIS::Client;
use SIS::DB;
use SIS::Image;
use OSCAR::Tk;
use OSCAR::MAC qw(save_to_file
                  load_from_file
                  start_mac_collect
                  stop_mac_collect
                  sortclients
                  populate_MACS
                  start_ping
                  end_ping
                  set_servermacs
                  add_mac_to_hash
                  run_cmd
                  generate_uyok
                  __setup_dhcpd
                  __end_collect_mac
                  __load_macs
                  __build_autoinstall_cd
                  __enable_install_mode
                  __run_setup_pxe
                  %MAC 
                  $COLLECT 
                  @SERVERMACS
                  @install_mode_options
                  $step_number
                  $startcoll 
                  $stopcoll 
                  $install_mode
                  );

use Carp;
use OSCAR::Logger;
use OSCAR::Database;
use OSCAR::Network;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw (  mac_window
             );

our $window;
our $destroyed = 0;

#REMOVE MAC_WINDOW FROM EXPORT WHEN NO LONGER NEEDED

$VERSION = sprintf("r%d", q$Revision: 5621 $ =~ /(\d+)/);

sub mac_window {
    $destroyed = 1;
    my $parent = shift;
    $step_number = shift;
    our ($vars) = @_;

    my ($ip, $broadcast, $netmask) = interface2ip($$vars{interface});

    $parent->Busy(-recurse => 1);
    # init this only once, as we don't add network cards during this process
    @SERVERMACS = set_servermacs();

    our $window = $parent->Toplevel;
    $window->withdraw;
    $window->title("Setup Networking");

    if ($0 =~ /manage/) {
        oscar_log_section("OSCAR Management Wizard: Setup networking");
    } else {
        oscar_log_section("Running step $step_number of the OSCAR wizard:".
	"Setup networking");
    }

    my $instructions = $window->Message(-text => "MAC Address collection. ".
        "When a new MAC address is received on the network, it will appear in".
	" the left column.  To assign that MAC address to a machine highlight".
	" the address and the machine and click \"Assign MAC to Node\".",
	-aspect => 800);

    our $starttext = $startcoll;
    our $label = $window->Label(-text => "Not Listening to Network. Click".
    " \"$starttext\" to start.", -relief => 'sunken');


    my $frame = $window->Frame();
    my $topframe = $window->Frame();

    our $listbox = $topframe->ScrlListbox(
                                       -selectmode => 'single',
                                       -background => "white",
                                       -scrollbars => 'osoe',
                                      );

    # the "All Clients" widget
    our $tree = $topframe->Scrolled("Tree",
                                 -background => "white",
                                 -itemtype => 'imagetext',
                                 -separator => '|',
                                 -selectmode => 'single',
                                 -scrollbars => 'osoe',
                                 -width => 40,
                                );

    $listbox->bind( "<ButtonRelease>", \&set_buttons );
    $tree->bind( "<ButtonRelease>", \&set_buttons );

    $instructions->pack($label, -fill => 'x');

    our $clear    = $topframe->Button( -text => "Remove",
                    -height=>1,
                    -command => \&clearmacaddy,
                    -state => "disabled",
                    );
    our $clearall = $topframe->Button( -text => "Remove All",
                    -height=>1,
                    -command => \&clearallmacs,
                    -state => "disabled",
                    );
    $frame->pack(-side => "bottom", -fill => "both", -expand => 1);
    $topframe->pack(-side => 'top', -fill => "both", -expand => 1);

    $listbox->grid('-', $tree, -sticky => 'nsew');
    $clear->grid($clearall, '^', -sticky => 'nsew');
    $topframe->gridColumnconfigure(0, -weight => 1);
    $topframe->gridColumnconfigure(1, -weight => 1);
    $topframe->gridColumnconfigure(2, -weight => 2);

    our $start = $frame->Button(
                                   -textvariable => \$starttext,
                                   -command => [\&begin_collect_mac, 
				                $$vars{interface} ],
                                   );
    our $exitbutton = $frame->Button(
                                     -text => "Close",
                                     -borderwidth => "6",
                                     -relief => "groove",
                                     -command => sub {
                                         undef $destroyed;
                                         end_ping();
                                         end_collect_mac($label);
                                         oscar_log_subsection(
					   "Step $step_number: ".
					   "Completed successfully");
                                         $parent->Unbusy();
                                         $window->destroy;
                                     },
                                    );
    our $assignbutton = $frame->Button(
                                      -text => "Assign MAC to Node",
                                      -command => [\&assign2machine, 
				                   undef, 
						   undef],
                                      -state => "disabled",
                                     );
    our $deletebutton = $frame->Button(
                                      -text => "Delete MAC from Node",
                                      -command => \&clear_mac,
                                      -state => "disabled",
                                     );
    our $dhcpbutton = $frame->Button(
                                    -text => "Configure DHCP Server",
                                    -command => [\&setup_dhcpd, 
				                 $$vars{interface}],
                                    -state => "disabled",
                                   );

    our $dyndhcp = 1;
    my $refreshdhcp = $frame->Checkbutton(
                                -text => "Dynamic DHCP update",
                                -variable => \$dyndhcp,
                                );

    our $install_mode;

    # Retrive the installation mode from ODA
    my $orig_install_mode = get_install_mode();

    $install_mode = $orig_install_mode;

    my $install_button = $frame->Optionmenu(
                    -options => [ @install_mode_options ],
                    -variable => \$install_mode
                    );

    our $enable_install_button = $frame->Button(
                                     -text => "Enable Install Mode",
                                     -command => [\&enable_install_mode],
                                    );

    our $loadbutton = $frame->Menubutton(
                                   -text => "Import MACs from",
                                   -menuitems => [ [ 'command' => "file...",
                                                     "-command" => [
						       \&macfile_selector, 
						       "load", 
						       $frame] ],
                                                   [ 'command' => 
						       "user input...",
                                                     "-command" => 
						       \&macs_inputer ],
                                                 ],
                                   -tearoff => 0,
                                   -direction => "right",
                                   -relief => "raised",
                                   -indicatoron => 1,
                                  );

    our $savebutton = $frame->Button(
                                    -text => "Export MACs to file...",
                                    -command => [\&macfile_selector, 
				                 "save", 
						 $frame],
                                    -state => "disabled",
                                   );

    our $uyok = 0;
    my $uyok_radio = $frame->Checkbutton(
                                -text => "Enable UYOK",
                                -variable => \$uyok,
                                );

    our $bootcd = $frame->Button(
                                    -text => "Build AutoInstall CD...",
                                    -command => [\&build_autoinstall_cd, $ip],
                                   );

    our $networkboot = $frame->Button(
                                     -text => "Setup Network Boot",
                                     -command => [\&run_setup_pxe],
                                    );

    our $assignall   = $frame->Button(
                                     -text => "Assign all MACs",
                                     -command => \&assignallmacs,
                                     -state => "disabled",
                                    );
#    my $clearallmacsfromnodes = $frame->Button(
#                                        -text =>"Remove all MACs",
#                                        -command => \&clearallmacsfromnodes,
#                                        );

# This is what the widget looks like:
# |----------------------------------------------------------------|
# |                        MAC Address Management                  |
# |------------------------------------------- --------------------|
# | Start Collecting MACs | Assign all MACs  | Assign MAC to Node  |
# | ---------------------------------------------------------------|
# | Delete MAC from Node  | Import MACs from | Export MACs to file |
# |----------------------------------------------------------------|
# |                 Installation Mode and DHCP Setup               |
# |----------------------------------------------------------------|
# | <Install Mode>        | Enable Install Mode   |                |
# |------------------------------------------------                |
# | o Dynamic DHCP update | Configure DHCP Server |                |
# |----------------------------------------------------------------|
# |             Boot Environment (CD or PXE-boot) Setup            |
# |----------------------------------------------------------------|
# | o Enable UYOK      | Build AutoInstall CD | Setup Network Boot |
# |----------------------------------------------------------------|
# |                             Close                              |
# |----------------------------------------------------------------|
#
    my $mac_label = $frame->Label(-text => "MAC Address Management", 
                                  -relief => 'sunken');
    $mac_label->grid("-", "-", -sticky => "ew");
    $start->grid($assignall, $assignbutton, -sticky => "ew");
    $deletebutton->grid($loadbutton, $savebutton, -sticky => "ew");
    $loadbutton->grid($savebutton, -sticky => "ew");
    my $install_label = $frame->Label(-text => 
        "Installation Mode and DHCP Setup", -relief => 'sunken');
    $install_label->grid("-", "-", -sticky => "ew");
    $install_button->grid($enable_install_button, -sticky => "ew");
    $refreshdhcp->grid($dhcpbutton, -sticky => "ew");
    my $label2 = $frame->Label(-text => 
        "Boot Environment (CD or PXE-boot) Setup",
	-relief => 'sunken');
    $label2->grid("-","-",-sticky => "ew");
    $uyok_radio->grid($bootcd, $networkboot, -sticky => "ew");
    $exitbutton->grid("-","-",-sticky=>"nsew",-ipady=>"4");
#    $clearallmacsfromnodes->grid( -sticky => 'ew');
    $window->bind('<Destroy>', sub {
                                    if ( defined($destroyed) ) {
                                      undef $destroyed;
                                      $exitbutton->invoke();
                                      return;
                                    }
                                   });
    # this populates the tree as it exists
    populate_MACS();

    regenerate_tree();
    OSCAR::Tk::center_window( $window );
}

sub set_buttons {
    our $listbox;
    our $tree;
    my $state;
    my $lbs;
    my $trs;
#
#   Enabled iff at least one item selected in the listbox.
#
    $lbs = defined $listbox->curselection();
    $state = $lbs ? "normal" : "disabled";
    our $clear->configure( -state => $state );
#
#   Enabled iff at least one item in listbox.
#
    $lbs = defined $listbox->get( 0, 'end' );
    $state = $lbs ? "normal" : "disabled";
    our $clearall->configure( -state => $state );
#
#   Enabled iff at least one item in listbox and one item in tree.
#
    $trs = $tree->infoNext( "|" );
    $state = ($lbs && $trs) ? "normal" : "disabled";
    our $assignall->configure( -state => $state );
#
#   Enabled iff at least one MAC exists.
#
    $state = (scalar keys %MAC) ? "normal" : "disabled";
    our $savebutton->configure( -state => $state );
#
#   Enabled iff at least one item selected in the listbox and the tree.
#
    $trs = defined $tree->infoSelection();
    $state = ($lbs && $trs) ? "normal" : "disabled";
    our $assignbutton->configure( -state => $state );
#
#   Enabled iff at least one item selected in listbox and selected item in tree
#   has a MAC.
#
    my $node = $tree->infoSelection();

    # hack to support both perl-Tk-800 and perl-Tk-804
    $node = $$node[0] if ref($node) eq "ARRAY";

    if( $trs && $node =~ /^\|([^\|]+)/) {
        my $client = list_client(name=>$1);
        my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
        $state = $adapter->mac ? "normal" : "disabled";
    } else {
        $state = "disabled";
    }
    our $deletebutton->configure( -state => $state );
}

sub setup_dhcpd {
    my $interface = shift;
    our $window;

    $window->Busy(-recurse => 1);
    __setup_dhcpd($interface);
    our $dhcpbutton->configure(-state => 'disabled'); 
    $window->Unbusy();
}

sub regenerate_tree {
    our $tree;
    $tree->delete("all");
    $tree->add("|",-text => "All Clients",-itemtype => "text");
    my @clients = sortclients list_client();
    foreach my $client (@clients) {
        my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
        $tree->add("|".$client->name, 
	           -text => $client->hostname, 
		   -itemtype => "text");
        my $mac=$adapter->mac || "" ;
        $tree->add("|".$client->name . "|mac",
                   -text => $adapter->devname . " mac = " . $mac, 
		   -itemtype => "text");
        $tree->add("|".$client->name . "|ip" . $adapter->devname,
                   -text => $adapter->devname . " ip = " . $adapter->ip, 
		   -itemtype => "text");
    }
    $tree->autosetmode;
    set_buttons();
}

sub assign2machine {
    my ($mac, $node, $noupdate) = @_;
    our $listbox;
    our $tree;
    unless ( defined($noupdate) ) { $noupdate = 0; }
    unless ( $mac ) {
      my $sel = $listbox->curselection;
      if ( defined( $sel ) ) {
        $mac = $listbox->get($listbox->curselection) or return undef;
      }
      else { return undef; }
    }

    unless ( $node ) {
      if ( defined( $tree->infoSelection() ) ) {
        $node = $tree->infoSelection() or return undef;
      }
      else { return undef; }
    }

    my $client;
    clear_mac();

    # hack to support both perl-Tk-800 and perl-Tk-804...
    $node = $$node[0] if ref($node) eq "ARRAY";

    if($node =~ /^\|([^\|]+)/) {
        oscar_log_subsection("Step $step_number: Assigned $mac to $1");
        $client = list_client(name=>$1);
    } else {
        return undef;
    }
    my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
    $MAC{$mac}->{client} = $adapter->ip;
    $adapter->mac($mac);
    set_adapter($adapter);
    regenerate_listbox();
    if ( ! $noupdate ) { regenerate_tree(); }
    if ( our $dyndhcp && ! $noupdate ) {
      our $vars;
      setup_dhcpd($$vars{interface});
    }
}

sub assignallmacs {
    our $listbox;
    our $tree;
    our $window;
    $tree->selectionClear();
    $window->Busy(-recurse => 1);
    my @macs = $listbox->get(0, 'end');
    @macs = reverse @macs;
    $listbox->delete(0, 'end');
    regenerate_listbox();
    my $client;
    my $adapter;
    my $tempnode = '|';
    while ( scalar(@macs)) {
      last unless $tempnode = $tree->infoNext($tempnode);
      $tempnode =~ /^\|([^\|]+)/;
      $client = list_client(name=>$1);
      $adapter = list_adapter(client=>$client->name,devname=>"eth0");
      assign2machine(pop @macs, $tempnode, 1) unless $adapter->mac;
    }
    $listbox->insert(0, @macs);
    regenerate_listbox();
    regenerate_tree();
    if ( our $dyndhcp ) {
      our $vars;
      setup_dhcpd($$vars{interface});
    }
    $window->Unbusy();
}

sub clearmacaddy {
    our $listbox;
    our $window;
    my $macindex = '';
    $window->Busy(-recurse => 1);
    if ( defined($listbox->curselection) ) {
      $macindex=$listbox->curselection;
      #$listbox->selectionClear(0, 'end');
      delete $MAC{$listbox->get($macindex)};
      $listbox->delete($macindex);
      $listbox->update();
    }
    set_buttons();
    $window->Unbusy();
}

sub clearallmacs {
    our $listbox;
    our $window;
    $window->Busy(-recurse => 1);
    my @macs = $listbox->get(0, 'end');
    foreach my $mac (@macs) {
      delete $MAC{$mac};
    }
    $listbox->delete(0, 'end');
    $listbox->update();
    set_buttons();
    $window->Unbusy();
}

sub clear_mac {
    my ($node, $noupdate) = @_;
    our $listbox;
    our $tree;
    unless( $node ) { $node = $tree->infoSelection() or return undef; }
    unless( defined($noupdate) ) {$noupdate = 0;}
    my $client;

    # hack to support both perl-Tk-800 and perl-Tk-804
    $node = $$node[0] if ref($node) eq "ARRAY";

    if($node =~ /^\|([^\|]+)/) {
        $client = list_client(name=>$1);
    } else {
        return undef;
    }
    my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
    my $mac = $adapter->mac;
    if ( ! $mac ) { return undef; }
    oscar_log_subsection("Step $step_number: Cleared $mac from $1");

    # now put the mac back in the pool
    $listbox->selectionClear(0, 'end');
    $listbox->insert('end', ( $mac ));
    $MAC{$mac}->{client} = undef;
    $adapter->mac("");
    set_adapter($adapter);
    regenerate_listbox();
    if ( ! $noupdate ) {regenerate_tree();}
    if ( our $dyndhcp && ! $noupdate ) {
      our $vars;
      setup_dhcpd($$vars{interface});
    }
}

sub clearallmacsfromnodes {
    our $listbox;
    our $tree;
    our $window;
    $tree->selectionClear();
    $window->Busy(-recurse => 1);
    my @macs = $listbox->get(0, 'end');
    @macs = reverse @macs;
    $listbox->delete(0, 'end');
    my $client;
    my $adapter;
    foreach my $child ( $tree->infoChildren('|') ) {
      clear_mac($child, 1);
    }
    regenerate_tree();
    if (our $dyndhcp) {
      our $vars;
      setup_dhcpd($$vars{interface});
    }
    $window->Unbusy();
}

sub regenerate_listbox {
    our $listbox;
    $listbox->delete(0,"end");
    foreach my $key (sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC){
        if(!$MAC{$key}->{client}) {
            $listbox->insert("end",$key);
        }
    }
    $listbox->update;
    set_buttons();
}

sub end_collect_mac {
    my $interface = shift;
    our $listbox;
    our $label;
    our $starttext = $startcoll;
    $label->configure(-text => 
        "Not Listening to Network. Click \"$starttext\" to start.");

    our $bootcd->configure(-state => 'normal');
    our $networkboot->configure(-state => 'normal');
    our $loadbutton->configure(-state => 'normal');
    our $exitbutton->configure(-state => 'normal');
    set_buttons();

    our $start->configure(-command => [\&begin_collect_mac, $interface]);
    __end_collect_mac($interface);
    oscar_log_subsection("Step $step_number: Stopped listening to network");
    $COLLECT = 0;
}

# Interesting enough Mandrake and RedHat seem to compile tcpdump
# differently.  The two regexes should work with both.  We may have to
# add additional lines for other versions of tcpdump.
#
# The real solution is using Net::RawIP... but figuring out how that bad
# boy works is a full time job itself.

sub begin_collect_mac {
    return if $COLLECT; # This is so we don't end up with 2 tcpdump processes
    $COLLECT = 1;
    my $interface = shift;
    our $listbox;
    our $window;
    our $starttext = $stopcoll;
    our $label;
    our $start;

    our $bootcd->configure(-state => 'disabled');
    our $networkboot->configure(-state => 'disabled');
    our $savebutton->configure(-state => 'disabled');
    our $loadbutton->configure(-state => 'disabled');
    our $exitbutton->configure(-state => 'disabled');

    $start->configure(-command => [\&end_collect_mac, $interface]);
    start_ping($interface);
    my $cmd = "/usr/sbin/tcpdump -i $interface -n -e -l";
    oscar_log_subsection("Step $step_number: Starting to listen to network: ".
                         "$cmd");
    open(TCPDUMP,"$cmd |") or (carp("Could not run $cmd"), return undef);
    $label->configure(-text => 
        "Currently Scanning Network... Click \"$starttext\" to stop.");
    while($COLLECT and $_ = <TCPDUMP>) {
        # print $_ unless $_ =~ /echo/;
        # This is for tcpdump version 3.8 (MDK 10.0)
    if(/^\S+.*BOOTP\/DHCP,\sRequest\sfrom\s([a-f0-9\:]{11,17}).*$/) {
        regenerate_listbox() if add_mac_to_hash( $1 );
    }
    # This is the for tcp dump version 3.6 (MDK 8.0)
        if(/^\S+\s+([a-f0-9\:]{11,17}).*bootp.*\(DF\)/) {
#            print "1 collected: ", $_||"NOTHING\n";
             regenerate_listbox() if add_mac_to_hash( $1 );
        }
        # This is for tcp dump version 3.4 (RH 7.1)
        elsif (/^\S+\s+\S\s+([a-f0-9\:]{11,17}).*\[\|bootp\]/) {
#            print "2 collected: ", $_||"NOTHING\n";
             regenerate_listbox() if add_mac_to_hash( $1 );
        }
        # This is for tcp dump version 3.6 (RH 7.2 for IA64)
        elsif(/^\S+\s+([a-f0-9\:]{11,17}).*bootp/) {
#            print "3 collected: ", $_||"NOTHING\n";
             regenerate_listbox() if add_mac_to_hash( $1 );
        }

        $window->update;
    }
    close(TCPDUMP);
    system("killall tcpdump");
    end_ping();
}

# Import MACs via user input (entry widget)
sub macs_inputer {
    our $window;
    $window->Busy(-recurse => 1);
    my $widget = $window->Toplevel;
    $widget->withdraw;
    $widget->title("Input MAC address");

    my $topframe = $widget->Frame();
    my $bottomframe = $widget->Frame();

    my $mac = "";
    my $entry = $topframe->Entry(
            -textvariable => \$mac,
            -width => 31,
    );

    # Put input cursor on the entry dialogbox
    $entry->focus;

    my $apply = sub {
            load_macs($mac);
            $entry->delete(0, 'end');
    };

    my $applyButton = $bottomframe->Button(
        -text => "Apply",
        -command => $apply,
    );
    my $clearButton = $bottomframe->Button(
        -text => "Clear",
        -command => sub {$entry->delete(0, 'end');},
    );
    my $closeButton = $bottomframe->Button(
        -text => "Close",
        -command => sub {
                $window->Unbusy();
                $widget->destroy;
                },
    );

    $topframe->pack(-side => 'top');
    $bottomframe->pack(-side => 'top');

    $entry->pack();
    $applyButton->pack(-side => 'left');
    $clearButton->pack(-side => 'left');
    $closeButton->pack(-side => 'left');

    $entry->bind('<Return>' => $apply);
    $entry->bind('<KP_Enter>' => $apply);

    OSCAR::Tk::center_window($widget);

    regenerate_listbox();
    return 1;
}

sub macfile_selector {
    my ($op, $widget) = @_;

    # now we attempt to do some reasonable directory setting
    my $dir = $ENV{HOME};
    $dir = dirname( $dir ) unless -d $dir;
    $dir = "/" unless -d $dir;

    if( $op eq "load" ) {
        my $file = $widget->getOpenFile(
            -initialdir => $dir,
            -title => "Import MACs from file",
        );
        return 1 unless $file;
        load_from_file( $file );
    } else {
        my $file = $widget->getSaveFile(
            -initialdir => $dir,
            -initialfile => "mac-addresses",
            -title => "Export MACs to file",
        );
        return 1 unless $file;
        save_to_file( $file );
    }
    regenerate_listbox();
    return 1;
}

# Subroutine that takes MAC address string as input and pass it to the 
# add_mac_to_hash subroutine if string is validated to be a sane MAC address
# TODO: - merge with load_from_file subroutine as there seems to be code 
#         duplication
#       - better MAC address validation
sub load_macs {
    my $string = shift;

    __load_macs($string);
    regenerate_listbox();
    return 1;
}

# Call library to execute setup_pxe script
sub run_setup_pxe {
    our $window;
    our $uyok;
    $window->Busy(-recurse => 1);

    __run_setup_pxe($uyok);

    $window->Unbusy();
    return 1;
}

# Build AutoInstall CD
sub build_autoinstall_cd {
    my $ip = shift;

    __build_autoinstall_cd($ip);
    OSCAR::Tk::done_window($window,"You can now burn your ISO image to a " .
                           "CDROM with a command such as:\n'cdrecord -v " .
                           "speed=2 dev=1,0,0 /tmp/oscar_bootcd.iso'.");
}

# Call the library function to enable selected install mode
sub enable_install_mode {
    our $install_mode;
    our $window;
    $window->Busy(-recurse => 1);

    __enable_install_mode();
    our $dhcpbutton->configure(-state => 'normal');
    $window->Unbusy();
    return 1;
}

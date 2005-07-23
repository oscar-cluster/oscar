package OSCAR::MAC;


# Copyright (c) 2004 	The Board of Trustees of the University of Illinois.
#                     	All rights reserved.
#			Jason Brechin <brechin@ncsa.uiuc.edu>

#   $Id: MAC.pm,v 1.47 2004/04/06 15:21:32 brechin Exp $

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

use Net::Netmask;
use Tk;
use Tk::Tree;
use SystemImager::Client;
use File::Copy;
use SIS::Adapter;
use SIS::DB;
use OSCAR::Network;
use OSCAR::Tk;

use strict;
use Carp;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Logger;
use OSCAR::Database;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw (  save_to_file
                load_from_file
                start_mac_collect
                stop_mac_collect 
                mac_window
             );
#REMOVE MAC_WINDOW FROM EXPORT WHEN NO LONGER NEEDED

$VERSION = sprintf("%d.%02d", q$Revision: 1.47 $ =~ /(\d+)\.(\d+)/);

# %MAC = (
#                   'macaddr' => {client => 'clientname', order => 'order collected'}
#                 );
#                 client will be client name or undef for unassigned
#                 order will be a number

my %MAC = (); # mac will be -1 for unknown, machine name for known

my @SERVERMACS;     # a variable which stores a regex of the server mac addreses
my $ORDER = 1;      # global count variable
my $COLLECT = 0;    # are we collecting or not?
our $PINGPID = undef; # process id of the ping fork we make
my $step_number;    # which step number of the oscar process we are in
our $destroyed = 0;

our $startcoll = "Start Collecting MACs";
our $stopcoll = "Stop Collecting MACs";

sub mac_window {
    $destroyed = 1;
    my $parent = shift;
    $step_number = shift;
    our ($vars) = @_;
    $parent->Busy(-recurse => 1);
    # init this only once, as we don't add network cards during this process
    @SERVERMACS = set_servermacs();

    our $window = $parent->Toplevel;
    $window->withdraw;
    $window->title("Setup Networking");
    
    oscar_log_section("Running step $step_number of the OSCAR wizard: Setup networking");

    my $instructions = $window->Message(-text => "MAC Address collection.  When a new MAC address is received on the network, it will appear in the left column.  To assign that MAC address to a machine highlight the address and the machine and click \"Assign MAC to Node\".", -aspect => 800);

    our $starttext = $startcoll;
    our $label = $window->Label(-text => "Not Listening to Network. Click \"$starttext\" to start.", -relief => 'sunken');


    my $frame = $window->Frame();
    my $topframe = $window->Frame();

    our $listbox = $topframe->ScrlListbox(
                                       -selectmode => 'single',
                                       -background => "white",
                                       -scrollbars => 'osoe',
                                      );

    our $tree = $topframe->Scrolled("Tree",    
                                 -background => "white",
                                 -itemtype => 'imagetext',
                                 -separator => '|',
                                 -selectmode => 'single',
                                 -scrollbars => 'osoe',
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
                                   -command => [\&begin_collect_mac, $$vars{interface} ],
                                   );
    our $exitbutton = $frame->Button(
                                     -text => "Close",
                                     -command => sub {
                                         undef $destroyed;
                                         end_ping(); 
                                         end_collect_mac($label); 
                                         oscar_log_subsection("Step $step_number: Completed successfully"); 
                                         $parent->Unbusy();
                                         $window->destroy;
                                     },
                                    );
    our $assignbutton = $frame->Button(
                                      -text => "Assign MAC to Node",
                                      -command => [\&assign2machine, undef, undef],
                                      -state => "disabled",
                                     );
    our $deletebutton = $frame->Button(
                                      -text => "Delete MAC from Node",
                                      -command => \&clear_mac,
                                      -state => "disabled",
                                     );
    my $dhcpbutton = $frame->Button(
                                    -text => "Configure DHCP Server",
                                    -command => [\&setup_dhcpd, $$vars{interface}],
                                   );

    our $dyndhcp = 1;
    my $refreshdhcp = $frame->Checkbutton(
                                -text => "Dynamic DHCP update",
                                -variable => \$dyndhcp,
                                );

    our $multicast = 0;
    my $selectmulticast = $frame->Checkbutton(
                                -text => "Enable Multicasting",
                                -variable => \$multicast,
                                );

    my $fileselector = $frame->FileSelect(-directory => "$ENV{HOME}");
    our $loadbutton = $frame->Button(
                                   -text=>"Import MACs from file...",
                                   -command=> [\&macfile_selector, "load", $fileselector],
                                  );
    our $savebutton = $frame->Button(
                                    -text => "Export MACs to file...",
                                    -command => [\&macfile_selector, "save", $fileselector],
                                    -state => "disabled",
                                   );

    our $bootfloppy = $frame->Button(
                                    -text => "Build Autoinstall CD...",
                                    -command => sub {
                                        my $cmd = "xterm -T 'Build Autoinstall CD' -e si_mkautoinstallcd --out-file /tmp/oscar.iso";
                                        oscar_log_subsection("Step $step_number: Building autoinstall cd: $cmd");
                                        system($cmd);
                                        oscar_log_subsection("Step $step_number: Successfully built si_autoinstallcd");
					done_window($window,"You can now burn your ISO image to a CDROM with a command such as:\n'cdrecord -v speed=2 dev=1,0,0 /tmp/oscar.iso'.");
                                    }
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

    $start->grid($assignall, $exitbutton, -sticky => "ew");
    $assignbutton->grid($deletebutton, $dhcpbutton, -sticky => "ew");
    $loadbutton->grid($savebutton, $selectmulticast, -sticky => "ew");
    my $label2 = $frame->Label(-text => "Below are commands to create a boot environment.\nYou can either boot from floppy or network");
    $label2->grid("-","-",-sticky => "ew");
    $bootfloppy->grid($networkboot, $refreshdhcp, -sticky => "ew");
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
    center_window( $window );
}

sub set_buttons {
    our $listbox;
    our $tree;
    my $state;
#
#   Enabled iff at least one item selected in the listbox.
#
    my $lbs = defined $listbox->curselection();
    $state = $lbs ? "normal" : "disabled";
    our $clear->configure( -state => $state );
#
#   Enabled iff at least one item is in the listbox.
#
    $state = (defined $listbox->get( 0, 'end' )) ? "normal" : "disabled";
    our $clearall->configure( -state => $state );
    our $assignall->configure( -state => $state );
#
#	Enabled iff at least one MAC exists.
#
    $state = (scalar keys %MAC) ? "normal" : "disabled";
    our $savebutton->configure( -state => $state );
#
#   Enabled iff at least one item selected in the listbox and the tree.
#
    my $trs = defined $tree->infoSelection();
    $state = ($lbs && $trs) ? "normal" : "disabled";
    our $assignbutton->configure( -state => $state );
#
#   Enabled iff at least one item selected in listbox and selected item in tree has a MAC.
#
    my @node = $tree->infoSelection();
    if( $trs && $node[0] =~ /^\|([^\|]+)/) {
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
    oscar_log_subsection("Step $step_number: cleaning hostfile");
    clean_hostsfile() or (carp "Couldn't clean hosts file!",
                          return undef);
    
    carp "About to run setup_dhcpd";
    if(-e "/etc/dhcpd.conf") {
        copy("/etc/dhcpd.conf", "/etc/dhcpd.conf.oscarbak") or (carp "Couldn't backup dhcpd.conf file", return undef);
    }
    my ($ip, $broadcast, $netmask) = interface2ip($interface);
    my $cmd = "mkdhcpconf -o /etc/dhcpd.conf --interface=$interface --bootfile=pxelinux.0 --gateway=$ip";
    if(our $multicast){
       $cmd = "mkdhcpconf -o /etc/dhcpd.conf --interface=$interface --bootfile=pxelinux.0 --gateway=$ip --multicast=yes";
    }
    oscar_log_subsection("Step $step_number: Running command: $cmd");
    !system($cmd) or (carp "Couldn't mkdhcpconf", return undef);
    oscar_log_subsection("Step $step_number: Successfully ran command");
    if(!-e "/var/lib/dhcp/dhcpd.leases") {
        open(OUT,">/var/lib/dhcp/dhcpd.leases") or (carp "Couldn't create dhcpd.leases files", return undef);
        close(OUT);
    }
    oscar_log_subsection("Step $step_number: Restarting dhcpd service");
    !system("/etc/init.d/dhcpd restart") or (carp "Couldn't restart dhcpd", 
                                         return undef);
    oscar_log_subsection("Step $step_number: Successfully restarted dhcpd service");
    $window->Unbusy();
    return 1;
}

sub clean_hostsfile {
    my $file = "/var/lib/systemimager/scripts/hosts";
    copy($file, "$file.bak") or (carp "Couldn't backup rsyncable hosts file!",
                                 and return undef);
    open(IN,"<$file.bak") or (carp "Couldn't open $file.bak for reading!",
                                 and return undef);
    open(OUT,">$file") or (carp "Couldn't open $file for writing!",
                                 and return undef);
    while(<IN>) {
        if(/^\#/) {
            print OUT $_;
        }elsif(/^([\d+\.]+).*\s([^\s\.]+)\s/) {
            print OUT "$1     $2\n";
        }
    }
    close(OUT);
    close(IN);
}
 
# Use Schwartzian transform to sort clients by node names alphabetically and numerically.
# Names w/o numeric suffix precede those with numeric suffix.
sub sortclients(@) {
	return map { $_->[0] }
	       sort { $a->[1] cmp $b->[1] || ($a->[2]||-1) <=> ($b->[2]||-1) }
	       map { [$_, $_->name =~ /^([\D]+)([\d]*)$/] }
	       @_;
}

# populates existing MAC entries into the global hash

sub populate_MACS {
    my @clients = sortclients list_client();
    %MAC = ();
    foreach my $client (@clients) {
        my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
        if ($adapter->mac) {
                add_mac_to_hash($adapter->mac, $client->name);
        }
    }
}

sub regenerate_tree {
    our $tree;
    $tree->delete("all");
    $tree->add("|",-text => "All Clients",-itemtype => "text");
    my @clients = sortclients list_client();
    foreach my $client (@clients) {
        my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
        $tree->add("|".$client->name, -text => $client->hostname, -itemtype => "text");
        my $mac=$adapter->mac || "" ;
        $tree->add("|".$client->name . "|mac", 
                   -text => $adapter->devname . " mac = " . $mac, -itemtype => "text");
        $tree->add("|".$client->name . "|ip" . $adapter->devname, 
           -text => $adapter->devname . " ip = " . $adapter->ip, -itemtype => "text");
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
    MAC: while ( scalar(@macs)) {
      unless ( $tempnode = $tree->infoNext($tempnode) ) {
        last MAC;
      }
      $tempnode =~ /^\|([^\|]+)/;
      $client = list_client(name=>$1);
      $adapter = list_adapter(client=>$client->name,devname=>"eth0");
      unless ( $adapter->mac ) {
        assign2machine(pop @macs, $tempnode, 1);
      }
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
    foreach my $key (sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC) {
        if(!$MAC{$key}->{client}) {
            $listbox->insert("end",$key);
        }
    }
    $listbox->update;
    set_buttons();
}

# Ok, here is the problem.  This whole thing works great on a network with
# a bunch of traffic.  It sucks on a quiet one.  So when we start up the
# tcpdump command we also fork a broadcast ping to generate more
# traffic on the network.

sub start_ping {
    my $interface = shift;
    end_ping();
    my ($ip, $broad, $nm) = interface2ip($interface);
    my $network = new Net::Netmask($ip, $nm);
    my $pid = fork();

    if($pid) {
        $PINGPID = $pid;
    } else {
        oscar_log_subsection("Step $step_number: Launching background ping");
        open(STDOUT,">/dev/null");
        system("ping -b " . $network->base);
        oscar_log_subsection("Step $step_number: Background ping stopped");
        exit 0;
    }
}

sub end_ping {
    if($PINGPID) {
        print "Attempting to kill $PINGPID\n";
        kill 15, $PINGPID;
        $PINGPID = undef;
    }
}

sub end_collect_mac {
    my $interface = shift;
    our $listbox;
    our $label;
    our $starttext = $startcoll;
    $label->configure(-text => "Not Listening to Network. Click \"$starttext\" to start.");

    our $bootfloppy->configure(-state => 'normal');
    our $networkboot->configure(-state => 'normal');
    our $loadbutton->configure(-state => 'normal');
    our $exitbutton->configure(-state => 'normal');
    set_buttons();

    our $start->configure(-command => [\&begin_collect_mac, $interface]);
    system("killall tcpdump");
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

    our $bootfloppy->configure(-state => 'disabled');
    our $networkboot->configure(-state => 'disabled');
    our $savebutton->configure(-state => 'disabled');
    our $loadbutton->configure(-state => 'disabled');
    our $exitbutton->configure(-state => 'disabled');

    $start->configure(-command => [\&end_collect_mac, $interface]);
    start_ping($interface);
    my $cmd = "/usr/sbin/tcpdump -i $interface -n -e -l";
    oscar_log_subsection("Step $step_number: Starting to listen to network: $cmd");
    open(TCPDUMP,"$cmd |") or (carp("Could not run $cmd"), return undef);
    $label->configure(-text => "Currently Scanning Network... Click \"$starttext\" to stop.");
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

# 

sub macfile_selector {
    my ($op, $selector) = @_;
    our $listbox;

    # now we attempt to do some reasonable directory setting
    my $dir = $ENV{HOME};
    if(-d $dir) {
        $selector->configure(-directory => $dir);
    } else {
        my $dir2 = dirname($dir);
        if(-d $dir2) {
            $selector->configure(-directory => $dir2);
        }
    }
    my $file = $selector->Show();
    if(!$file) {
        return 1;
    } 
    if($op eq "load") {
        load_from_file($file);
    } elsif($op eq "save") {
        save_to_file($file);
    }
    regenerate_listbox();
    return 1;
}

sub save_to_file {
    my $file = shift;
    open(OUT,">$file") or croak "Couldn't open file: $file for writing";
    print OUT "# Saved OSCAR MAC Addresses; ", scalar localtime, "\n";
    foreach my $mac (sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC) {
        print OUT $mac, "\n";
    }
    close(OUT);
    return 1;
}

sub load_from_file {
    my $file = shift;
    open(IN,"<$file") or croak "Couldn't open file: $file for reading";
    while(<IN>) {
        if(/^\s*\#/) {
            next;
        }
        if(/^\s*([a-fA-F0-9\:]{11,17})/) {
            my $mac = $1;
            add_mac_to_hash($mac);
        }
    }
    close(IN);
    return 1;
}

sub set_servermacs {
    open(CMD, "/sbin/ifconfig|");
    my @hostmacs = map {/HWaddr\s+([[:xdigit:]:]+)\s+/} grep /HWaddr/, <CMD>;
    close CMD;
    foreach (@hostmacs) {
       $_ = uc mactransform( $_ );
    }
    return @hostmacs;
}

sub add_mac_to_hash {
    my ($m, $client) = @_;
    my $mac = uc mactransform( $m );
    # if the mac is 00:00:00:00:00:00, it isn't real
    if($mac =~ /^[0\:]+$/) {
        return 0;
    }
    # If the MAC is the server's, then get out of here
    if ( grep {$mac eq $_} @SERVERMACS ) {
        return 0;
    }
    # if it already has an order, then we already know about it
    if($MAC{$mac}->{order}) {
        return 0;
    }
    # else, add the mac address with a null client
    $MAC{$mac} = {
                  client => $client,
                  order => $ORDER,
                 };
    $ORDER++;
    return 1;
}

# mac transform does a join map split trick to ensure that each octet is 2 characters

sub mactransform {
    my $mac = shift;
    my $return = uc join ':', (map {(length($_) == 1) ? "0$_" : "$_"} split (':',$mac));
    return $return;
}

# Sub to initiate the setup_pxe script
sub run_setup_pxe {
    our $window;
    $window->Busy(-recurse => 1);

    my $cmd = "./setup_pxe -v";
    oscar_log_subsection("Step $step_number: Setup network boot: $cmd");
    !system($cmd) or (carp($!), $window->Unbusy(), return undef);

    $cmd = "../packages/kernel/scripts/fix_network_boot";
    if ( -x $cmd) {
        oscar_log_subsection("Step $step_number: Finishing network boot: $cmd");
        system($cmd);
        oscar_log_subsection("Step $step_number: Successfully finished network boot");
    }

    oscar_log_subsection("Step $step_number: Successfully setup network boot");
    $window->Unbusy();
    return 1;
}

1;


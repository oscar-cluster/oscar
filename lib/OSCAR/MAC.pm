package OSCAR::MAC;

#   $Id: MAC.pm,v 1.35 2003/01/29 19:51:15 brechin Exp $

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

#   Copyright 2001-2003 International Business Machines
#                       Sean Dague <sean@dague.net>

use strict;
use Net::Netmask;
use vars qw($VERSION @EXPORT);
use Tk;
use Tk::Tree;
use Carp;
use SIS::Client;
use File::Copy;
use SIS::Adapter;
use SIS::DB;
use OSCAR::Network;
use OSCAR::Logger;
use base qw(Exporter);
@EXPORT = qw(mac_window);

$VERSION = sprintf("%d.%02d", q$Revision: 1.35 $ =~ /(\d+)\.(\d+)/);

# %MAC = (
#                   'macaddr' => {client => 'clientname', order => 'order collected'}
#                 );
#                 client will be client name or undef for unassigned
#                 order will be a number

my %MAC = (); # mac will be -1 for unknown, machine name for known

my $SERVERMACS;     # a variable which stores a regex of the server mac addreses
my $ORDER = 1;      # global count variable
my $COLLECT = 0;    # are we collecting or not?
my $PINGPID = undef; # process id of the ping fork we make
my $step_number;    # which step number of the oscar process we are in
our $destroyed = 0;

sub mac_window {
    $destroyed = 1;
    my $parent = shift;
    $step_number = shift;
    our ($vars) = @_;
    $parent->Busy(-recurse => 1);
    # init this only once, as we don't add network cards during this process
    $SERVERMACS = set_servermacs();

    my $window = $parent->Toplevel;
    $window->title("MAC Address Collection");
    
    oscar_log_section("Running step $step_number of the OSCAR wizard: Setup networking");

    my $instructions = $window->Message(-text => "MAC Address Collection Tool.  When a new MAC address is received on the network, it will appear in the left column.  To assign that MAC address to a machine highlight the address and the machine and click 'Assign MAC to Node'.", -aspect => 800);

    our $label = $window->Label(-text => "Not Listening to Network. Click 'Collect MAC Addresses' to start.");


    my $frame = $window->Frame();
    my $topframe = $window->Frame();

    my $listbox = $topframe->ScrlListbox(
                                       -selectmode => 'single',
                                       -background => "white",
				       -scrollbars => 'osoe',
                                      );
    my $tree = $topframe->Scrolled("Tree",    
                                 -background => "white",
                                 -itemtype => 'imagetext',
                                 -separator => '|',
                                 -selectmode => 'single',
				 -scrollbars => 'osoe',
                                );

    $instructions->pack($label);

    my $clear    = $topframe->Button( 	-text => "Remove",
					-height=>1,
					-command => [\&clearmacaddy, $listbox, $window ],
				  );
    $clear->configure( -font => [ -size => 7 ] );
    my $clearall = $topframe->Button( 	-text => "Remove All",
					-height=>1,
					-command => [\&clearallmacs, $listbox, $window ],
				  );
    $clearall->configure( -font => [ -size => 7 ] );
    $frame->pack(-side => "bottom", -fill => "both", -expand => 1);
    $topframe->pack(-side => 'top', -fill => "both", -expand => 1);

    $listbox->grid('-', $tree, -sticky => 'nsew');
    $clear->grid($clearall, '^', -sticky => 'nsew');
    $topframe->gridColumnconfigure(0, -weight => 1);
    $topframe->gridColumnconfigure(1, -weight => 1);
    $topframe->gridColumnconfigure(2, -weight => 2);

    # this populates the tree as it exists
    populate_MACS();
    
    regenerate_tree($tree);
    our $starttext = "Collect MAC Addresses";
    our $start = $frame->Button(
                                   -textvariable => \$starttext,
                                   -command => [\&begin_collect_mac, $window, $listbox, $$vars{interface} ],
                                   );
#    my $stop = $frame->Button(
#                                         -text => "Stop Collecting",
#                                         -command => [\&end_collect_mac, $label, $starttext],
#                                         );
    my $exitbutton = $frame->Button(
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
    my $assignbutton = $frame->Button(
                                      -text => "Assign MAC to Node",
                                      -command => [\&assign2machine, $listbox, $tree, undef, undef, $window],
                                     );
    my $deletebutton = $frame->Button(
                                      -text => "Delete MAC from Node",
                                      -command => [\&clear_mac, $listbox, $tree, $window],
                                     );
    my $dhcpbutton = $frame->Button(
                                    -text => "Configure DHCP Server",
                                    -command => [\&setup_dhcpd, $$vars{interface}, $window],
                                   );

    our $dyndhcp = 1;
    my $refreshdhcp = $frame->Checkbutton(
				-text => "Dynamic DHCP update",
				-variable => \$dyndhcp,
				);

    my $fileselector = $frame->FileSelect(-directory => "$ENV{HOME}");
    my $loadbutton = $frame->Button(
                                   -text=>"Import MACs from file...",
                                   -command=> [\&macfile_selector, "load", $fileselector, $listbox],
                                  );
    my $savebutton = $frame->Button(
                                    -text => "Export MACs to file...",
                                    -command => [\&macfile_selector, "save", $fileselector, $listbox],
                                   );

    my $bootfloppy = $frame->Button(
                                    -text => "Build Autoinstall Floppy...",
                                    -command => sub {
					my $cmd = "xterm -T 'Build Autoinstall Floppy' -e mkautoinstalldiskette";
					oscar_log_subsection("Step $step_number: Building autoinstall floppy: $cmd");
					system($cmd);
					oscar_log_subsection("Step $step_number: Successfully built autoinstallfloppy");
				    }
                                   );
    my $networkboot = $frame->Button(
                                     -text => "Setup Network Boot",
                                     -command => [\&run_setup_pxe, $window],
                                    );

    my $assignall   = $frame->Button(
				     -text => "Assign all MACs",
				     -command => [\&assignallmacs, $listbox, $tree, $window],
				    );

    $start->grid($assignall, $exitbutton, -sticky => "ew");
    $assignbutton->grid($deletebutton, $dhcpbutton, -sticky => "ew");
    $loadbutton->grid($savebutton, -sticky => "ew");
    my $label2 = $frame->Label(-text => "Below are commands to create a boot environment.\nYou can either boot from floppy or network");
    $label2->grid("-","-",-sticky => "ew");
    $bootfloppy->grid($networkboot, $refreshdhcp, -sticky => "ew");

    $window->bind('<Destroy>', sub {
        if ( defined($destroyed) ) {
          undef $destroyed;
          $exitbutton->invoke();
          return;
        }
                                   });
}

sub setup_dhcpd {
    my ($interface,$window) = @_;
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
    oscar_log_subsection("Step $step_number: Running command: $cmd");
    !system($cmd) or (carp "Couldn't mkdhcpconf", return undef);
    oscar_log_subsection("Step $step_number: Successfully ran command");
    if(!-e "/var/lib/dhcp/dhcpd.leases") {
        open(OUT,">/var/lib/dhcp/dhcpd.leases") or (carp "Couldn't create dhcpd.leases files", return undef);
        close(OUT);
    }
    oscar_log_subsection("Step $step_number: Restarting dhcpd service");
    !system("service dhcpd restart") or (carp "Couldn't restart dhcpd", 
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

# populates existing MAC entries into the global hash

sub populate_MACS {
    my @clients = list_client();
    %MAC = ();
    foreach my $client (@clients) {
        my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
	if ($adapter->mac) {
        	add_mac_to_hash($adapter->mac, $client->name);
	}
    }
}

sub regenerate_tree {
    my ($tree) = @_;
    $tree->delete("all");
    $tree->add("|",-text => "All Clients",-itemtype => "text");
    my @clients = list_client();
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
}

sub message_window {
    
}

sub assign2machine {
    my ($listbox, $tree, $mac, $node, $window, $dhcp) = @_;
    unless ( defined($dhcp) ) { $dhcp = 1; }
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
    clear_mac($listbox, $tree, $window);
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
    regenerate_listbox($listbox);
    regenerate_tree($tree);
    if ( our $dyndhcp && $dhcp ) {
      our $vars;
      setup_dhcpd($$vars{interface}, $window);
    }
}

sub assignallmacs {
    my ($listbox, $tree, $window) = @_;
    $tree->selectionClear();
    $window->Busy(-recurse => 1);
    my @macs = $listbox->get(0, 'end');
    @macs = reverse @macs;
    $listbox->delete(0, 'end');
    regenerate_listbox($listbox);
    my $client;
    my $adapter;
    my $tempnode = '|';
    MAC: while ( scalar(@macs)) {
      unless ( $tempnode = $tree->infoNext($tempnode) ) {
        #$window->Unbusy();
        last MAC;
      }
      $tempnode =~ /^\|([^\|]+)/;
      $client = list_client(name=>$1);
      $adapter = list_adapter(client=>$client->name,devname=>"eth0");
      unless ( $adapter->mac ) {
        assign2machine($listbox, $tree, pop @macs, $tempnode, $window, 0);
      }
    }
    if ( our $dyndhcp ) {
      our $vars;
      setup_dhcpd($$vars{interface}, $window);
    }
    $listbox->insert(0, @macs);
    regenerate_listbox($listbox);
    $window->Unbusy();
}

sub clearmacaddy {
    my ($listbox, $window) = @_;
    my $macindex = '';
    $window->Busy(-recurse => 1);
    if ( defined($listbox->curselection) ) {
      $macindex=$listbox->curselection;
      #print $listbox->get($macindex) . "\n";
      #print $macindex . "\n";
      #$listbox->selectionClear(0, 'end');
      delete $MAC{$listbox->get($macindex)};
      $listbox->delete($macindex);
      $listbox->update();
    }
    $window->Unbusy();
}

sub clearallmacs {
    my ($listbox, $window) = @_;
    $window->Busy(-recurse => 1);
    my @macs = $listbox->get(0, 'end');
    foreach my $mac (@macs) {
      delete $MAC{$mac};
    }
    $listbox->delete(0, 'end');
    $listbox->update();
    $window->Unbusy();
}

sub clear_mac {
    my ($listbox, $tree, $window) = @_;
    my $node = $tree->infoSelection() or return undef;
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
    $MAC{$mac}->{client} = undef;
    $adapter->mac("");
    set_adapter($adapter);
    regenerate_listbox($listbox);
    regenerate_tree($tree);
    if ( our $dyndhcp ) {
      our $vars;
      setup_dhcpd($$vars{interface}, $window);
    }
}

sub regenerate_listbox {
    my $listbox = shift;
    $listbox->delete(0,"end");
    foreach my $key (sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC) {
        if(!$MAC{$key}->{client}) {
            $listbox->insert("end",$key);
        }
    }
    $listbox->update;
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

    oscar_log_subsection("Step $step_number: Launching background ping");
    if($pid) {
        $PINGPID = $pid;
    } else {
        open(STDOUT,">/dev/null");
        exec("ping -b " . $network->base);
    }
}

sub end_ping {
    if($PINGPID) {
        print "Attempting to kill $PINGPID\n";
        kill 15, $PINGPID;
        $PINGPID = undef;
    }
    oscar_log_subsection("Step $step_number: Killed background ping");
}

sub end_collect_mac {
    my ($window, $listbox, $interface) = @_;
    our $label;
    $label->configure(-text => "Not Listening to Network. Click 'Collect MAC Addresses' to start.");
    our $starttext = "Start Collecting MACs";
    our $start;
    $start->configure(-command => [\&begin_collect_mac, $window, $listbox, $interface, $label ]);
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
    my ($window, $listbox, $interface) = @_;
    our $starttext;
    our $label;
    our $start;
    $starttext = "Stop Collecting MACs";
    $start->configure(-command => [\&end_collect_mac, $window, $listbox, $interface ]);
    start_ping($interface);
    my $cmd = "/usr/sbin/tcpdump -i $interface -n -e -l";
    oscar_log_subsection("Step $step_number: Starting to listen to network: $cmd");
    open(TCPDUMP,"$cmd |") or (carp("Could not run $cmd"), return undef);
    $label->configure(-text => "Currently Scanning Network... Click 'Stop Collecting' to stop.");
    while($COLLECT and $_ = <TCPDUMP>) {
        # print $_ unless $_ =~ /echo/;
        # This is the for tcp dump version 3.6 (MDK 8.0)
        if(/^\S+\s+([a-f0-9\:]{11,17}).*bootp.*\(DF\)/) {
            my $mac = mactransform($1);
            if(add_mac_to_hash($mac)) {
                regenerate_listbox($listbox);
            }
        } 
        # This is for tcp dump version 3.4 (RH 7.1)
        elsif (/^\S+\s+\S\s+([a-f0-9\:]{11,17}).*\[\|bootp\]/) {
            my $mac = mactransform($1);
            if(add_mac_to_hash($mac)) {
                regenerate_listbox($listbox);
            }
        }
        # This is for tcp dump version 3.6 (RH 7.2 for IA64)
        elsif(/^\S+\s+([a-f0-9\:]{11,17}).*bootp/) {
            my $mac = mactransform($1);
            if(add_mac_to_hash($mac)) {
                regenerate_listbox($listbox);
            }
        }

        $window->update;
    }
    close(TCPDUMP);
    end_ping();
}

# 

sub macfile_selector {
    my ($op, $selector, $listbox) = @_;

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
    regenerate_listbox($listbox);
    return 1;
}

sub save_to_file {
    my $file = shift;
    open(OUT,">$file") or croak "Couldn't open file: $file for writing";
    print OUT "# Saved OSCAR MAC Addresses\n";
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
    open(CMD, "/sbin/ifconfig | grep HWaddr | tail -c 20 | sed -e 's-\:-\\\:-g' |");
    my @hostmacs = <CMD>;
    close CMD;
    my $macregex = "(" . (join '|', @hostmacs) . ")";
    return $macregex;
}

sub add_mac_to_hash {
    my ($mac, $client) = @_;
    # if the mac is 00:00:00:00:00:00, it isn't real
    if($mac =~ /^[0\:]+$/) {
        return 0;
    }
    # If the MAC is the server's, then get out of here
    if ($mac =~ /$SERVERMACS/) {
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
    my $return = join ':', (map {(length($_) == 1) ? "0$_" : "$_"} split (':',$mac));
    return $return;
}

# Sub to initiate the setup_pxe script
sub run_setup_pxe {
    my ($window) = @_;
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

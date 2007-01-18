package OSCAR::MAC;

# Copyright (c) 2004 	The Board of Trustees of the University of Illinois.
#                     	All rights reserved.
#			Jason Brechin <brechin@ncsa.uiuc.edu>
# Copyright (C) 2006 Bernard Li <bli@bcgsc.ca>
#                    All rights reserved.

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
use OSCAR::Network;
use OSCAR::Tk;

use Carp;
use OSCAR::Logger;
use OSCAR::Database;
use OSCAR::OCA::OS_Detect;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw (  save_to_file
                load_from_file
                start_mac_collect
                stop_mac_collect 
                mac_window
             );
#REMOVE MAC_WINDOW FROM EXPORT WHEN NO LONGER NEEDED

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

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

our $window;
our $kernel;
our $ramdisk;
#our $uyok_generated = 0;

my @install_mode_options = qw(systemimager-rsync systemimager-multicast systemimager-bt);

# Subroutines below here...

our $os = OSCAR::OCA::OS_Detect::open();
sub sortclients;

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
        oscar_log_section("Running step $step_number of the OSCAR wizard: Setup networking");
    }

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
                                   -command => [\&begin_collect_mac, $$vars{interface} ],
                                   );
    our $exitbutton = $frame->Button(
                                     -text => "Close",
                                     -borderwidth => "6",
                                     -relief => "groove",
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
    our $dhcpbutton = $frame->Button(
                                    -text => "Configure DHCP Server",
                                    -command => [\&setup_dhcpd, $$vars{interface}],
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
                                                     "-command" => [\&macfile_selector, "load", $frame] ],
                                                   [ 'command' => "user input...",
                                                     "-command" => \&macs_inputer ],
                                                 ],
                                   -tearoff => 0,
                                   -direction => "right",
                                   -relief => "raised",
                                   -indicatoron => 1,
                                  );

    our $savebutton = $frame->Button(
                                    -text => "Export MACs to file...",
                                    -command => [\&macfile_selector, "save", $frame],
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
    my $mac_label = $frame->Label(-text => "MAC Address Management", -relief => 'sunken');
    $mac_label->grid("-", "-", -sticky => "ew");
    $start->grid($assignall, $assignbutton, -sticky => "ew");
    $deletebutton->grid($loadbutton, $savebutton, -sticky => "ew");
    $loadbutton->grid($savebutton, -sticky => "ew");
    my $install_label = $frame->Label(-text => "Installation Mode and DHCP Setup", -relief => 'sunken');
    $install_label->grid("-", "-", -sticky => "ew");
    $install_button->grid($enable_install_button, -sticky => "ew");
    $refreshdhcp->grid($dhcpbutton, -sticky => "ew");
    my $label2 = $frame->Label(-text => "Boot Environment (CD or PXE-boot) Setup", -relief => 'sunken');
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
    center_window( $window );
}

sub set_buttons {
	our $listbox;
	our $tree;
	my $state;
	my $lbs;
	my $trs;
#
#	Enabled iff at least one item selected in the listbox.
#
	$lbs = defined $listbox->curselection();
	$state = $lbs ? "normal" : "disabled";
	our $clear->configure( -state => $state );
#
#	Enabled iff at least one item in listbox.
#
	$lbs = defined $listbox->get( 0, 'end' );
	$state = $lbs ? "normal" : "disabled";
	our $clearall->configure( -state => $state );
#
#	Enabled iff at least one item in listbox and one item in tree.
#
	$trs = $tree->infoNext( "|" );
	$state = ($lbs && $trs) ? "normal" : "disabled";
	our $assignall->configure( -state => $state );
#
#	Enabled iff at least one MAC exists.
#
	$state = (scalar keys %MAC) ? "normal" : "disabled";
	our $savebutton->configure( -state => $state );
#
#	Enabled iff at least one item selected in the listbox and the tree.
#
	$trs = defined $tree->infoSelection();
	$state = ($lbs && $trs) ? "normal" : "disabled";
	our $assignbutton->configure( -state => $state );
#
#	Enabled iff at least one item selected in listbox and selected item in tree has a MAC.
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
    our $install_mode;
    our $os;

    $window->Busy(-recurse => 1) if ($ENV{OSCAR_UI} eq "gui");
    oscar_log_subsection("Step $step_number: cleaning hostfile");
    clean_hostsfile() or (carp "Couldn't clean hosts file!",
                          return undef);
    
    my $dhcpd_configfile = "/etc/dhcpd.conf";
    # Under Debian the dhcpd config file is in /etc/dhcp3
    $dhcpd_configfile = "/etc/dhcp3/dhcpd.conf" if -x "/etc/dhcp3";
    carp "About to run setup_dhcpd";
    if(-e $dhcpd_configfile) {
        copy($dhcpd_configfile, $dhcpd_configfile.".oscarbak") or (carp "Couldn't backup dhcpd.conf file", return undef);
    }
    my ($ip, $broadcast, $netmask) = interface2ip($interface);
    my $cmd = "mkdhcpconf -o $dhcpd_configfile --interface=$interface --gateway=$ip";

    if ($install_mode eq "systemimager-multicast"){
       $cmd = $cmd . " --multicast=yes";
    }

    oscar_log_subsection("Step $step_number: Running command: $cmd");
    !system($cmd) or (carp "Couldn't mkdhcpconf", return undef);
    oscar_log_subsection("Step $step_number: Successfully ran command");

    my $dhcpd_leases = "/var/lib/dhcp/dhcpd.leases";

    # Fedora Core 5's dhcpd.leases file is located in a slightly different
    # directory
    if ( ($os->{'distro'} eq "fedora") && ($os->{'distro_version'} == "5") ) {
        $dhcpd_leases = "/var/lib/dhcpd/dhcpd.leases";
    }

    if(!-e "$dhcpd_leases") {
        open(OUT,">$dhcpd_leases") or (carp "Couldn't create dhcpd.leases files", return undef);
        close(OUT);
    }

    # Need to setup /etc/sysconfig/dhcpd on SUSE Linux prior to restarting dhcpd
    if ($os->{'distro'} eq "suse") {
        my $dhcpd_file = "/etc/sysconfig/dhcpd";
        run_cmd("/bin/mv -f $dhcpd_file $dhcpd_file.oscarbak");

        $cmd = "sed -e 's/^DHCPD_INTERFACE=\".*\"/DHCPD_INTERFACE=\"$interface\"/g' $dhcpd_file.oscarbak > $dhcpd_file";     
        if (system($cmd)) {
            carp("Failed to update $dhcpd_file");
            return 1;
        }
    }

    my $dhcpd = "dhcpd";
    # Under Debian the init script for dhcp is "dhcp3-server"
    $dhcpd = "dhcp3-server" if -x "/etc/init.d/dhcp3-server";
    oscar_log_subsection("Step $step_number: Restarting dhcpd service");
    !system("/etc/init.d/$dhcpd restart") or (carp "Couldn't restart $dhcpd", 
                                         return undef);
    oscar_log_subsection("Step $step_number: Successfully restarted dhcpd service");
    our $dhcpbutton->configure(-state => 'disabled') if ($ENV{OSCAR_UI} eq "gui");
    $window->Unbusy() if ($ENV{OSCAR_UI} eq "gui");
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
    my $pid = fork();

    if($pid) {
        $PINGPID = $pid;
    } else {
        oscar_log_subsection("Step $step_number: Launching background ping");
        open(STDOUT,">/dev/null");
        my $cmd = "ping -b $broad";
        exec("$cmd") or die("Failed to exec: $cmd");
        exit 0;
    }
}

sub end_ping {
    if($PINGPID) {
        print "Attempting to kill $PINGPID\n";
        kill 15, $PINGPID;
        $PINGPID = undef;
        wait();
        oscar_log_subsection("Step $step_number: Background ping stopped");
    }
}

sub end_collect_mac {
    my $interface = shift;
    our $listbox;
    our $label;
    our $starttext = $startcoll;
    $label->configure(-text => "Not Listening to Network. Click \"$starttext\" to start.");

    our $bootcd->configure(-state => 'normal');
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

    our $bootcd->configure(-state => 'disabled');
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

	center_window($widget);

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

sub save_to_file {
    my $file = shift;

    open(OUT,">$file") or croak "Couldn't open file: $file for writing";
    print OUT "# Saved OSCAR MAC Addresses; ", scalar localtime, "\n";
    foreach my $mac (sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC) {
        my $client = $MAC{$mac}->{client};
        print OUT $mac, "\t# $client\n";
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

# Subroutine that takes MAC address string as input and pass it to the add_mac_to_hash
# subroutine if string is validated to be a sane MAC address
# TODO: - merge with load_from_file subroutine as there seems to be code duplication
#       - better MAC address validation
sub load_macs {
    my $string = shift;

    my @macs = split("\n", $string);
    foreach my $mac (@macs) {
        my @elements = split(":", $mac);
        my $num_elements = @elements;
        if ( ($mac =~ /^\s*([a-fA-F0-9\:])/) && (length($mac) == 17) && ($num_elements > 1) ) {
            add_mac_to_hash($mac);
        }
    }
    regenerate_listbox();
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
    $window->Busy(-recurse => 1) if ($ENV{OSCAR_UI} eq "gui");
 
    our $uyok;
    #our $uyok_generated;

    my $cmd = "./setup_pxe -v";

    if ($uyok) {
      $cmd = "$cmd --uyok";
      #generate_uyok() if !($uyok_generated);
      generate_uyok();
    }

    oscar_log_subsection("Step $step_number: Setup network boot: $cmd");
    if ($ENV{OSCAR_UI} eq "gui") {
        !system($cmd) or (carp($!), $window->Unbusy(), return undef);
    } else {
        !system($cmd) or (carp($!), return undef);
    }

    $cmd = "../packages/kernel/scripts/fix_network_boot";
    if ( -x $cmd) {
        oscar_log_subsection("Step $step_number: Finishing network boot: $cmd");
        !system($cmd) or carp "ERROR COMMAND FAILED ($!): $cmd";
        oscar_log_subsection("Step $step_number: Successfully finished network boot");
    }

    oscar_log_subsection("Step $step_number: Successfully setup network boot");
    $window->Unbusy() if ($ENV{OSCAR_UI} eq "gui");
    return 1;
}

# A simple subrountine for running a command
sub run_cmd {
    my $cmd = shift;
    !system($cmd) or croak("Failed to run $cmd");
}

# Build AutoInstall CD
sub build_autoinstall_cd {
    my $ip = shift;
    our $uyok;
    our $kernel;
    our $ramdisk;
    our $install_mode;
    #our $uyok_generated;

    if ($uyok) {
      #generate_uyok() if ( $uyok && !($uyok_generated) );    
      generate_uyok();
    }

    my $append = "MONITOR_SERVER=$ip MONITOR_CONSOLE=yes";
    $append = "$append ramdisk_size=80000" if $uyok;
    if ($install_mode eq "systemimager-bt") {
      $append = "$append BITTORRENT=y";
    }

    my $cmd = "si_mkautoinstallcd --append \"$append\" --out-file /tmp/oscar_bootcd.iso --flavor standard";
    $cmd = "$cmd --kernel $kernel --initrd $ramdisk" if $uyok;

    oscar_log_subsection("Step $step_number: Building AutoInstall CD: $cmd");
    !system($cmd) or croak("Failed to run $cmd");
    oscar_log_subsection("Step $step_number: Successfully built AutoInstall CD");
    done_window($window,"You can now burn your ISO image to a CDROM with a command such as:\n'cdrecord -v speed=2 dev=1,0,0 /tmp/oscar_bootcd.iso'.") if ($ENV{OSCAR_UI} eq "gui");
    print "You can now burn your ISO image to a CDROM with a command such as:\n'cdrecord -v speed=2 dev=1,0,0 /tmp/oscar_bootcd.iso'.\n\n" if ($ENV{OSCAR_UI} eq "cli");
}

# Run SystemImager's si_prepareclient on the headnode to generate the UYOK
# boot kernel and ramdisk (initrd.img).  These will be stored in
# /etc/systemimager/boot
sub generate_uyok {
    our $kernel;
    our $ramdisk;
    #our $uyok_generated;

    $kernel = "/etc/systemimager/boot/kernel";
    $ramdisk = "/etc/systemimager/boot/initrd.img";

    oscar_log_subsection("Step $step_number: Running si_prepareclient on headnode to generate UYOK kernel and ramdisk");
    my $cmd = "si_prepareclient --server $ENV{HOSTNAME} --no-rsyncd --yes";
    $cmd = "$cmd --quiet" unless $ENV{OSCAR_VERBOSE};

    !system("$cmd") or croak("Failed to run: $cmd");
    #$uyok_generated = 1;
    oscar_log_subsection("Step $step_number: Successfully enabled UYOK");
}

# Configure system to use selected installation mode
sub enable_install_mode {
    our $install_mode;
    our $window;
    $window->Busy(-recurse => 1) if ($ENV{OSCAR_UI} eq "gui");

    our $os;
    my $cmd;
    my $interface = get_headnode_iface();

    my $os_detect = OSCAR::OCA::OS_Detect::open();
    my $binary_format = $os_detect->{'pkg'};

    if ($install_mode eq "systemimager-rsync") {
	    # Stop systemimager-server-flamethrowerd
	    run_cmd("/etc/init.d/systemimager-server-flamethrowerd stop");

	    # Remove systemimager-server-flamethrowerd from chkconfig
        if ($binary_format ne "deb") {
        	run_cmd("chkconfig systemimager-server-flamethrowerd off");
        } else {
            run_cmd("update-rc.d -f systemimager-server-flamethrowerd remove");
        }

	    # Stop systemimager-server-bittorrent
	    run_cmd("/etc/init.d/systemimager-server-bittorrent stop");

	    # Remove systemimager-server bittorrent from chkconfig
        if ($binary_format ne "deb") {
        	run_cmd("chkconfig systemimager-server-bittorrent off");
        } else {
            run_cmd("update-rc.d -f systemimager-server-bittorrent remove");
        }

	    # Restart systemimager-server-rsyncd
	    run_cmd("/etc/init.d/systemimager-server-rsyncd restart");

	    # Enable systemimager-server-rsyncd
        if ($binary_format ne "deb") {
        	run_cmd("chkconfig systemimager-server-rsyncd on");
        } else {
            run_cmd("update-rc.d -f systemimager-server-rsyncd start 20 2 .");
        }
    } elsif ($install_mode eq "systemimager-multicast") {
	    # Stop systemimager-server-bittorrent
	    run_cmd("/etc/init.d/systemimager-server-bittorrent stop");

	    # Remove systemimager-server-bittorrent from chkconfig
        if ($binary_format ne "deb") {
    	    run_cmd("chkconfig systemimager-server-bittorrent off");
        } else {
            run_cmd("update-rc.d -f systemimager-server-bittorrent remove");
        }

	    # Restart systemimager-server-rsyncd (needed by netbootmond and also for calculating image size in si_monitortk)
	    run_cmd("/etc/init.d/systemimager-server-rsyncd restart");

        # Backup original flamethrower.conf
        run_cmd("/bin/mv -f /etc/systemimager/flamethrower.conf /etc/systemimager/flamethrower.conf.bak");

        $cmd = "sed -e 's/START_FLAMETHROWER_DAEMON = no/START_FLAMETHROWER_DAEMON = yes/' -e 's/INTERFACE = eth[0-9][0-9]*/INTERFACE = $interface/' /etc/systemimager/flamethrower.conf.bak > /etc/systemimager/flamethrower.conf";
        if( system( $cmd ) ) {
            carp("Failed to update /etc/systemimager/flamethrower.conf");
            return 0;
        }

        # add entry for boot-<arch>-standard module
    	my $march = $os->{'arch'};
        $march =~ s/i.86/i386/;
        $cmd = "/usr/lib/systemimager/perl/confedit --file /etc/systemimager/flamethrower.conf --entry boot-$march-standard --data \" DIR=/usr/share/systemimager/boot/$march/standard/\"";
        if( system( $cmd ) ) {
            carp("Couldn't run command $cmd");
            return 1;
        }

        oscar_log_subsection("Step $step_number: Updated /etc/systemimager/flamethrower.conf");

    	# Restart systemimager-server-flamethrowerd
        run_cmd("/etc/init.d/systemimager-server-flamethrowerd restart");

	    # Add systemimager-server-flamethrowerd to chkconfig
        if ($binary_format ne "deb") {
    	    run_cmd("chkconfig systemimager-server-flamethrowerd on");
        } else {
            run_cmd("update-rc.d -f systemimager-server-flamethrowerd start 20 2 .");
        }
    } elsif ($install_mode eq "systemimager-bt") {
	    # Stop systemimager-server-flamethrowerd
	    run_cmd("/etc/init.d/systemimager-server-flamethrowerd stop");

	    # Remove systemimager-server-flamethrower from chkconfig
        if ($binary_format ne "deb") {
    	    run_cmd("chkconfig systemimager-server-flamethrowerd off");
        } else {
            run_cmd("update-rc.d -f systemimager-server-flamethrowerd remove");
        }

        # Restart systemimager-server-rsyncd (needed by netbootmond and also for calculating image size in si_monitortk)
        run_cmd("/etc/init.d/systemimager-server-rsyncd restart");

        # Backup original bittorrent.conf
        run_cmd("/bin/mv -f /etc/systemimager/bittorrent.conf /etc/systemimager/bittorrent.conf.bak");

	my @images = list_image();
	my $images_list = join(",", map { $_->name } @images);

        $cmd = "sed -e 's/BT_INTERFACE=eth[0-9][0-9]*/BT_INTERFACE=$interface/' -e 's/BT_IMAGES=.*/BT_IMAGES=$images_list/' -e 's/BT_OVERRIDES=.*/BT_OVERRIDES=$images_list/' /etc/systemimager/bittorrent.conf.bak > /etc/systemimager/bittorrent.conf";
        if( system( $cmd ) ) {
            carp("Failed to update /etc/systemimager/bittorrent.conf");
            return 0;
        }

        oscar_log_subsection("Step $step_number: Updated /etc/systemimager/bittorrent.conf");

        # Restart systemimager-server-bittorrent
        run_cmd("/etc/init.d/systemimager-server-bittorrent restart");

        # Add systemimager-server-bittorrent to chkconfig
        if ($binary_format ne "deb") {
            run_cmd("chkconfig systemimager-server-bittorrent on");
        } else {
            run_cmd("update-rc.d -f systemimager-server-bittorrent start 20 2 .");
        }
    }

    # Store installation mode in ODA
    set_install_mode($install_mode);

    oscar_log_subsection("Step $step_number: Successfully enabled installation mode: $install_mode");

    our $dhcpbutton->configure(-state => 'normal') if ($ENV{OSCAR_UI} eq "gui");
    our $dhcpbtn = 1 if ($ENV{OSCAR_UI} eq "cli");

    $window->Unbusy() if ($ENV{OSCAR_UI} eq "gui");
    return 1;
}

#Setup the cli
sub mac_cli {
    # If there is a filename here, it will be used to automate the 
    our $autofile = shift;
    $step_number = shift;
    our ($vars) = @_;
    our $auto; #True if we're going to run automatically
    
    if ($autofile ne " ") {$auto = 1;}

    chdir("$ENV{OSCAR_HOME}/scripts");

    # init this only once as we don't add network cards during this process
    @SERVERMACS = set_servermacs();

    oscar_log_section("Running step $step_number of the OSCAR wizard: Setup networking");

    our $install_mode;
    
    #Retrive the installation mode from ODA
    my $orig_install_mode = get_install_mode();
    
    $install_mode = $orig_install_mode;

    # The data structure to hold the clients and their information was VERY
    # tailor made for the GUI and impossible to use for the cli version
    # so I have to create a new one.  Here's the structure for this one
    # (so that people after me can actually use it):
    #
    # Hash of hashes
    # 
    # cli_clients => name => hostname
    #                     => mac
    #                     => ip
    #             => name => hostname ...
    our %cli_clients;
    
    #Get a list of clients
    my @clients;
    #{
        #use base qw(SIS::Component);
        @clients = sortclients list_client();
    #}
    foreach my $client (@clients) {
        my $adapter = list_adapter(client=>$client->name,devname=>"eth0");
        $cli_clients{$client->name} = {
                                       hostname => $client->hostname,
                                       mac => "",
                                       ip => $adapter->ip
                                      };
    }

    #Start printing the menu
    cli_menu($autofile);

    return 0;
}

#The interface for the cli version of the MAC setup
sub cli_menu {
    my $done = 0;
    my $infile = shift;
    our $auto;
    our $install_mode;
    our $dyndhcp = 1;
    our $uyok = 0;
    our $dhcpbtn = 0;
    our $vars;

    #Open the log file
    my $ppid = getppid();
    if (!$auto) {open(LOG, ">$ENV{OSCAR_HOME}/tmp/mac.$ppid.clilog") || print "Can't open the log for writing.\n";}
    
    #Open the file passed in for the automated version
    if($auto) {open(FILE, "$infile") || die "Can't open the input file\n";}
    
    while (!$done) {        
        print "1)  Import MACs from file\n" . 
              "2)  Installation Mode:  $install_mode\n" .
              "3)  Enable Install Mode\n" .
              "4)  Dynamic DHCP update:  " . numtostring($dyndhcp) . "\n" .
              "5)  Configure DHCP Server\n" .  
              "6)  Enable UYOK:  " . numtostring($uyok) . "\n" .
              "7)  Build AutoInstall CD\n" .
              "8)  Setup Network Boot\n" .
              "9)  Finish\n" .
              ">  " unless ($auto);
        my $response;
        if (!$auto) {
            print LOG "######################################\n" .
              "#1)  Import MACs from file\n" . 
              "#2)  Installation Mode:  $install_mode\n" .
              "#3)  Enable Install Mode\n" .
              "#4)  Dynamic DHCP update:  " . numtostring($dyndhcp) . "\n" .
              "#5)  Configure DHCP Server\n" .  
              "#6)  Enable UYOK:  " . numtostring($uyok) . "\n" .
              "#7)  Build AutoInstall CD\n" .
              "#8)  Setup Network Boot\n" .
              "#9)  Finish\n" .
              "######################################\n";
            $response = <STDIN>;
            print LOG $response;
        }
        else {
            $response = <FILE>;
            next if (response_filter($response));
        }
        chomp $response;
        if($response == 1) {
            my $result = 0;
            while (!$result) {
                if(!$auto) {
                    print "Enter filename:  ";
                    $response = <STDIN>;
                    print LOG $response;
                } else {
                    $response = <FILE>;
                    next if (response_filter($response));
                }
                chomp $response;

                if (!$response) {
                    $result = "You did not specify a filename\n";
                    print $result;
                    next;
                } elsif (!( -e $response)) {
                    $result = "File $response does not exist\n";
                    print $result;
                    next;
                }
                $result = load_from_file($response);
                assign_macs_cli();
            }
        }
        elsif($response == 2) {
            $install_mode = cli_installmode();
            oscar_log_subsection("Install mode: $install_mode");
        }
        elsif($response == 3) {
            enable_install_mode();
        }
        elsif($response == 4) {
            $dyndhcp = ++$dyndhcp%2; #Jump between 1 and 0
        }
        elsif($response == 5) {
            if($dhcpbtn) {
                setup_dhcpd($$vars{interface});
            }
            else {
                print "Need to Enable Install Mode first\n";
            }
        }
        elsif($response == 6) {
            $uyok = ++$uyok%2; #Jump between 1 and 0
        }
        elsif($response == 7) {
            my ($ip, $broadcast, $netmask) = interface2ip($$vars{interface});
            build_autoinstall_cd($ip);
        }
        elsif($response == 8) {
            run_setup_pxe();
        }
        elsif($response == 9) {
            $done = 1;
            oscar_log_subsection("Step $step_number: Completed successfully");
        }
    }

    close LOG;
}

# This will assign the MAC addresses that were read in from a file to the
# clients that have been defined.  Right now this is done only in a random
# mode.  In the future, a way to assign a specific MAC to a specific node
# will be developed.
sub assign_macs_cli {
    our %cli_clients;
    our $auto;
    
    my $notdone = 1;
    my $response;
    while ($notdone) {
        print "=====MAC Assignment Method=====\n" .
            "1)  Automatically assign MACs\n" .
            "2)  Manually assign MACs\n" .
            ">  " unless ($auto);
        $response = <STDIN> if (!$auto);
        $response = <FILE> if ($auto);
        $notdone = response_filter($response);
    }
    chomp $response;
    my @mac_keys = keys %MAC;
    
    if ($response == 1) {
        foreach my $client (keys %cli_clients) {
            if(my $mac = shift @mac_keys) {
                my $adapter = list_adapter(client=>$client,devname=>"eth0");
                $MAC{$mac}->{client} = $adapter->{ip};
                $adapter->mac($mac);
                set_adapter($adapter);
                $cli_clients{$client}->{mac} = $mac;
                oscar_log_subsection("Assigning MAC: $mac to client: " . 
                        $cli_clients{$client}->{hostname});
            } else {
                return 0;
            }
        }
    } else {
        my @client_keys = keys %cli_clients;
        my $quit = 0;
        while (!$quit) {
            my $valid = 0;
            my $mac_selection;
            while (!$valid && !$quit) {
                print "-----MAC Addresses-----\n" . join("\n",@mac_keys)."\n" .
                "Pick a MAC Address (Type quit to stop assigning)\n>  " unless ($auto);
                $mac_selection = <STDIN> if (!$auto);
                $mac_selection = <FILE> if ($auto);
                next if (response_filter($mac_selection));
                chomp $mac_selection;
                if ($mac_selection eq "quit") {
                    $quit = 1;
                    $valid = 1;
                } else {
                    foreach my $item (@mac_keys) {
                        if ($item eq $mac_selection) {
                            $valid = 1;
                            last;
                        }
                    }
                }
            }
            my $ip_selection;
            $valid = 0;
            while (!$valid && !$quit) {
                print "---------Clients-------\n" . join("\n",@client_keys) .
                "\nPick a client (Type quit to stop assigning)\n>  " unless ($auto);
                my $client_selection = <STDIN> if (!$auto);
                $client_selection = <FILE> if ($auto);
                next if (response_filter($client_selection));
                chomp $client_selection;
                if ($client_selection eq "quit") {
                    $quit = 1;
                    $valid = 1;
                } else {
                    foreach my $item (@client_keys) {
                        if ($item eq $client_selection) {
                            $valid = 1;
                            last;
                        }
                    }
                    my $adapter = list_adapter(client=>$client_selection,devname=>"eth0");
                    $MAC{$mac_selection}->{client} = $adapter->{ip};
                    $adapter->mac($mac_selection);
                    set_adapter($adapter);
                    $cli_clients{$client_selection}->{mac} = $mac_selection;
                    oscar_log_subsection("Assigning MAC: $mac_selection to client: " . $cli_clients{$client_selection}->{hostname});
                }
            }
        }
    }
}

sub cli_installmode {
    our $install_mode;
    our $auto;
    
    my $done = 0;
    while(!$done) {
        print "Currently:  $install_mode\n" .
              "Options:  " . join(" ",@install_mode_options) . "\n" .
              "New:  " unless ($auto);
        my $line = <STDIN> if (!$auto);
        $line = <FILE> if ($auto);
        next if (response_filter($line));
        chomp $line;
        foreach my $choice (@install_mode_options) {
            if($choice eq $line) {
                $done = 1;
                return $choice;
            }
        }
    }
}

sub numtostring {
    my $number = shift;
    if ($number == 0) {
        return "false";
    } else {
        return "true";
    }
}

sub response_filter {
    $_ = shift;

#print "LINE (PRECHOMP): $_";

    if ($_) {chomp ($_);}

#print "LINE (POSTCHOMP): $_";

    #Blank line
    if(!$_) {return 1;}

    #Comment
    elsif(/^#/) {return 1;}

    return 0;
}

1;

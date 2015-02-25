package OSCAR::MAC;

# Copyright (c) 2004 	The Board of Trustees of the University of Illinois.
#                     	All rights reserved.
#			            Jason Brechin <brechin@ncsa.uiuc.edu>
# Copyright (C) 2006,2007 Bernard Li <bernard@vanhpc.org>
#                         All rights reserved.
# Copyright (C) 2006-2008 Oak Ridge National Laboratory
#                         Geoffroy Vallee <valleegr@ornl.gov>
#                         All rights reserved.
# Copyright (C) 2013-2014 Commissariat a l'Enargie Atomique et aux Energies Alternatives
#                         Olivier Lahaye <olivier.lahaye@cea.fr>
#                         All rights reserved.

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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use File::Copy;
use SIS::Adapter;
use SIS::Client;
use SIS::NewDB;
use SIS::Image;
use OSCAR::Env;
use OSCAR::Utils;
use OSCAR::Network;
use OSCAR::FileUtils;

use Carp;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::Database;
use OSCAR::OCA::OS_Detect;
use OSCAR::OCA::OS_Settings;
use OSCAR::ConfigManager;
use OSCAR::SystemServices;
use OSCAR::SystemServicesDefs;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

use Data::Dumper;

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# %MAC = (
#                   'macaddr' => {client => 'clientname', order => 'order collected'}
#                 );
#                 client will be client name or undef for unassigned
#                 order will be a number

our %MAC = (); # mac will be -1 for unknown, machine name for known

our @SERVERMACS;     # a variable which stores a regex of the server mac addreses
my $ORDER = 1;      # global count variable
our $COLLECT = 0;    # are we collecting or not?
our $PINGPID = undef; # process id of the ping fork we make
our $step_number;    # which step number of the oscar process we are in

our $startcoll = "Start Collecting MACs";
our $stopcoll = "Stop Collecting MACs";

our $kernel;
our $ramdisk;
our $uyok = 0; # UYOK not enabled by default
our @install_mode_options = qw(systemimager-rsync
                              systemimager-multicast 
                              systemimager-bt);
our $install_mode = $install_mode_options[0];

@EXPORT = qw (  
                __setup_dhcpd
                __end_collect_mac
                __load_macs
                __build_autoinstall_cd
                __enable_install_mode
                __run_setup_pxe
                add_mac_to_hash
                end_ping
                generate_uyok
                get_from_file
                load_from_file
                populate_MACS
                run_cmd
                save_macs_to_file
                save_to_file
                sortclients
                start_mac_collect
                stop_mac_collect
                start_ping
                set_servermacs
                verify_mac
                %MAC
                $COLLECT
                @SERVERMACS
                @install_mode_options
                $step_number
                $startcoll
                $stopcoll
                $install_mode
             );

=encoding utf8

=head1 NAME

OSCAR::MAC - A set of usefull functions for the manipulation MAC Adresses.

=head1 SYNOPSIS

use OSCAR::MAC;

=head1 DESCRIPTION

A set of usefull functions for the manipulation of MAC Addresses.

=head2 Functions

=over 4

=cut

# Subroutines below here...

our $os = OSCAR::OCA::OS_Detect::open();
sub sortclients;

################################################################################
=item __setup_dhcpd

Setup the DHCP server configuration file.

 Input: Interface, the network interface used by the DHCP server (e.g., eth0).
Return:  0: Success
        -1: Error

Exported: YES
=cut
################################################################################

sub __setup_dhcpd ($) {
    my $interface = shift;
    our $install_mode;
    our $os;

    oscar_log(2,SUBSECTION, "Step $step_number: Setting up DHCP service.");

    if (!OSCAR::Utils::is_a_valid_string($interface)) {
        oscar_log(5,ERROR,"Network interface not defined or invalid.");
        oscar_log(2,ERROR,"Failed to setup DHCP service.");
    }

    oscar_log(5,ACTION, "Cleaning hostfile.");
    if(clean_hostsfile()) {
        oscar_log(5,ERROR,"Couldn't clean hosts file!");
        oscar_log(2,ERROR,"Failed to setup DHCP service.");
        return -1;
    }

    # Get DHCP config file and leases file.
    my $config = OSCAR::OCA::OS_Settings::getconf();
    my $dhcpd_configfile = $config->{'dhcp_configfile'};
    my $dhcpd_leases = $config->{'dhcp_leases'};

    if (defined $dhcpd_configfile) {
        oscar_log(9,INFO,"dhcp_configfile: $dhcpd_configfile"); 
    } else {
        oscar_log(5,ERROR,"dhcpd_configfile not set up for this distro. Check the configuration files in lib/OSCAR/OCA/OS_Settings/*");
        oscar_log(2,ERROR,"Failed to setup DHCP service.");
        return -1;
    }
    if (defined $dhcpd_leases) {
        oscar_log(9, INFO, "dhcp_leases: $dhcpd_leases");
    } else {
        oscar_log(5, ERROR, "dhcpd_leases not set up for this distro. Check the configuration files in lib/OSCAR/OCA/OS_Settings/*");
        oscar_log(2, ERROR, "Failed to setup DHCP service.");
        return -1;
    }

    # 1st, we backup $dhcpd_configfile. (if not done yet)
    if ( ! backup_file_if_not_exist($dhcpd_configfile)) {
#        oscar_log(5, ERROR, "Couldn't backup dhcp server config file ($dhcpd_configfile)");
        oscar_log(2, ERROR, "Failed to setup DHCP service.");
        return -1;
    }

    oscar_log(5,INFO, "Retrieving IP infos for $interface.");
    my ($ip, $broadcast, $netmask) = interface2ip($interface);
    if (OSCAR::Network::is_a_valid_ip ($ip) == 0) {
        oscar_log(5, ERROR, "Impossible to get networking data.");
        oscar_log(2, ERROR, "Failed to setup DHCP service.");
        return -1;
    }

    oscar_log(5, ACTION, "Creating dhcp config file for $interface.");
    my $cmd = "mkdhcpconf -o $dhcpd_configfile ".
                         "--interface=$interface ".
                         "--gateway=$ip ".
                         "--imageserver=oscar-server";

    if ($install_mode eq "systemimager-multicast") {
       $cmd = $cmd . " --multicast=yes";
    }

    if (oscar_system($cmd)) {
        return -1;
    }

    oscar_log(5, INFO, "Checking lease file ($dhcpd_leases).");
    if(!-f "$dhcpd_leases") {
        oscar_log(5, ACTION, "No lease file, creating it");
        open(OUT,">$dhcpd_leases")
            or (oscar_log(5, ERROR, "ERROR: Couldn't create $dhcpd_leases file."), return -1);
        close(OUT);
    }
    oscar_log(5, INFO, "DHCP lease file ready.");

    # Need to setup /etc/sysconfig/dhcpd on SUSE Linux prior to restarting dhcpd
    if ($os->{'distro'} eq "suse") {
        oscar_log(6, INFO, "Handeling SuSE specific case here: need to edit /etc/sysconfig/dhcpd");
        my $dhcpd_file = "/etc/sysconfig/dhcpd";
        # 1st, create a backup of the config file if not already done.
        backup_file_if_not_exist($dhcpd_file) or (oscar_log(2, ERROR, "Failed to setup DHCP service."), return -1);

        $cmd = "sed -i -e ".
               "'s/^DHCPD_INTERFACE=\".*\"/DHCPD_INTERFACE=\"$interface\"/g' ".
               "$dhcpd_file";
        if (oscar_system($cmd)) {
            oscar_log(5, ERROR, "Failed to update $dhcpd_file.");
            return -1;
        }
    }

    # We enable the DHCP server so it is reboot persistent.
    !enable_system_services(DHCP)
        or oscar_log(2, ERROR, "Failed to enable DHCP service.");

    # We restart the DHCP server.
    !system_service(DHCP,RESTART)
        or (oscar_log(2, ERROR, "Failed to setup DHCP service."), return -1);

    oscar_log(2, INFO, "DHCP service successfully set up for interface $interface.");
    return 0;
}

################################################################################
=item clean_hostsfile

Clean systemimager hosts file.

 Input:  None
Return:  0: Success
        -1: Error

Exported: NO
=cut
################################################################################
sub clean_hostsfile {
    my $file = "/var/lib/systemimager/scripts/hosts";
    # 1st, backup $file if not done yet.
    oscar_log(5, ACTION, "Cleaning up $file");
    backup_file_if_not_exist($file)
        or (oscar_log(5,ERROR, "Couldn't backup rsyncable hosts file! Cleanup failed."), return -1);
    open(IN,"<$file.oscarbak")
        or (oscar_log(5,ERROR,"Couldn't open $file.oscarbak for reading! Cleanup failed."), return -1);
    open(OUT,">$file")
        or (oscar_log(5,ERROR,"Couldn't open $file for writing! Cleanup failed."), return -1);
    while(<IN>) {
        if(/^\#/) {
            print OUT $_;
        } elsif(/^([\d+\.]+).*\s([^\s\.]+)\s/) {
            print OUT "$1     $2\n";
        }
    }
    close(OUT);
    close(IN);
    return 0;
}
 
################################################################################
=item sortclients

Use Schwartzian transform to sort clients by node names alphabetically and
numerically.
Names w/o numeric suffix precede those with numeric suffix.

 Input:  None
Return:  0: Success
        -1: Error

Exported: YES
=cut
################################################################################
sub sortclients(@) {
	return map { $_->[0] }
	       sort { $a->[1] cmp $b->[1] || ($a->[2]||-1) <=> ($b->[2]||-1) }
	       map { [$_, $_->{name} =~ /^([\D]+)([\d]*)$/] }
	       @_;
}

################################################################################
=item populate_MACS

Populates existing MAC entries into the global hash

 Input:  None
Return:  None

Exported: YES
=cut
################################################################################
sub populate_MACS {
    my @clients = sortclients SIS::NewDB::list_client();
    %MAC = ();
    foreach my $client (@clients) {
        my %h = (client=>$client->{name},devname=>"eth0");
        my $adapter = SIS::NewDB::list_adapter(\%h);

        oscar_log(9, INFO, "Dump for $adapter: (populate_MAC)");
        print Dumper $adapter if ($OSCAR::Env::oscar_verbose >= 9);

        if (defined ($adapter) && 
            OSCAR::Utils::is_a_valid_string(@$adapter[0]->{mac})) {
                add_mac_to_hash(@$adapter[0]->{mac}, $client->{name});
        }
    }
}

# Ok, here is the problem.  This whole thing works great on a network with
# a bunch of traffic.  It sucks on a quiet one.  So when we start up the
# tcpdump command we also fork a broadcast ping to generate more
# traffic on the network.

################################################################################
=item start_ping

Start a background broadcast ping to force traffic so arp tables gets populated.

 Input:  interface: name of oscar interface.
Return:  0: Success.
        -1: Problem.

Exported: YES
=cut
################################################################################
sub start_ping($) {
    my $interface = shift;
    end_ping();
    my ($ip, $broad, $nm) = interface2ip($interface);
    my $pid = fork();

    if( ! defined $pid ) {
        oscar_log(6, ERROR, "Fork failed.");
        oscar_log(5, ERROR, "Failed to start background broadcast ping.");
        return -1;
    }

    if($pid) {
        # In parent, we keep track of child PID so we can kill it later.
        $PINGPID = $pid;
        return 0;
    } else {
        # In child: will replace ourself with the ping command using exec.
        oscar_log(5, INFO, "Launching background ping");
        open(STDOUT,">/dev/null");
        my $cmd = "ping -b $broad";
        oscar_log(7, ACTION, "About to exec: $cmd");
        if (! exec("$cmd")) {
            # Exec failed, we're still here: need to display the error.
            my $exec_rc = $?;
            oscar_log(5, ERROR, "Failed to exec: $cmd");
            die("exec rc: $?");
        } # else: if success, we are not here anymore.
    }
}

################################################################################
=item end_ping

Stop the background broadcast ping.

 Input:  None: (ping pid is stored in global variable $PINGPID)
Return:  None.

Exported: YES
=cut
################################################################################
sub end_ping {
    if($PINGPID) {
        oscar_log(5, ACTION, "Attempting to kill ping process: $PINGPID");
        kill 15, $PINGPID;
        $PINGPID = undef;
        wait();
        oscar_log(5, INFO, "Background ping stopped");
    }
}

################################################################################
=item __end_collect_mac

Stop the background tcpdump

 Input:  tcpdump process pid.
Return:  None.

Exported: YES
=cut
################################################################################
sub __end_collect_mac($) {
    my $tcpdump_pid = shift;
    # OL: FIXME Need to keep track of PID avoiding killing
    #     tcpdumps that are not ours.
    oscar_log(6, INFO, "Attempting to stop tcpdump (pid: $tcpdump_pid)");

    if(!oscar_system("kill -TERM $tcpdump_pid")) {
        oscar_log(6, INFO, "Successfully stopped tcpdump process");
    }
}

################################################################################
=item verify_mac

Verifies a MAC address and, if possible and necessary, will reformat to match
our format requirements

 Input:  $mac: MAC address to test.
Return:        Well formed MAC address or nothing.

Exported: YES
=cut
################################################################################
sub verify_mac($) {
    my $mac = shift;
    chomp($mac);
    if ( $mac =~ /^([a-fA-f0-9]{2}:){5}[a-fA-F0-9]{2}$/ ) {
        oscar_log(6,INFO, "$mac is fully formed.");
        return $mac;
    } elsif ( $mac =~ /^[a-fA-F0-9]{12}$/ ) {
        oscar_log(6,INFO, "$mac has no colons.");
        return join(':', ( $mac =~ /(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)/ ));
    } else {
        oscar_log(5, ERROR, "$mac is not formed correctly!");
    }
    return;
}


################################################################################
=item save_to_file

Saves a list of MACs to a file in an appropriate format.

 Input:      $filename: Where to save MACs.
         @list_of_macs: Array of MAC addresses to export.
Return:               : Nothing.

Exported: YES
=cut
################################################################################
sub save_to_file ($@) {
    my $file = shift;
    my @macs = @_;
    open(OUT,">$file") or oscar_log(5, ERROR, "Couldn't open file: $file for writing");
    print OUT "# Saved OSCAR MAC Addresses\n";
    foreach my $mac ( @macs ) {
        print OUT $mac, "\n";
    }
    close(OUT);
}

################################################################################
=item save_macs_to_file

Saves $MAC has sorted by nodename as comment to a file

 Input:      $filename: Where to save MACs.
Return:              1: Success.
                     0: Failure.

Exported: YES
=cut
################################################################################
sub save_macs_to_file ($) {
    my $file = shift;

    open(OUT,">$file") or (oscar_log(5, ERROR, "Couldn't open file: $file for writing"), return 0);
    print OUT "# Saved OSCAR MAC Addresses; ", scalar localtime, "\n";
    foreach my $mac (sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC) {
        my $client = $MAC{$mac}->{client};
        print OUT $mac, "\t# $client\n";
    }
    close(OUT);
    return 1;
}

################################################################################
=item get_from_file

Loads a list of MACs from a file and returns array of macs.

 Input:      $filename: Where to read MACs from.
Return:          @macs: Array with MACs that were read successfully.
                 undef: Failure.

Exported: YES
=cut
################################################################################
sub get_from_file {
    my $file = shift;
    my @macs;
    open(IN,"<$file") or (oscar_log(5, ERROR, "Couldn't open file: $file for reading"), return undef);
    while(my $line = <IN>) {
        if($line =~ /^\s*\#/) { # Ignore comments
            next;
        }
        if( $line =~ /([0-9a-fA-F:-]+)\s*\#*/i ) {
            my $pre_mac = $1;
            chomp $pre_mac;
            if( my $mac = verify_mac($pre_mac) ) {
                push @macs, $mac;
            }
        }
    }
    close(IN);
    return @macs;
}

################################################################################
=item load_from_file

Populate the global hash MAC based on MACs from a file.

 Input:          $file: Where to read MACs from.
Return:              1: Success.
                     0: Failure.

Exported: YES
=cut
################################################################################
sub load_from_file($) {
    my $file = shift;
    my @macs = get_from_file ($file);
    my $rc=0;

    if (scalar @macs == 0) {
        oscar_log(5, ERROR, "Unable to read macs from file.");
        return 0;
    }

    foreach my $mac (@macs) {
        if (! add_mac_to_hash($mac, undef)) {
            $rc++;
        }
    }

    if( $rc == scalar @macs ) {
        oscar_log(5, ERROR, "Problem: none of the macs were added to global MACs.");
        return 0;
    } elsif ( $rc > 0 ) {
        oscar_log(5, WARNING, "Some macs were not added to global MACs.");
    }

    return 1;
}

################################################################################
=item __load_macs

Subroutine that takes MAC address string as input and pass it to the add_mac_to_hash
subroutine if string is validated to be a sane MAC address
TODO: - merge with load_from_file subroutine as there seems to be code duplication
      - better MAC address validation
      - Support infiniband MACS (20 hex numbers instead of 6 (size 59 instead of 17).)
      - Support firewire MACS

 Input:          $file: Where to read MACs from.
Return:              1: Success.

Exported: YES
=cut
################################################################################
sub __load_macs($) {
    my $string = shift;

    my @macs = split("\n", $string);
    foreach my $mac (@macs) {
        my @elements = split(":", $mac);
        my $num_elements = @elements;
        if ( ($mac =~ /^\s*([a-fA-F0-9\:])/) && (length($mac) == 17) && ($num_elements > 1) ) {
            add_mac_to_hash($mac, undef);
        }
    }
    return 1;
}

################################################################################
=item set_servermacs

Fuction call by GUI_MAC and CLI_MAC to put all server mac addresses into @SERVERMACS

 Input: None
Return: @hostmacs: Array of server MACs.

Exported: YES
=cut
################################################################################
sub set_servermacs {
    open(CMD, "/sbin/ip addr|");
    my @hostmacs = map {/link\/.[a-z]+\s+([[:xdigit:]:]+)\s+/} grep /link\//, <CMD>;
    close CMD;
    foreach (@hostmacs) {
       $_ = uc mactransform( $_ );
    }
    return @hostmacs;
}

################################################################################
=item add_mac_to_hash

Add a mac address into global $MAC hash.

 Input:      $m: The raw mac address to add.
        $client: The client name.
Return:       0: MAC not added.
              1: MAC added.

Exported: YES
=cut
################################################################################
sub add_mac_to_hash($$) {
    my ($m, $client) = @_;
    my $mac = uc mactransform( $m );
    # if the mac is 00:00:00:00:00:00, it isn't real
    if($mac =~ /^[0\:]+$/) {
        oscar_log(6, ERROR , "Ingnoring NULL MAC.");
        return 0;
    }
    # If the MAC is the server's, then get out of here
    if ( grep {$mac eq $_} @SERVERMACS ) {
        oscar_log(6, WARNING, "Skipping server MAC.");
        return 0;
    }
    # if it already has an order, then we already know about it
    if($MAC{$mac}->{order}) {
        oscar_log(6, INFO, "Ignoring $mac; (we already have it).");
        # This is fine. We have reloaded an updated MAC file with MACs we already have
        return 1;
    }
    # else, add the mac address with a null client
    my $client_msg = "";
    $client_msg = " for client $client" if (OSCAR::Utils::is_a_valid_string($client));
    oscar_log(6, INFO, "Adding $mac$client_msg to global MAC list.");
    $MAC{$mac} = {
                  client => $client,
                  order => $ORDER,
                 };
    $ORDER++;
    return 1;
}

################################################################################
=item mactransform

mactransform does a join map split trick to ensure that each octet is 2 characters

 Input: $mac: The raw mac address to add.
Return: $mac: The fixed (if needed) mac address.

Exported: NO
=cut
################################################################################
sub mactransform {
    my $mac = shift;
    my $return = uc join ':', (map {(length($_) == 1) ? "0$_" : "$_"} split (':',$mac));
    return $return;
}

################################################################################
=item __build_autoinstall_cd

Build AutoInstall CD

 Input:   $ip: IP of the client we build the image for.
        $uyok: Flag: Do we use YUOK option.
Return:  0: Success.
        -1: Failure.

Exported: YES
=cut
################################################################################
sub __build_autoinstall_cd($$) {
    my $ip = shift;
    my $uyok = shift;
    our $kernel;
    our $ramdisk;
    our $install_mode;

    if ($uyok) {
        if (generate_uyok()) {
            oscar_log(2, ERROR, "Impossible to build the autoinstall cd with YUOK");
            return -1;
        }
    }

    my $ramdisk_size = 250000;
    my $append = "MONITOR_SERVER=$ip MONITOR_CONSOLE=yes";
    $append = "$append ramdisk_size=$ramdisk_size" if $uyok;
    if ($install_mode eq "systemimager-bt") {
      $append = "$append BITTORRENT=y";
    }

    my $cmd = "si_mkautoinstallcd --append \"$append\" --out-file /tmp/oscar_bootcd.iso --flavor standard";
    $cmd = "$cmd --kernel $kernel --initrd $ramdisk" if $uyok;

    my $message = "Building AutoInstall CD";
    $message .= " with option YUOK." if($uyok);
#    oscar_log(2, SUBSECTION, "Step $step_number: Building AutoInstall CD: $cmd");
    oscar_log(2, SUBSECTION, $message);
    if (oscar_system($cmd)) {
        return -1;
    }
    oscar_log(2, INFO, "Successfully built AutoInstall CD");
    oscar_log(1, INFO, "You can now burn your ISO image to a CDROM with a command such as:\n'    cdrecord -v speed=2 dev=1,0,0 /tmp/oscar_bootcd.iso'.");
    # FIXME: cdrecord is obsolete (update message with new tool)
    # print "You can now burn your ISO image to a CDROM with a command such as:\n'cdrecord -v speed=2 dev=1,0,0 /tmp/oscar_bootcd.iso'.\n\n" if (defined $ENV{OSCAR_UI} && $ENV{OSCAR_UI} eq "cli");

    return 0;
}

################################################################################
=item generate_uyok

Run SystemImager's si_prepareclient on the headnode to generate the UYOK
boot kernel and ramdisk (initrd.img).  These will be stored in
/etc/systemimager/boot

 Input: None
Return:  0: Success.
        -1: Failure.

Exported: YES
=cut
################################################################################
sub generate_uyok {
    our $kernel;
    our $ramdisk;

    $kernel = "/etc/systemimager/boot/kernel";
    $ramdisk = "/etc/systemimager/boot/initrd.img";

    oscar_log(2, INFO, "Running si_prepareclient on headnode to generate UYOK kernel and ramdisk");
    my $hostname = $ENV{HOSTNAME};
    # WARNING, if we use the si_prepareclient command with the 
    # --np-rsyncd option option, that creates problem with UYOK
    if (!defined $hostname) {
        require Sys::Hostname;
        $hostname = Sys::Hostname::hostname ();
        if (!defined $hostname) {
            oscar_log (5, ERROR, "Failed to determine hostname. \$HOSTNAME not defined?");
            return -1;
        }
    }
    my $cmd = "si_prepareclient --server $hostname --yes";
    $cmd = "$cmd --quiet" unless ($OSCAR::Env::oscar_verbose >= 5);

    if (my $cmd_rc = oscar_system($cmd)) {
        $cmd_rc = $cmd_rc/256;
        return -1;
    }

    oscar_log(2, INFO, "Successfully enabled UYOK");

    return 0;
}

################################################################################
=item __enable_install_mode

Configure system to use selected installation mode

 Input: None
Return:  1: Success.
         0: Failure.

Exported: YES
=cut
################################################################################
sub __enable_install_mode () {
    our $install_mode;

    our $os;
    my $cmd;
    my $interface = OSCAR::Database::get_headnode_iface(undef, undef);

    my $os_detect = OSCAR::OCA::OS_Detect::open();
    my $binary_format = $os_detect->{'pkg'};

    my $script;
    my $file;
    if ($install_mode eq "systemimager-rsync") {
        # Stop systemimager-server-flamethrowerd and systemimager-server-bittorrent
        !system_service(SI_FLAMETHROWER,STOP)
            or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-flamethrowerd."), return 0);
        !system_service(SI_BITTORRENT,STOP)
            or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-bittorent."), return 0);

        # disable systemimager-server-flamethrowerd and systemimager-server-bittorrent
        !disable_system_services( (SI_FLAMETHROWER,
                                  SI_BITTORRENT) )
            or (oscar_log(5, ERROR, "Couldn't disable si_flametrhower and si_bittorrent."), return 0);

        # Restart systemimager-server-rsyncd
        !system_service(SI_RSYNC,RESTART)
            or (oscar_log(5, ERROR, "Couldn't restart systemimager-rsync."), return 0);

        # Enable systemimager-server-rsyncd
        !enable_system_services( (SI_RSYNC) )
            or (oscar_log(5, ERROR, "Couldn't enable systemimager-rsync."), return 0);

    } elsif ($install_mode eq "systemimager-multicast") {
        # Stop systemimager-server-bittorrent
        !system_service(SI_BITTORRENT,STOP)
            or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-bittorent."), return 0);

        # Disable systemimager-server-bittorrent (prevent start at boot)
        !disable_system_services( (SI_BITTORRENT) )
            or (oscar_log(5, ERROR, "Couldn't disable si_flametrhower and si_bittorrent."), return 0);

        # Restart systemimager-server-rsyncd (needed by netbootmond and also
        # for calculating image size in si_monitortk)
        !system_service(SI_RSYNC,RESTART)
            or (oscar_log(5, ERROR, "Couldn't restart systemimager-rsync."), return 0);

        # Backup original flamethrower.conf
        $file = OSCAR::OCA::OS_Settings::getitem(SI_FLAMETHROWER . "_configfile");
        if (-f $file) {
            # 1st, create a backup of the config file if not already done.
            backup_file_if_not_exist($file) or return 0;

            # 2nd, Update config (enable daemon mode, and set the net iface).
            $cmd = "sed -i -e 's/START_FLAMETHROWER_DAEMON = no/START_FLAMETHROWER_DAEMON = yes/' -e 's/INTERFACE = eth[0-9][0-9]*/INTERFACE = $interface/' $file";
            if( oscar_system( $cmd ) ) {
                oscar_log(5, ERROR, "ERROR: Failed to update $file");
                return 0;
            }

            # add entry for boot-<arch>-standard module
            my $march = $os->{'arch'};
            $march =~ s/i.86/i386/;
            $cmd = "/usr/lib/systemimager/confedit --file $file --entry boot-$march-standard --data \" DIR=/usr/share/systemimager/boot/$march/standard/\"";
            if( oscar_system( $cmd ) ) {
                return 0;
            }

            oscar_log(4, INFO, "Successfully updated $file");

            # Restart systemimager-server-flamethrowerd
            !system_service(SI_FLAMETHROWER,RESTART)
                or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-flamethrowerd."), return 0);

            # Add systemimager-server-flamethrowerd to chkconfig
            !enable_system_services( (SI_FLAMETHROWER) )
                or (oscar_log(5, ERROR, "Couldn't disable si_flametrhower and si_bittorrent."), return 0);
        }
    } elsif ($install_mode eq "systemimager-bt") {
        # Stop systemimager-server-flamethrowerd
        !system_service(SI_FLAMETHROWER,STOP)
            or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-flamethrowerd."), return 0);

        # Remove systemimager-server-flamethrower from chkconfig
        !disable_system_services( (SI_FLAMETHROWER) )
            or (oscar_log(5, ERROR, "Couldn't disable si_flametrhower and si_bittorrent."), return 0);

        # Restart systemimager-server-rsyncd (needed by netbootmond and also for calculating image size in si_monitortk)
        !system_service(SI_RSYNC,RESTART)
            or (oscar_log(5, ERROR, "Couldn't restart systemimager-rsync."), return 0);

        # Backup original bittorrent.conf
        $file = OSCAR::OCA::OS_Settings::getitem(SI_BITTORRENT . "_configfile");
        if (-f $file) {
            # 1st, create a backup of the config file if not already done.
            backup_file_if_not_exist($file) or return 0;

            my @images = list_image();
            # FIXME: Check @images is defined.

            my $images_list = join(",", map { $_->name } @images);

            # 2nd, set the net interface to use.
            $cmd = "sed -i -e 's/BT_INTERFACE=eth[0-9][0-9]*/BT_INTERFACE=$interface/' -e 's/BT_IMAGES=.*/BT_IMAGES=$images_list/' -e 's/BT_OVERRIDES=.*/BT_OVERRIDES=$images_list/' $file";
            if( oscar_system( $cmd ) ) {
                oscar_log(5, ERROR, "Failed to update $file");
                return 0;
            }

            oscar_log(4, INFO, "Successfully updated $file");

            # Restart systemimager-server-bittorrent
            !system_service(SI_BITTORRENT,RESTART)
                or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-bittorent."), return 0);

            # Add systemimager-server-bittorrent to chkconfig
            !enable_system_services( (SI_BITTORRENT) )
                or (oscar_log(5, ERROR, "Couldn't disable si_flametrhower and si_bittorrent."), return 0);
        }
    }

    # Store installation mode in ODA
    OSCAR::Database::set_install_mode($install_mode, undef, undef);
    # FIXME: Check return code.

    oscar_log(2, INFO, "Successfully enabled installation mode: $install_mode");

    return 1;
}

################################################################################
=item __run_setup_pxe

Execute the setup_pxe script.

 Input: $uyok: do we need to use the "Use Your Own Kernel" SIS feature or not?
               0 => No, anything else => yes.
Return:  0: Success.
        -1: Failure.

Exported: YES
=cut
################################################################################
sub __run_setup_pxe ($) {
    my $uyok = shift;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        return undef;
    }
    my $config = $oscar_configurator->get_config();
    my $bin_path = $config->{'binaries_path'};

    my $cmd = "$bin_path/setup_pxe";
    if ($OSCAR::Env::oscar_verbose >= 5) {
        $cmd = "$cmd -v";
    }

    if ($uyok) {
        $cmd = "$cmd --uyok";
        if (generate_uyok()) {
            oscar_log(5, ERROR, "Impossible to setup PXE with YUOK");
            return -1
        }
    }

    oscar_log(2, INFO, "Setup network boot (PXE)");
    !oscar_system($cmd) or return -1;

    $cmd = "../packages/kernel/scripts/fix_network_boot";
    if ( -x $cmd) {
#        oscar_log_subsection("Step $step_number: Finishing network boot: $cmd");
        oscar_log(2, INFO, "Finishing network boot (PXE).");
        !oscar_system($cmd) or (oscar_log(5, ERROR, "Failed to fix network boot ($!)"), return -1);
        oscar_log(2, INFO, "Successfully finished network boot (PXE).");
    }

    oscar_log(2, INFO, "Successfully setup network boot (PXE).");
    return 0;
}

=back

=head1 AUTHORS

=over 4

=item Main coding:

    (c) 2004      Jason Brechin <brechin@ncsa.uiuc.edu>
                  The Board of Trustees of the University of Illinois.
                  All rights reserved.
    (c) 2006-2007 Bernard Li <bernard@vanhpc.org>
                  All rights reserved.
    (c) 2006-2008 Geoffroy Vallee <valleegr@ornl.gov>
                  Oak Ridge National Laboratory
                  All rights reserved.

=item Fixed, enhanced and documented by:

    (c) 2013-2014 Olivier Lahaye C<< <olivier.lahaye@cea.fr> >>
                  CEA (Commissariat A l'Energie Atomique)
                  All rights reserved

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

1;

__END__

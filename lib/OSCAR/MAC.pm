package OSCAR::MAC;

# Copyright (c) 2004 	The Board of Trustees of the University of Illinois.
#                     	All rights reserved.
#			Jason Brechin <brechin@ncsa.uiuc.edu>
# Copyright (C) 2006,2007 Bernard Li <bernard@vanhpc.org>
#                    All rights reserved.
# Copyright (C) 2006-2008 Oak Ridge National Laboratory
#                         Geoffroy Vallee <valleegr@ornl.gov>
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

use lib "/usr/lib/systeminstaller";
use strict;
use File::Copy;
use SIS::Adapter;
use SIS::Client;
use SIS::NewDB;
use SIS::Image;
use OSCAR::Network;

use Carp;
use OSCAR::Logger;
use OSCAR::Database;
use OSCAR::OCA::OS_Detect;
use OSCAR::ConfigManager;
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

# Subroutines below here...

our $os = OSCAR::OCA::OS_Detect::open();
sub sortclients;

# Setup the DHCP server configuration file.
#
# Input: interface, the network interface used by the DHCP server (e.g., eth0).
# Return: 0 if success, -1 else.
sub __setup_dhcpd ($) {
    my $interface = shift;
    our $install_mode;
    our $os;

    oscar_log_subsection("Step $step_number: cleaning hostfile");
    clean_hostsfile() 
        or (carp "ERROR: Couldn't clean hosts file!", return -1);

    my $dhcpd_configfile = "/etc/dhcpd.conf";
    # Under RHEL6 like, the dhcpd config file is in /etc/dhcp
    $dhcpd_configfile = "/etc/dhcp/dhcpd.conf" if -x "/etc/dhcp";
    # Under Debian the dhcpd config file is in /etc/dhcp3
    $dhcpd_configfile = "/etc/dhcp3/dhcpd.conf" if -x "/etc/dhcp3";
    oscar_log_subsection ("Step $step_number: About to run setup_dhcpd...");
    if(-e $dhcpd_configfile) {
        copy($dhcpd_configfile, $dhcpd_configfile.".oscarbak") 
            or (carp "ERROR: Couldn't backup dhcpd.conf file", return -1);
    }
    my ($ip, $broadcast, $netmask) = interface2ip($interface);
    if (!defined $interface || OSCAR::Network::is_a_valid_ip ($ip) == 0) {
        carp "ERROR: Impossible to get networking data";
        return -1;
    }
    my $cmd = "mkdhcpconf -o $dhcpd_configfile ".
                         "--interface=$interface ".
                         "--gateway=$ip";

    if ($install_mode eq "systemimager-multicast"){
       $cmd = $cmd . " --multicast=yes";
    }

    oscar_log_subsection("Step $step_number: Running command: $cmd");
    if (system($cmd)) {
        carp "ERROR: Couldn't mkdhcpconf ($cmd)\n";
        return -1;
    }
    oscar_log_subsection("Step $step_number: Successfully ran \"$cmd\"");

    oscar_log_subsection("Step $step_number: Checking the DHCP lease file");
    # The DHCP lease can be in different places, depending on the distro, 
    # we detect where
    my $dhcpd_leases;
    if ( -d "/var/lib/dhcp3" ) {
        $dhcpd_leases = "/var/lib/dhcp3/dhcpd.leases";
    } elsif ( -d "/var/lib/dhcp" ) {
        $dhcpd_leases = "/var/lib/dhcp/dhcpd.leases";
    } elsif ( -d "/var/lib/dhcpd" ) {
        $dhcpd_leases = "/var/lib/dhcpd/dhcpd.leases";
    } else {
        carp "ERROR: Impossible to detect where the DHCP lease is stored.";
        return -1;
    }

    if(!-f "$dhcpd_leases") {
        oscar_log_subsection("Step $step_number: Creating $dhcpd_leases");
        open(OUT,">$dhcpd_leases")
            or (carp "ERROR: Couldn't create $dhcpd_leases files.", return -1);
        close(OUT);
    }
    oscar_log_subsection("Step $step_number: DHCP lease file ready");

    # Need to setup /etc/sysconfig/dhcpd on SUSE Linux prior to restarting dhcpd
    if ($os->{'distro'} eq "suse") {
        my $dhcpd_file = "/etc/sysconfig/dhcpd";
        run_cmd("/bin/mv -f $dhcpd_file $dhcpd_file.oscarbak");

        $cmd = "sed -e ".
               "'s/^DHCPD_INTERFACE=\".*\"/DHCPD_INTERFACE=\"$interface\"/g' ".
               "$dhcpd_file.oscarbak > $dhcpd_file";
        if (system($cmd)) {
            carp("ERROR: Failed to update $dhcpd_file.\n");
            return -1;
        }
    }

    # We get the path to the DHCP server and restart it.
    my $dhcpdpath = OSCAR::OCA::OS_Settings::getitem ("dhcp_daemon");
    oscar_log_subsection("Step $step_number: Restarting dhcpd service");
    !system("$dhcpdpath restart")
        or (carp "ERROR: Couldn't restart $dhcpdpath.\n", return -1);
    oscar_log_subsection("Step $step_number: Successfully restarted dhcpd ".
                         "service");

    return 0;
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
	       map { [$_, $_->{name} =~ /^([\D]+)([\d]*)$/] }
	       @_;
}

# populates existing MAC entries into the global hash

sub populate_MACS {
    my @clients = sortclients SIS::NewDB::list_client();
    %MAC = ();
    foreach my $client (@clients) {
        my %h = (client=>$client->{name},devname=>"eth0");
        my $adapter = SIS::NewDB::list_adapter(\%h);
        print Dumper $adapter;
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

sub __end_collect_mac {
    system("killall tcpdump");
}

# verify_mac - Verifies a MAC address and, if possible and necessary, will 
#          reformat to match our format requirements
# Args:  $mac, ($debug=0)
# Returns formatted MAC address or nothing
sub verify_mac {
    my $mac = shift;
    chomp($mac);
    my $debug = shift;
    if ( $mac =~ /^([a-fA-f0-9]{2}:){5}[a-fA-F0-9]{2}$/ ) {
        if ( $debug ) { print "$mac is fully formed\n"; }
        return $mac;
    } elsif ( $mac =~ /^[a-fA-F0-9]{12}$/ ) {
        if ( $debug ) { print "$mac has no colons \n"; }
        return join(':', ( $mac =~ /(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)/ ));
    } else {
        warn ( "$mac is not formed correctly!\n" );
    }
    return;
}


# save_to_file - Saves a list of MACs to a file in an appropriate format
# Args:  $filename, @list_of_macs
# Returns nothing
sub save_to_file ($@) {
    my $file = shift;
    my @macs = @_;
    open(OUT,">$file") or croak "Couldn't open file: $file for writing";
    print OUT "# Saved OSCAR MAC Addresses\n";
    foreach my $mac ( @macs ) {
        print OUT $mac, "\n";
    }
    close(OUT);
}

sub save_macs_to_file ($) {
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

# Loads a list of MACs from a file and returns array of macs
# Args:  $filename
# Returns array of loaded MACs that pass verification
sub get_from_file {
    my $file = shift;
    my @macs;
    open(IN,"<$file") or croak "Couldn't open file: $file for reading";
    while(<IN>) {
        if(/^\s*\#/) {
            next;
        }
        if( my $mac = verify_mac($_) ) {
            push @macs, $mac;
        }
    }
    close(IN);
    return @macs;
}

# Populate the global hash MAC based on MACs from a file.
#
# Input: File path from which the MACs need to be read.
# Return: 1 if success, 0 else.
sub load_from_file {
    my $file = shift;
    my @macs = get_from_file ($file);

    foreach my $mac (@macs) {
        add_mac_to_hash($mac);
    }

    return 1;
}

# Subroutine that takes MAC address string as input and pass it to the add_mac_to_hash
# subroutine if string is validated to be a sane MAC address
# TODO: - merge with load_from_file subroutine as there seems to be code duplication
#       - better MAC address validation
sub __load_macs {
    my $string = shift;

    my @macs = split("\n", $string);
    foreach my $mac (@macs) {
        my @elements = split(":", $mac);
        my $num_elements = @elements;
        if ( ($mac =~ /^\s*([a-fA-F0-9\:])/) && (length($mac) == 17) && ($num_elements > 1) ) {
            add_mac_to_hash($mac);
        }
    }
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

# Build AutoInstall CD
#
# Return: 0 if success, -1 else.
sub __build_autoinstall_cd {
    my $ip = shift;
    my $uyok = shift;
    our $kernel;
    our $ramdisk;
    our $install_mode;

    if ($uyok) {
        if (generate_uyok()) {
            carp "ERROR: Impossible to build the autoinstall cd with YUOK";
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

    oscar_log_subsection("Step $step_number: Building AutoInstall CD: $cmd");
    if (system($cmd)) {
        carp ("ERROR: Failed to run $cmd");
        return -1;
    }
    oscar_log_subsection("Step $step_number: Successfully built AutoInstall CD");
    print "You can now burn your ISO image to a CDROM with a command such as:\n'cdrecord -v speed=2 dev=1,0,0 /tmp/oscar_bootcd.iso'.\n\n" if (defined $ENV{OSCAR_UI} && $ENV{OSCAR_UI} eq "cli");

    return 0;
}

# Run SystemImager's si_prepareclient on the headnode to generate the UYOK
# boot kernel and ramdisk (initrd.img).  These will be stored in
# /etc/systemimager/boot
#
# Return: 0 if success, -1 else.
sub generate_uyok {
    our $kernel;
    our $ramdisk;

    $kernel = "/etc/systemimager/boot/kernel";
    $ramdisk = "/etc/systemimager/boot/initrd.img";

    oscar_log_subsection("Step $step_number: Running si_prepareclient on headnode to generate UYOK kernel and ramdisk");
    my $hostname = $ENV{HOSTNAME};
    # WARNING, if we use the si_prepareclient command with the 
    # --np-rsyncd option option, that creates problem with UYOK
    if (!defined $hostname) {
        require Sys::Hostname;
        $hostname = Sys::Hostname::hostname ();
        if (!defined $hostname) {
            carp "ERROR: HOSTNAME env variable not defined";
            return -1;
        }
    }
    my $cmd = "si_prepareclient --server $hostname --yes";
    $cmd = "$cmd --quiet" unless $ENV{OSCAR_VERBOSE};

    if (system($cmd)) {
        carp ("ERROR: Failed to run: $cmd");
        return -1;
    }

    oscar_log_subsection("Step $step_number: Successfully enabled UYOK");

    return 0;
}

# Configure system to use selected installation mode
# TODO: We should use an abstraction to manage the service this code is just ugly.
#
# Return: 1 if success, 0 else.
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
        # Stop systemimager-server-flamethrowerd
        $script = "/etc/init.d/systemimager-server-flamethrowerd";
	if (-f $script) {
            $cmd = "$script stop";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }

            # Remove systemimager-server-flamethrowerd from chkconfig
            if ($binary_format ne "deb") {
                $cmd = "/sbin/chkconfig systemimager-server-flamethrowerd off";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            } else {
                $cmd = "update-rc.d -f systemimager-server-flamethrowerd remove";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            }
        }

        # Stop systemimager-server-bittorrent if bittorrent is installed.
        $script = "/etc/init.d/systemimager-server-bittorrent";
        if (-f $script) {
            $cmd = "$script stop";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }

            # Remove systemimager-server bittorrent from chkconfig
            if ($binary_format ne "deb") {
                $cmd = "/sbin/chkconfig systemimager-server-bittorrent off";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            } else {
                $cmd = "update-rc.d -f systemimager-server-bittorrent remove";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            }
        }

        # Restart systemimager-server-rsyncd
        $cmd = "/etc/init.d/systemimager-server-rsyncd restart";
        if (system ($cmd)) {
            carp "ERROR: Impossible to execute $cmd";
            return 0;
        }

        # Enable systemimager-server-rsyncd
        if ($binary_format ne "deb") {
            $cmd = "/sbin/chkconfig systemimager-server-rsyncd on";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }
        } else {
            $cmd = "update-rc.d -f systemimager-server-rsyncd start 20 2 .";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }
        }
    } elsif ($install_mode eq "systemimager-multicast") {
        # Stop systemimager-server-bittorrent
        $script = "/etc/init.d/systemimager-server-bittorrent";
        if (-f $script) {
            $cmd = "$script stop";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }
        }

        # Remove systemimager-server-bittorrent from chkconfig
        if ($binary_format ne "deb") {
            $cmd = "/sbin/chkconfig systemimager-server-bittorrent off";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }
        } else {
            $cmd = "update-rc.d -f systemimager-server-bittorrent remove";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }
        }

        # Restart systemimager-server-rsyncd (needed by netbootmond and also
        # for calculating image size in si_monitortk)
        $cmd = "/etc/init.d/systemimager-server-rsyncd restart";
        if (system ($cmd)) {
            carp "ERROR: Impossible to execute $cmd";
            return 0;
        }

        # Backup original flamethrower.conf
        $file = "/etc/systemimager/flamethrower.conf";
        $script = "/etc/init.d/systemimager-server-flamethrowerd";
        if (-f $file) {
            $cmd = "/bin/mv -f $file $file.bak";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }

            $cmd = "sed -e 's/START_FLAMETHROWER_DAEMON = no/START_FLAMETHROWER_DAEMON = yes/' -e 's/INTERFACE = eth[0-9][0-9]*/INTERFACE = $interface/' $file.bak > $file";
            if( system( $cmd ) ) {
                carp("ERROR: Failed to update $file");
                return 0;
            }

            # add entry for boot-<arch>-standard module
            my $march = $os->{'arch'};
            $march =~ s/i.86/i386/;
            $cmd = "/usr/lib/systemimager/perl/confedit --file $file --entry boot-$march-standard --data \" DIR=/usr/share/systemimager/boot/$march/standard/\"";
            if( system( $cmd ) ) {
                carp("ERROR: Couldn't run command $cmd");
                return 0;
            }

            oscar_log_subsection("Step $step_number: Updated $file");

            # Restart systemimager-server-flamethrowerd
            $cmd = "$script restart";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }

            # Add systemimager-server-flamethrowerd to chkconfig
            if ($binary_format ne "deb") {
                $cmd = "/sbin/chkconfig systemimager-server-flamethrowerd on";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            } else {
                $cmd = "update-rc.d -f systemimager-server-flamethrowerd start 20 2 .";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            }
        }
    } elsif ($install_mode eq "systemimager-bt") {
        # Stop systemimager-server-flamethrowerd
        $script = "/etc/init.d/systemimager-server-flamethrowerd";
        if (-f $script) {
            $cmd = "$script stop";
            if (system ($cmd)) {
                carp "ERROR: Impossibel to execute $cmd";
                return 0;
            }

            # Remove systemimager-server-flamethrower from chkconfig
            if ($binary_format ne "deb") {
                $cmd = "/sbin/chkconfig systemimager-server-flamethrowerd off";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            } else {
                $cmd = "update-rc.d -f systemimager-server-flamethrowerd remove";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            }
        }

        # Restart systemimager-server-rsyncd (needed by netbootmond and also for calculating image size in si_monitortk)
        $cmd = "/etc/init.d/systemimager-server-rsyncd restart";
        if (system ($cmd)) {
            carp "ERROR: Impossible to execute $cmd";
            return 0;
        }

        # Backup original bittorrent.conf
        $file = "/etc/systemimager/bittorrent.conf";
        if (-f $file) {
            $cmd = "/bin/mv -f $file $file.bak";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }

            my @images = list_image();
            my $images_list = join(",", map { $_->name } @images);

            $cmd = "sed -e 's/BT_INTERFACE=eth[0-9][0-9]*/BT_INTERFACE=$interface/' -e 's/BT_IMAGES=.*/BT_IMAGES=$images_list/' -e 's/BT_OVERRIDES=.*/BT_OVERRIDES=$images_list/' $file.bak > $file";
            if( system( $cmd ) ) {
                carp("ERROR: Failed to update $file");
                return 0;
            }

            oscar_log_subsection("Step $step_number: Updated $file");

            # Restart systemimager-server-bittorrent
            $cmd = "/etc/init.d/systemimager-server-bittorrent restart";
            if (system ($cmd)) {
                carp "ERROR: Impossible to execute $cmd";
                return 0;
            }

            # Add systemimager-server-bittorrent to chkconfig
            if ($binary_format ne "deb") {
                $cmd = "/sbin/chkconfig systemimager-server-bittorrent on";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            } else {
                $cmd = "update-rc.d -f systemimager-server-bittorrent start 20 2 .";
                if (system ($cmd)) {
                    carp "ERROR: Impossible to execute $cmd";
                    return 0;
                }
            }
        }
    }

    # Store installation mode in ODA
    OSCAR::Database::set_install_mode($install_mode, undef, undef);

    oscar_log_subsection("Step $step_number: Successfully enabled installation mode: $install_mode");

    return 1;
}

# Execute the setup_pxe script.
#
# Input: uyok, do we need to use the "Use Your Own Kernel" SIS feature or not?
#              0 => No, anything else => yes.s
# Return: 0 if success, -1 else.
sub __run_setup_pxe ($) {
    my $uyok = shift;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return undef;
    }
    my $config = $oscar_configurator->get_config();
    my $bin_path = $config->{binaries_path};

    my $cmd = "$bin_path/setup_pxe";
    if ($ENV{OSCAR_VERBOSE}) {
        $cmd = "$cmd -v";
    }

    if ($uyok) {
        $cmd = "$cmd --uyok";
        if (generate_uyok()) {
            carp "ERROR: Impossible to setup PXE with YUOK";
            return -1
        }
    }

    oscar_log_subsection("Step $step_number: Setup network boot: $cmd");
    !system($cmd) or (carp("ERROR: ".$!), return -1);

    $cmd = "../packages/kernel/scripts/fix_network_boot";
    if ( -x $cmd) {
        oscar_log_subsection("Step $step_number: Finishing network boot: $cmd");
        !system($cmd) or (carp "ERROR COMMAND FAILED ($!): $cmd", return -1);
        oscar_log_subsection("Step $step_number: Successfully finished network boot");
    }

    oscar_log_subsection("Step $step_number: Successfully setup network boot");
    return 0;
}

1;

__END__


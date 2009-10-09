package OSCAR::CLI_MAC;

# Copyright (c) 2004    The Board of Trustees of the University of Illinois.
#                       All rights reserved.
#           Jason Brechin <brechin@ncsa.uiuc.edu>
# Copyright (c) 2006, 2007 Bernard Li <bernard@vanhpc.org>
#                          All rights reserved.
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

# Description: this is the CLI code for setup networking, especially
# related to MAC addresses. The library code is in lib/OSCAR/MAC.pm

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use lib "/usr/lib/systeminstaller";
use SIS::NewDB;
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

@EXPORT = qw (  mac_cli  );

# Setup the cli
#
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

    #Retrive the installation mode from ODA
    my $orig_install_mode = OSCAR::Database::get_install_mode(undef, undef);

    $install_mode = $orig_install_mode;

    #Start printing the menu
    cli_menu($autofile);

    return 0;
}


#The interface for the cli version of the MAC setup
sub cli_menu {
    my $done = 0;
    my $infile = shift;
    my $dhcpbtn = 0;
    our $auto;
    our $dyndhcp = 1;
    our $uyok = 0;
    our $vars;

    #Open the log file
    my $ppid = getppid();
    if (!$auto) {open(LOG, ">$ENV{OSCAR_HOME}/tmp/mac.$ppid.clilog") || print "Can't open the
log for writing.\n";}

    #Open the file passed in for the automated version
    if($auto) {open(FILE, "$infile") || die "Can't open the input file\n";}

    while (!$done) {
        # For now, default interface is eth0
        my $iface = "eth0";
        populate_MACS();
        my @clients = sortclients list_client();
        print "Current client assignments:\n";
        if (@clients) {
            foreach my $client (@clients) {
                my $nodename = $client->name;
                my %h = (client=>$nodename, devname=>"$iface");
                my $adapter = list_adapter(\%h);
                my $mac = $adapter->mac || "  :  :  :  :  :  ";
                my $ip = $adapter->ip;
                print "\t$nodename ($iface) [$ip] <$mac>\n";
            }
        } else {
            print "\tNo clients defined.\n";
        }
        print "\n";

        $install_mode = $install_mode_options[0] if !defined $install_mode;
        print "1)  Import MACs from file\n" .
              "2)  Delete MACs\n" .
              "3)  Installation Mode:  $install_mode\n" .
              "4)  Enable Install Mode\n" .
              "5)  Dynamic DHCP update:  " . numtostring($dyndhcp) . "\n" .
              "6)  Configure DHCP Server\n" .
              "7)  Enable UYOK:  " . numtostring($uyok) . "\n" .
              "8)  Build AutoInstall CD\n" .
              "9)  Setup Network Boot\n" .
              "10) Finish\n" .
              ">  " unless ($auto);
        my $response;
        if (!$auto) {
            print LOG "######################################\n" .
              "#1)  Import MACs from file\n" .
              "#2)  Delete MACs\n" .
              "#3)  Installation Mode:  $install_mode\n" .
              "#4)  Enable Install Mode\n" .
              "#5)  Dynamic DHCP update:  " . numtostring($dyndhcp) . "\n" .
              "#6)  Configure DHCP Server\n" .
              "#7)  Enable UYOK:  " . numtostring($uyok) . "\n" .
              "#8)  Build AutoInstall CD\n" .
              "#9)  Setup Network Boot\n" .
              "#10) Finish\n" .
              "######################################\n";
            $response = <STDIN>;
            print LOG $response;
        }
        else {
            $response = <FILE>;
            next if (response_filter($response));
        }

        # If response is "return", loop
        if ($response eq "\n") {
            next;
        }

        chomp $response;
        if($response eq "1") {
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
                assign_macs_cli($dyndhcp);
            }
        }
        elsif($response eq "2") {
            delete_macs_cli();
        }
        elsif($response eq "3") {
            $install_mode = cli_installmode();
            oscar_log_subsection("Install mode: $install_mode");
        }
        elsif($response eq "4") {
            __enable_install_mode();
            $dhcpbtn = 1;
        }
        elsif($response eq "5") {
            $dyndhcp = ++$dyndhcp%2; #Jump between 1 and 0
        }
        elsif($response eq "6") {
            if($dhcpbtn) {
                __setup_dhcpd($$vars{interface});
            }
            else {
                print "Need to Enable Install Mode first\n";
            }
        }
        elsif($response eq "7") {
            $uyok = ++$uyok%2; #Jump between 1 and 0
         }
        elsif($response eq "8") {
            my ($ip, $broadcast, $netmask) = interface2ip($$vars{interface});
            __build_autoinstall_cd($ip);
        }
        elsif($response eq "9") {
            __run_setup_pxe($uyok);
        }
        elsif($response eq "10") {
            $done = 1;
            oscar_log_subsection("Step $step_number: Completed successfully");
        }
    }

    close LOG;
}


# This will assign the MAC addresses that were read in from a file to the
# clients that have been defined.  This is done sequentially (top to bottom)
# according to the file.
sub assign_macs_cli {
    my @clients = sortclients list_client();
    our $auto;
    my $dyndhcp = shift;
    my $notdone = 1;
    my $response;

    # If MAC is already assigned to a client, remove it from the hash
    foreach my $mac (keys %MAC) {
        if ($MAC{$mac}->{client}) {
            delete $MAC{$mac};
        }
    }

    if (!%MAC) {
        print "There are no unassigned MACs.\n";
        $notdone = 0;
        return;
    }

    LOOP:
    while ($notdone) {
        print "=====MAC Assignment Method=====\n" .
            "1)  Automatically assign MACs\n" .
            "2)  Manually assign MACs\n" .
            "3)  Return to previous menu\n" .
            ">  " unless ($auto);
        $response = <STDIN> if (!$auto);
        $response = <FILE> if ($auto);
        $notdone = response_filter($response);
    }
    chomp $response;
    my @mac_keys = sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC;
    my $iface = "eth0";

    if ($response eq "1") {
        while (my $mac = shift @mac_keys) {
            foreach my $client (@clients) {
                my %h = (client=>$client->name,devname=>"$iface");
                my $adapter = list_adapter(\%h);
                # Assign only if client has no assignment
                if (!$adapter->mac && !$MAC{$mac}->{client}) {
                    oscar_log_subsection("Assigning MAC: $mac to client: " .
                        $client->name);
                    $adapter->mac($mac);
                    set_adapter($adapter);
                    $MAC{$mac}->{client}=$client->name;
                    add_mac_to_hash($mac, $client->name);
                }
            }
        }
    } elsif ($response eq "2") {
        my $quit = 0;
        while (!$quit) {
            my $valid = 0;
            my $mac_selection;
            while (!$valid && !$quit) {
                @mac_keys = sort {$MAC{$a}->{order} <=> $MAC{$b}->{order}} keys %MAC;
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
                print "---------Clients-------\n" . join("\n", map { $_->name } @clients) .
                "\nPick a client (Type quit to stop assigning)\n>  " unless ($auto);
                my $client_selection = <STDIN> if (!$auto);
                $client_selection = <FILE> if ($auto);
                next if (response_filter($client_selection));
                chomp $client_selection;
                if ($client_selection eq "quit") {
                    $quit = 1;
                    $valid = 1;
                } else {
                    foreach my $item (@clients) {
                        if ($item->name eq $client_selection) {
                            $valid = 1;
                            last;
                        }
                    }
                    oscar_log_subsection("Assigning MAC: $mac_selection to client: " . $client_selection);
                    my %h = (client=>$client_selection,devname=>"eth0");
                    my $adapter = list_adapter(\%h);
                    # If client selection has a MAC address assigned, bump it back out to the
                    # global hash
                    if ($adapter->mac) {
                        add_mac_to_hash($adapter->mac);
                    }
                    $adapter->mac($mac_selection);
                    set_adapter($adapter);
                    delete $MAC{$mac_selection};
                }
            }
        }
    } elsif ($response eq "3") {
        return 0;
    } else {
       goto LOOP;
    }

    # Rebuild dhcpd.conf
    if ($dyndhcp) {
      our $vars;
      __setup_dhcpd($$vars{interface});
    }

}

sub delete_macs_cli {
    print "Not implemented yet.\n";
}

sub cli_installmode {
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

#####################
# PRIVATE FUNCTIONS #
#####################

sub numtostring {
    my $number = shift;
    if ($number == 0) {
        return "false";
    } else {
        return "true";
    }
}

1;

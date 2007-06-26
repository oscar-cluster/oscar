#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";
use POSIX;

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = SUCCESS;

$ENV{LANG}="C";

# We check if the hostname is valid, i.e. does not return localhost or
# something similar. We also check if the host name is assigned to the
# loopback interface or not.
# @return: FAILURE if a problem is detected, SUCCESS else.
sub check_hostname {
    my $hostname = (uname)[1];
    if ($hostname eq "") {
        print " ---------------------------------------\n";
        print " ERROR: Localhost name seems to be empty\n";
        print " ---------------------------------------\n";
        return FAILURE;
    }
    my ($shorthostname) = split(/\./,$hostname,2);
    if ($shorthostname eq "") {
        print " --------------------------------------\n";
        print " ERROR: shorthostname seems to be empty\n";
        print " --------------------------------------\n";
        return FAILURE;
    }
    my $dnsdomainname = `dnsdomainname`;
    chomp ($dnsdomainname);
    if ($shorthostname eq "localhost") {
       return FAILURE;
    }
    if ($hostname eq "localhost.localdomain") {
       return FAILURE;
    }

    # the value of hostname should not to be assigned to the loopback
    # interface
    my $hostname_ip = `grep $shorthostname /etc/hosts | awk ' { print \$1 } '`;
    chomp ($hostname_ip);
    if ($hostname_ip eq "127.0.0.1") {
        print " -------------------------------------------------\n";
        print " ERROR: your hostname is assigned to the loopback \n";
        print " interface\n";
        print " Please assign it to your public network interface\n";
        print " updating /etc/hosts\n";
        print " -------------------------------------------------\n";
        return FAILURE;
    }
    
    return SUCCESS;
}

# Check the configuration of the interface used by OSCAR
# @return: FAILURE if a problem is detected, SUCCESS else.
sub check_oscar_interface {
    my $oscar_if = $ENV{OSCAR_HEAD_INTERNAL_INTERFACE};
    my %nics;
    open IN, "/sbin/ifconfig |" || die "ERROR: Unable to query NICs\n";
    while( <IN> ) {
        next if /^\s/ || /^lo\W/;
        chomp;
        s/\s.*$//;
        $nics{$_} = 1;
    }
    close IN;

    if (! ($oscar_if && exists $nics{$oscar_if}) ) {
	if ($oscar_if eq "") {
            $oscar_if = "<None>";
        }
        print " ----------------------------------------------------\n";
        print " ERROR: A valid NIC must be specified for the cluster\n";
        print " private network.\n";
        print " Valid NICs: ".join( ", ", sort keys %nics )."\n\n";
        print " You tried to use: " . $oscar_if . ".\n";
        print " ----------------------------------------------------\n";
        return FAILURE;
    }

    # we check now the IP assgned to the interface used by OSCAR
    my $oscar_ip = `grep oscar_server /etc/hosts | awk ' { print \$1 } '`;
    chomp ($oscar_ip);
    my $oscar_if_ip = `env LC_ALL=C /sbin/ifconfig $oscar_if | grep "inet addr:" | awk '{ print \$2 }' | sed -e 's/addr://'`;
    chomp ($oscar_if_ip);
    # the first time we execute OSCAR, /etc/hosts is not updated, it is 
    # normal
    if ($oscar_ip ne "" && ($oscar_ip ne $oscar_if_ip)) {
        print " --------------------------------------------------\n";
        print " ERROR: it seems the interface used is not the one \n";
        print " assigned to OSCAR in /etc/hosts \n";
        print " --------------------------------------------------\n";
        return FAILURE;
    }

    return SUCCESS;
}

if (check_hostname () eq FAILURE || check_oscar_interface () eq FAILURE) { 
    $rc = FAILURE;
    print " -----------------------------------\n";
    print "  $0 \n";
    print "  Network configuration not correct \n";
    print " -----------------------------------\n";
}

exit($rc);

#!/usr/bin/perl

#$Id: manage-pkgs.pl,v 1.1 2001/08/14 22:10:12 mjbrim Exp $

# manage-pkgs - OSCAR package management master script

#$COPYRIGHT$

# Setup Environment
# (should use oscar environment script later on)

use lib "$ENV{OPMLIB}";
use OPMC3;
use Getopt::Long;

# Check Usage

GetOptions("install|i",
           "uninstall|u",
           "configure|c",
           "cluster=s",
           "pkgs|p=s",
           "group|g=s",
           "core");

$usage = "usage: $0 {-i|-u|-c} [--core] --cluster cluster_name ";
$usage .= "--pkgs pkg_list --group client_group\n";

if(!($opt_pkgs && $opt_group && $opt_cluster)) { 
    print $usage; 
    exit 1; 
}
elsif(!($opt_install || $opt_uninstall || $opt_configure)) {
    print $usage;
    exit 1;
}
elsif(($opt_install && $opt_uninstall) 
      || ($opt_install && $opt_configure)
      || ($opt_uninstall && $opt_configure)) {
    print $usage;
    exit 1;
}

# Check for Valid ODR Items

if( check_valid($opt_cluster, "cluster") ) {
    print "$0: cluster $opt_cluster does not exist, exiting\n";
    exit 1;
}

if( check_valid($opt_group, "group") ) {
    print "$0: client group $opt_group does not exist, exiting\n";
    exit 1;
}

if( check_version($opt_cluster) ) {
    print "$0: cluster $opt_cluster has a version which is incompatible\n";
    print "$0: with the current version of OSCAR, exiting\n";
    exit 1; 
}

# Check Files

if((! -f $opt_pkgs)
   || (! open(PKGS, "<$opt_pkgs"))) {
    print "$0: could not open package file $opt_pkgs, exiting\n";
    exit 1;
}

# Generate Client List
$| = 1;
$nodes = "/tmp/$opt_group.nodes";
open(NODES, ">$nodes") or
    die "$0: could not write nodes file, exiting\n";
$hostlist = `readDR -D $ENV{ODRDATA} group HOSTLIST NAME=$opt_group | awk -F= '{print \$2}'`;
chomp($hostlist);
@clients = `readDR -D $ENV{ODRDATA} hostlist HOST NAME=$hostlist | awk -F= '{print \$2}'`;
foreach $client (@clients) {
    print NODES "$client";
}
close(NODES);

# Process Packages

$RC = 0;
 
if( $opt_core ) { $pkg_base = "$ENV{OSCARHOME}/core-packages"; }
else { $pkg_base = "$ENV{OSCARHOME}/packages"; }

while(<PKGS>) {
    chomp;
    ($name, $server) = split;
    $pkg_dir = "$pkg_base/$name";
    if(! -d $pkg_dir) {
	print "$0: directory for package $_ does not exist, skipping\n";
	next;
    }
    if( $opt_install ) {
	$rc = install_pkg($name, $pkg_dir, $nodes, $opt_group, $server);
        if( $rc != 0 ) {
            print"$0: installation of package $name failed\n";
            $RC = 1;
        }
    }
    elsif( $opt_uninstall ) {
	$rc = uninstall_pkg($name, $pkg_dir, $nodes, $opt_group, $server);
        if( $rc != 0 ) {
            print"$0: uninstallation of package $name failed\n";
            $RC = 1;
        }
    }
    else {
	$rc = configure_pkg($name, $pkg_dir, $nodes, $opt_group, $server);
        if( $rc != 0 ) {
            print"$0: configuration of package $name failed\n";
            $RC = 1;
        }
    }
}

system("/bin/rm $nodes");

exit $RC;

#-------Subroutines--------#

sub check_valid {
    my ($name, $item) = @_;
    $out = `readDR -D $ENV{ODRDATA} $item NAME=$name`;
    if( $out eq "" ) { return 1; }
    else { return 0; }
}

sub check_version {
    my $cluster = shift;
    $version = `readDR -D $ENV{ODRDATA} cluster OSCAR_VERSION NAME=$cluster | awk -F= '{print \$2}'`;
    ($version, $rest) = split(/ /, $version);
    if( $version eq $ENV{OSCARVERSION} ) { return 0; }
    else { return 1; }
}

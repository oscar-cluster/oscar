#!/usr/bin/env perl

# writeODR.pl - wrapper routine for accessing OSCAR Data Repository (ODR)
#               using the CLAMDR writeDR.pl routine  

# $Id: writeODR.pl,v 1.3 2001/08/22 15:35:44 geiselha Exp $

# $Copyright$

$cluster = shift;

$write = "writeDR.pl ";
$read = "readDR.pl ";

$awkval = "awk -F= '{print \$2}'";

if( $ENV{ODRDATA} ) {
  $write .= "-D $ENV{ODRDATA} ";
  $read .= "-D $ENV{ODRDATA} ";
}

# Check OSCAR Version Against ODR Cluster Key

$version = `$read cluster OSCAR_VERSION NAME=$cluster | $awkval`;
($version, $rest) = split(/ /, $version);
if( $version ne $ENV{OSCARVERSION} ) {
  print "$0: OSCAR Version Mismatch - Cluster $cluster is v$version, OSCAR is v$ENV{OSCARVERSION}\n";
  exit 1;
} 

$write .= "@ARGV";

system($write);


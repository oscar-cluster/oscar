#!/usr/bin/env perl

# readODR.pl - wrapper routine for accessing OSCAR Data Repository (ODR)
#              using the CLAMDR readDR.pl routine  

# $Id: readODR.pl,v 1.3 2001/08/22 15:35:44 geiselha Exp $

# $Copyright$

$cluster = shift;

$read = "readDR.pl ";

$awkval = "awk -F= '{print \$2}'";

if( $ENV{ODRDATA} ) {
  $read .= "-D $ENV{ODRDATA} ";
}

# Check OSCAR Version Against ODR Cluster Key
 
$version = `$read cluster OSCAR_VERSION NAME=$cluster | $awkval`;
($version, $rest) = split(/ /, $version);
if( $version ne $ENV{OSCARVERSION} ) {
  print "$0: OSCAR Version Mismatch - Cluster $cluster is v$version, OSCAR is v$ENV{OSCARVERSION}\n";
  exit 1;
}

$read .= "@ARGV";

system($read);


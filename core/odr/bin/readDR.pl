#!/usr/bin/perl

#   $Header: /home/user5/oscar-cvsroot/oscar/core/odr/bin/Attic/readDR.pl,v 1.1 2001/08/14 18:46:59 geiselha Exp $

#   Copyright (c) 2001 International Business Machines

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

#   Greg Geiselhart <geiselha@us.ibm.com>

# read - return requested information from ODR

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use clamdr::API;
use Getopt::Long;
use Data::Dumper;
$Getopt::Long::ignorecase = 0;

my $defsyn = 'oscar';

sub usage {
    my $progname = $0;
    if ($progname =~ m/(.+\/)(\w+)/) {
	$progname = $2;
    }
    print <<USAGE;
usage: $progname [ options ] filename <column specification> <filter specification>
  options
    -D, --Directory
       Directory for data files (default: $clamdr::API::DATADIR)
    -l, --list
       List all valid data filenames
    -s, --syntax
       Syntax to use (default: $defsyn)
    -d, --distinct
       list only distinct rows
    -c, --columns
       list column names only
  filename
    name of the file on which to operate
  <column spec>
    list of columns names to read
  <filter spec>
    list of NAME=VALUE pairs ( NAME=column name, VALUE=value to filter on )
    filter specs are logically ANDed

prints query on file displaying <column spec> filtered on <filter spec>

<column spec> will be line of the form NAME1=VAL1 NAME2=VAL2 for each row
in file matching <filter spec>. Special character '*' may be used to specify
all columns in <column spec> (remember to quote * on cmd line to prevent
shell expansion)

USAGE
    exit 1;
}

my %options;
GetOptions(\%options,
	   "distinct!",
	   "columns!",
	   "list!",
	   "Directory=s",
	   "syntax=s",
	  );

my ($filename, @parameters) = @ARGV;
if (not $filename and not $options{list}) { # requires at least 1 parameter
    print "filename is required\n";
    usage;
}

my $syn = $options{syntax} || $defsyn;
my $syntax = initialize($syn);
if ($options{Directory}) {
    if (not -d $options{Directory}) {
	print "$options{Directory} not a directory\n";
	usage;
    }
    if (not -r $options{Directory}) {
	print "$options{Directory} not readable\n";
	usage;
    }
    if (not -f "$options{Directory}/syntax") {
	print "$options{Directory} has no syntax\n";
	usage;
    }
}

if ($options{list}) {
    foreach (sort keys %$syntax) {
	print "$_\n";
    }
    exit 0;
}

if (not $syntax->valid_category($filename)) { # $filename had best be valid...
    print "$filename is not a recognized data file\n";
    usage;
}
my @cols = $syntax->get_category_tags($filename);
if (not scalar(@parameters)) {
    if ($options{columns}) {
	print "@cols\n";
	exit 0;
    }
    @parameters = ( '*' ); # if no other parameters, select all columns
}

my ($col, $all, $param, @columns, @clauses, @markers);
foreach $param (@parameters) { # chaeck all parameters
    my $chk = 1;
    $param =~ s/\s//g;                 # eat whitespace
    if ($param =~ m/(.+)=(.+)/) {      # does it look like 'NAME=VALUE' ?
	my ($name, $value) = ($1, $2); # if so, must want filtering...
	push @clauses, "$name=?";      # parameter markers used...
	push @markers, $value;         # here's the corresponding value to bind
	$col = $name;
    } else {                           # otherwise, select specific COLUMN
	if ($param eq '*') {           # if wildcard ...
	    $all = 1;                  # SELECT all COLUMNS
	    $chk = 0;                  # don't check caolumn names
	    @columns = @cols;
	} elsif (not $all) {           # otherwise
	    push @columns, $param;     # grab specific COLUMN name
	    $col = $param;
	}
    }
    if ($chk and not $syntax->valid_tag($filename, $col)) { # check COLUMN name
	print "$param: not a valid tag\n";
	usage;
    }
}

@columns = @cols unless scalar(@columns); # list of all COLUMNS to select
my $distinct;
$distinct .= "DISTINCT" if $options{distinct}; # distinct select

# build SQL stmt
my $sql = "SELECT $distinct " . (join ',', @columns) . " FROM $filename";
if (scalar(@clauses)) { # if filtering 
    $sql .= " WHERE " . (join ' AND ', @clauses); # build the WHERE clause
}

# issue the query
query(
      sql      => $sql,
      callback => [ \&cb, @columns ],
      markers  => \@markers,
     );

#
# the query callback
#
sub cb {
    my ($params, @columns) = @_;
    my $i = 0;
    foreach (@$params) {
	print "$_=", $columns[$i++], " ";
    }
    print "\n";
}

__END__

=head1 NAME

readDR - script to read CLAMDR data

=head1 SYNOPSIS

  readDR --list                 # list all data files
  readDR client                 # read all client rows
  readDR --columns client       # list column names for table client
  readDR client NAME=test       # read all columns of client row 'test'
  readDR client NAME=test STATE # read STATE column of client row 'test'

=head1 DESCRIPTION

B<readDR> is a command line interface to read cluster persistent data.
Parameters are read from the command line, output is written to STDOUT.
Each output line consists of I<NAME=VALUE> pairs where I<NAME> is the
column name and I<VALUE> is the corresponding column value for a row
matching the input search critera.

=head2 Syntax

readDR [I<options>] filename [I<column spec>] [I<filter spec>]

=head2 Options

The following options are recognized:

=over 4

=item -D, --Directory

Directory where data files are located.

=item -d, --distinct

List only distinct occurences.

=item -c, --columns

List columns names only.

=item -l, --list

List all data filenames.

=item -s, --syntax

Syntax to apply when reading data files.

=back

=head2 Filename

The name of the data file to read. A complete list of all defined data files may
be obtained by issuing the command:

readDR --list

=head2 Column spec

Column specification is a whitespace delimited list of column names to display.
A complete list of all columns for a given data file may be obtained by issuing
the command:

readDR --columns I<filename>

If no column specification is provided, all columns will be displayed.

=head2 Filter spec

Filter specification consists of whitespace delimited I<NAME=VALUE> pairs. If provided,
only the rows in the given data file matching the filter specification will be displayed.
The complete filter specification is the logically B<and> of all filter clauses. Note
that the filter specification is an exact match only test.

=head1 AUTHOR

Greg Geiselhart, geiselha@us.ibm.com

=head1 SEE ALSO

perl(1), writeDR(1).

=cut

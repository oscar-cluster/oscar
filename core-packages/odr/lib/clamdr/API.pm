package clamdr::API;

#   $Header: /home/user5/oscar-cvsroot/oscar/core-packages/odr/lib/clamdr/Attic/API.pm,v 1.3 2001/10/22 00:44:59 sdague Exp $

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

use strict;
use vars qw($VERSION $DATADIR $DBH @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw($DATADIR $DBH initialize query);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use DBI;
use Text::CSV_XS;
use clamdr::Syntax;

$DATADIR = $ENV{CLAMDRHOME} || "/var/lib/clamdr"; # default directory for data files

#
# read the syntax file to discover schema for all other files
#
sub initialize {
    my $syntax = shift;
    $DBH = DBI->connect("DBI:CSV:f_dir=$DATADIR") or
      die "could not open database [ $DATADIR ]:\n$DBI::errstr\n";
    $DBH->{PrintError} = 1;
    $DBH->{RaiseError} = 1;
    $DBH->{csv_tables}->{syntax} = {
				    col_names => [ # columns names
						  qw(
						     syntax
						     tabname
						     colname
						     colseq
						     iskey
						     )
						 ],
				    types     => [ # column data types
						  Text::CSV_XS::PV(),
						  Text::CSV_XS::PV(),
						  Text::CSV_XS::PV(),
						  Text::CSV_XS::IV(),
						  Text::CSV_XS::IV(),
						 ],
				    eol       => "\n",     # record separator
				    sep_char  => ":",      # column separator
				    file      => "syntax", # schema file name
				   };
    #
    # syntax file describes schema for all other files. Format:
    #  syntax:  syntax to use (ie 'oscar')
    #  tabname: table name (and hence data file) for a given syntax
    #  colname: column name for a given table
    #  colseq:  sequence number of the column
    #  key:     column is a key of the table
    #
    my $thdl = $DBH->prepare("SELECT DISTINCT tabname FROM syntax where syntax=?");
    my $chdl = $DBH->prepare("SELECT colname,iskey FROM syntax WHERE syntax=? AND tabname=? ORDER BY colseq");
    $thdl->execute($syntax);
    my ($table, %tables);
    while ($table = $thdl->fetchrow_array) { # read all table names for given syntax
	$chdl->execute($syntax, $table);
	my ($column, $key, @columns, @keys);
	while (($column, $key) = $chdl->fetchrow_array) { # read column description for table
	    push @columns, $column;
	    push @keys, $column if $key;
	}
	$tables{$table}->{columns} = \@columns;
	$tables{$table}->{keys} = \@keys;
	$chdl->finish;
	$DBH->{csv_tables}->{$table} = { # let the DBD::CSV driver in on the schema
					col_names => \@columns,
					eol       => "\n",
					sep_char  => ":",
					file      => $table,
				       };
    }
    $chdl->finish;
    return new clamdr::Syntax(%tables);
}

#
# executes a query (SQL SELECT) and invokes callback for each fetched row
# SQL can contain parameter markers ('?'), in which case 'markers' array ref
# must be provided
#
sub query {
    my %params = @_;
    my $callback = $params{callback};
    my @parameters;
    if (ref($callback) eq 'ARRAY') {    # if the callback is ARRAY ref,
	@parameters = @$callback;       #   first element is cb ptr
	$callback = shift @parameters;  #   all others are user provided parameters
    }
    my $sth = $DBH->prepare($params{sql});
    $sth->execute(@{$params{markers}});
    my @columns;
    while (@columns = $sth->fetchrow_array) {
	$callback->(\@parameters, @columns) if $callback; # invoke callback (if any)
    }
    $sth->finish;
}

sub DESTROY {
    $DBH->disconnect if $DBH;
    $DBH = undef;
}

1;

__END__

=head1 NAME

API - Perl extension for interface to DBD::CSV data files

=head1 SYNOPSIS

  use clamdr::API;
  my $syntax = initialize('oscar');
  my @columns = @{$syntax->{client}};
  my $sql = "SELECT ". ( join ',', @columns ). " FROM client WHERE NAME=?";
  my $cb = sub {
      my ($params, @values) = @_;
      $i = 0;
      foreach (@$params) {
	  print "$_=", $values[$i++], " ";
      }
      print "\n";
  }
  query(
	sql      => $sql,
	callback => [ \&cb, @columns ],
	markers  => [ 'node1' ],
       );

=head1 DESCRIPTION

=head1 AUTHOR

Greg Geiselhart, geiselha@us.ibm.com

=head1 SEE ALSO

perl(1).

=cut

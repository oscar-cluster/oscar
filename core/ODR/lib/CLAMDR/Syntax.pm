package CLAMDR::Syntax;

#   $Header: /home/user5/oscar-cvsroot/oscar/core/ODR/lib/CLAMDR/Attic/Syntax.pm,v 1.1 2001/08/14 15:22:33 geiselha Exp $

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
use vars qw($VERSION $SYNTAX $CONFIG @ISA @EXPORT);

require Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw();
$VERSION = '0.01';

sub new {
    my $class = shift;
    return bless({ @_ }, $class);
}

sub valid_category {
    my ($self, $category) = @_;
    return 1 if defined($self->{$category});
    return 0;
}

sub valid_tag {
    my ($self, $category, $tag) = @_;
    my $table = $self->{$category};
    return 0 unless $table;
    foreach my $col (@{$table->{columns}}) {
	return 1 if $col eq $tag;
    }
    return 0;
}

sub get_category_tags {
    my ($self, $category) = @_;
    my $table = $self->{$category};
    return @{$table->{columns}} if $table;
    return ();
}

1;
__END__

=head1 NAME

API - Perl extension for customization of CLAMDR syntax

=head1 SYNOPSIS

  use CLAMDR::Syntax;
  my $syntax = initialize('oscar');

=head1 DESCRIPTION

=head1 AUTHOR

Greg Geiselhart, geiselha@us.ibm.com

=head1 SEE ALSO

perl(1).

=cut

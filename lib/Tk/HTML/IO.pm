#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# Copyright (c) 2002 National Center for Supercomputing Applications (NCSA)
#                    All rights reserved.
#
# Written by Terrence G. Fleury (tfleury@ncsa.uiuc.edu)
#
# Code is based on Tk::HTML written by Nick Ing-Simmons 24 Jan 1998

package LWP::IO;

# $Id$

require Tk;
require LWP::Debug;

use MIME::QuotedPrint qw(encode_qp);

=head1 NAME

LWP::TkIO - Tk I/O routines for the LWP library

=head1 SYNOPSIS


use vars qw($VERSION);
$VERSION = '$Id$';

 use Tk;
 require LWP::TkIO;
 require LWP::UserAgent;

=head1 DESCRIPTION

This module provide replacement functions for the LWP::IO
functions. Require this module if you use Tk and want non exclusive IO
behaviour from LWP.

See also L<LWP::IO>.

=cut


sub read
{
    my $fd = shift;
    my $dataRef = \$_[0];
    my $size    =  $_[1];
    my $offset  =  $_[2] || 0;
    my $timeout =  $_[3];

    my $doneFlag = 0;
    my $n;

    my $timer;
    my $timeoutSub = sub { undef $timer };

    Tk->fileevent($fd, 'readable',
		  sub {
		       $n = sysread($fd, $$dataRef, 1, $offset);
                  #     print STDERR fileno($fd)," sz=$size off=$offset n=$n:$!\n";
                       if (defined $n)
                        {
		        #LWP::Debug::conns("Read $n bytes: '" .
			#		encode_qp(substr($$dataRef, $offset, $n)) .
			#		"'");
                         $offset += $n;
                        }
		        $doneFlag = 1;
		      }
		 );
    $timer = Tk->after($timeout*1000, $timeoutSub );

    Tk::DoOneEvent(0) until ($doneFlag || !defined($timer));

    Tk->fileevent($fd, 'readable', ''); # no more callbacks
    die "Timeout" unless (defined $timer);
    Tk->after(cancel => $timer);
    return $n;
}


sub write
{
    my $fd = shift;
    my $dataRef = \$_[0];
    my $timeout =  $_[1];

    my $len = length $$dataRef;

    return 0 unless $len;

    my $offset = 0;
    my $timeoutFlag = 0;
    my $doneFlag = 0;

    my $timeoutSub = sub { $timeoutFlag = 1; };
    my $timer;
    $timer = Tk->after($timeout*1000, $timeoutSub ) if $timeout;

    Tk->fileevent($fd, 'writable',
		  sub {
		      my $n = syswrite($fd, $$dataRef, $len-$offset, $offset);
		      if (!defined $n) {
			  $done = 1;
		      } else {
			  LWP::Debug::conns("Write $n bytes: '" .
					    substr($$dataRef, $offset, $n) .
					    "'");
			  $offset += $n;
			  $timer = Tk->after($timeout*1000, $timeoutSub )
			    if $timeout;
		      }
		  }
		 );

    Tk::DoOneEvent(0) until ($timeoutFlag || $doneFlag || $offset >= $len);

    Tk->fileevent($fd, 'writable', ''); # no more callbacks
    Tk->after(cancel => $timer) if $timeout;

    die "Timeout" if $timeoutFlag;
    $offset;
}

1;

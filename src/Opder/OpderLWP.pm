package Opder::OpderLWP;

#########################################################################

=head1 NAME

Opder::OpderLWP - Utility routines for getting information about opd files
                  and for doing the actual fetching of the files.

=head1 SYNOPSIS

  use Opder::OpderLWP;

  my $opder = new Opder::OpderLWP;
  $opder->uri('http://oscar.ncsa.uiuc.edu/kernel_picker.rpm');

And then one of the following:

=over 2
=item
  $opder->localFileName('/tmp/kernel_picker.rpm');
  $opder->getFile;

=item 
  my $dataStream;
  my $chunkNum;
  my $fileSize = $opder->getContentLength;
  $opder->chunkSize(1024);     # Defaults to 4096 if not explicitly set
  $opder->callbackRef(\&getChunks);
  $opder->getFile;
  print "All done getting the dataStream!\n";  # Next, write it to a file!

  sub getChunks 
  { 
    my($data,$response,$protocol) = @_;
    $dataStream .= $data;
    print "Got ". (++$chunkNum)*$opder->chunkSize ."out of $fileSize bytes\n";
  }

=back

=head1 DESCRIPTION

Blah!

=head1 METHODS

=over

=cut

#########################################################################

use strict;
use utf8;

use LWP::Simple;
use LWP::UserAgent;
use Class::Struct;
use Carp;

struct ( 'Opder::OpderLWP' , {
  uri => '$',
  chunkSize => '$',
  callbackRef => '$',
  localFileName => '$'
  }
);

#########################################################################
                                                                                
=item C<chunkSize($self,$newSize)>
                                                                                
=cut

#########################################################################
sub chunkSize
{
  my $self = shift;
  if (@_ > 1)     
    { 
      Carp::croak "Too many arugments for chunkSize"; 
    }
  elsif (@_ == 1) 
    {
      my $newSize = shift;
      $newSize = 128   if ($newSize < 128);
      $newSize = 65536 if ($newSize > 65536);
      $self->{'chunkSize'} = $newSize;
    }
  else
    {
      return $self->{'chunkSize'};
    }
}

#########################################################################
                                                                                
=item C<getContentLength>
                                                                                
=cut

#########################################################################
sub getContentLength
{
  my $self = shift;
  my $contentLength = -1;  # Assume failure!

  if (length($self->uri) > 0)
    { # Make sure the user set a non-empty URI
      my @result = LWP::Simple::head($self->uri);
      $contentLength = $result[1] if (scalar(@result) > 0);
    }

  return $contentLength;
}

#########################################################################

=item C<getFile>
                                                                                
=cut

#########################################################################
sub getFile
{
  my $self = shift;
  my $ua = LWP::UserAgent->new(env_proxy => 1,
                               keep_alive => 1,
                               timeout => 30,
                              );
  my $request  = HTTP::Request->new('GET',$self->uri);
  my $response;

  if ($self->callbackRef) 
    {
      $response = (($self->chunkSize) ? 
                    $ua->request($request,$self->callbackRef,$self->chunkSize) :
                    $ua->request($request,$self->callbackRef,4096));
    }
  elsif ($self->localFileName)
    {
      $response = $ua->request($request,$self->localFileName);
    }
  else
    {
      $response = $ua->request($request);
    }

  return $response;
}

1;

__END__

=back

=head1 SEE ALSO

http://www.trolltech.com/

=head1 COPYRIGHT

Copyright E<copy> 2004 The Board of Trustees of the University of Illinois.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=head1 AUTHOR

Terrence G. Fleury (tfleury@ncsa.uiuc.edu)

First Created on February 24, 2004

Last Modified on February 24, 2004

=cut

#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
#########################################################################


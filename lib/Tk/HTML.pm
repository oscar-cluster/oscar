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

package Tk::HTML;
require Tk::ROText;
require Tk::HTML::Handler;

use Carp;

use vars qw($VERSION);
$VERSION = '$Id: HTML.pm,v 1.3 2002/10/29 19:18:27 tfleury Exp $';

@ISA = qw(Tk::Derived Tk::ROText);
use strict;

Construct Tk::Widget 'HTMLText';

sub Font
{
 my ($w,%fld)     = @_;
 $fld{'family'}   = 'times'   unless (exists $fld{'family'});
 $fld{'weight'}   = 'medium'  unless (exists $fld{'weight'});
 $fld{'slant'}    = 'r'       unless (exists $fld{'slant'});
 $fld{'size'}     = 140       unless (exists $fld{'size'});
 $fld{'spacing'}  = '*'       unless (exists $fld{'spacing'});
 $fld{'registry'} = 'iso8859' unless (exists $fld{'registry'});
 $fld{'encoding'} = '1'       unless (exists $fld{'encoding'});
 $fld{'slant'}    = substr($fld{'slant'},0,1);
 my $name = "-*-$fld{'family'}-$fld{'weight'}-$fld{'slant'}-*-*-*-$fld{'size'}-*-*-$fld{'spacing'}-*-$fld{'registry'}-$fld{'encoding'}";
 return $name;
}

sub call_ISINDEX 
{
 my($w,$e) = @_;
 my $method = "GET";
 my $url;
 if(defined $w->{'base'}) { $url = $w->{'base'}; } else { $url = $w->url; }
 my $query = Tk::HTML::Form::encode($w,$e->get);
 $w->HREF("$url?$query",'GET');
}

sub FindImage
{
 my ($w,$src,$l) = @_;
 $src = $w->HREF($src,'GET');
 my $img;
 eval {local $SIG{__DIE__}; require Tk::Pixmap; $img = $w->Pixmap(-data => $src) };
 eval {local $SIG{__DIE__}; require Tk::Bitmap; $img = $w->Bitmap(-data => $src) } if ($@);
 eval {local $SIG{__DIE__}; require Tk::Photo;  $img = $w->Photo(-data => $src)  } if ($@);
 if ($@)
  {
   warn "$@";
  }
 else
  {
   $l->configure(-image => $img);
  }
}

sub IMG_CLICK 
{
 my($w,$c,$t,$aref,$n) = @_;
 my $Ev = $c->XEvent;
 my $cor = $c->cget(-borderwidth);
 if($t eq "ISMAP") 
  {
   $w->HREF($aref . "?" . ($Ev->x - $cor) . "," . ($Ev->y - $cor),'GET');
  } 
 elsif ($t eq "AREF")
  {
   $w->HREF($aref,'GET');
  }
 else 
  {
   my $s = "$n.x=" . ($Ev->x - $cor) . "&$n.y=" . ($Ev->y - $cor);
   $aref->Submit($s);
  }
}

sub HTML::dump {
  my($a,$b) = @_;
  ${($a->configure(-textvariable))[4]} = $b;
}

sub plain
{
 my ($w,$text) = @_; 
 my $var = \$w->{Configure}{-plain};
 if (@_ > 1)
  {
   $$var = $text;
   $w->delete('0.0','end');
   $w->insert('end',$text);
  }
 return $$var;
}

sub fragment
{
 my ($w,$tag) = @_;
 my @info = $w->tagRanges($tag);
 if ($w->tagRanges($tag))
  {
   $w->yview($tag.'.first');
  }
 else
  {
   warn "No tag `$tag'";
  }
}

sub parse
{
 my ($w,$html) = @_;
 unless (ref $html)
  {
   my $s = Tk::timeofday();
   # print STDERR "Parsing ...";
   local $HTML::Parse::IGNORE_UNKNOWN = 0;
   my $obj = HTML::Parse::parse_html($html);
   $obj->{'_source_'} = $html;
   # printf STDERR " %.3g seconds\n",Tk::timeofday()-$s;
   return $obj;
  }
 return $html;
}

#
# This is a clone of 'traverse' which calls callback 
# for end _all_ tags even 'empty' ones.
# 
sub HTML::Element::traverse_all
{
 my ($self, $callback, $depth) = @_;
 $depth ||= 0;
 if (&$callback($self, 1, $depth)) 
  {
   for (@{$self->{'_content'}}) 
    {
     if (ref $_) 
      {
       $_->traverse_all($callback, $depth+1);
      } 
     else 
      {
       &$callback($_, 1, $depth+1);
      }
    }
   &$callback($self, 0, $depth);
  }
 $self;
}

sub html
{
 my ($w,$html,$frag) = @_; 
 my $var = \$w->{Configure}{-html};
 if (@_ > 1)
  {
   $$var = $w->parse($html);
   my $s = Tk::timeofday();
   # print STDERR "Rendering ...";
   my $h = new Tk::HTML::Handler widget => $w;
   $$var->traverse_all(sub { $h->traverse(@_)}, 0);
   # printf STDERR " %.3g seconds\n",Tk::timeofday()-$s;
   $w->fragment($frag) if (defined $frag);
  }
 return $$var;
}

sub file
{
 my ($w,$file) = @_; 
 my $var = \$w->{Configure}{-file};
 if (@_ > 1)
  {
   open($file,"<$file") || croak "Cannot open $file:$!";
   $$var = $file;
   $w->html(join('',<$file>));
   close($file);
  }
 return $$var;
}

sub ClassInit
{
 my ($class,$mw) = @_;
 $mw->bind($class,'<b>','Back');
 return $class->SUPER::ClassInit($mw);
}

sub InitObject
{
 my ($w,$args) = @_;
 $w->SUPER::InitObject($args);
 
 $args->{-wrap} = 'word';
 $args->{-font} = $w->Font(family => 'courier');

 $w->tagConfigure('symbol', -font => $w->Font(family => 'symbol', size => 180,  encoding => '*', registry => '*'));
 $w->tagConfigure('text', -font => $w->Font(family => 'times'));
 $w->tagConfigure('CODE',-font => $w->Font(family => 'courier', weight => 'bold'));
 $w->tagConfigure('KBD',-font => $w->Font(family => 'courier'));
 $w->tagConfigure('VAR',-font => $w->Font(family => 'helvetica',slant => 'o', weight => 'bold'));
 $w->tagConfigure('B',-font => $w->Font(family => 'times', weight => 'bold' ));
 $w->tagConfigure('H1',-font => $w->Font(family => 'times', weight => 'bold', size => 180));
 $w->tagConfigure('H2',-font => $w->Font(family => 'times', weight => 'bold', size => 140));
 $w->tagConfigure('I',-font => $w->Font(family => 'times',slant => 'i', weight => 'bold' ));
 $w->tagConfigure('BLOCKQUOTE', -font => $w->Font(family => 'helvetica',slant => 'o', weight => 'bold'),
         -lmargin1 => 35, -lmargin2 => 30, -rmargin => 30);
 $w->tagConfigure('ADDRESS', -font => $w->Font(family => 'times',slant => 'i'));
 $w->tagConfigure('HREF',-underline => 1, -font => $w->Font(family => 'times',slant => 'i', weight => 'bold' ));
 $w->tagConfigure('CENTER',-justify => 'center');
 $w->{Configure} = {};
 $w->ConfigSpecs('-showlink' => ['CALLBACK',undef,undef,undef],
                 '-base'     => ['PASSIVE',,undef,undef,undef],
                );
}

1;

# __END__


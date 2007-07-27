package OSCAR::Tk;

# Copyright (c) 2003, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
#   $Id$

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

#   Copyright 2001-2002 International Business Machines
#                       Sean Dague <japh@us.ibm.com>

use strict;
use vars qw($VERSION @EXPORT);
use Tk;
require Tk::Dialog;
use base qw(Exporter);
@EXPORT = qw(yesno_window);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

sub yesno_window {
    my $w = shift;
    my $title = shift || "Are you sure?";
    my $label = shift || $title;
    my $on_yes = shift;
    my $on_no = shift;
    my @args = @_;

    my $dialog = $w->Dialog(
        -title => $title,
        -bitmap => 'question',
        -text => $label,
        -buttons => [ 'Yes', 'No' ],
        );
    my $ans = $dialog->Show();

    &$on_yes( @args ) if $ans eq 'Yes' && ref( $on_yes ) eq 'CODE';
    &$on_no( @args ) if $ans eq 'No' && ref( $on_no ) eq 'CODE';

}

# WARNING: Do not export this function, the name conflicts with other 
# functions exported by some Perl modules
sub center_window {
    my $w = shift;
    my $p = $w->parent();

    $w->withdraw() if $w->viewable();

    $w->idletasks;
    my $x = int( ($w->screenwidth - $w->reqwidth)/2 );
    my $y = int( ($w->screenheight - $w->reqheight)/2 );
    if( $p ) {
        $x -= int( $p->vrootx/2 ) if $p->vrootx;
        $y -= int( $p->vrooty/2 ) if $p->vrooty;
    }
    $w->geometry( "+$x+$y" );

    $w->deiconify();

}
#
# These subs REPLACE SystemImager/Tk/Common.pm because, well,
# they need replacement...
# WARNING: Do not export this function, the name conflicts with other 
# functions exported by some Perl modules
sub done_window {
    my ($w, $message, $onclose, @args) = @_;

    my $dialog = $w->Dialog(
        -title => 'Done!',
        -bitmap => 'info',
        -text => $message,
        -default_button => 'OK',
        -buttons => [ 'OK' ],
        );
    $dialog->Show();

    &$onclose( @args ) if ref( $onclose ) eq 'CODE';

    1;
}

# WARNING: Do not export this function, the name conflicts with other 
# functions exported by some Perl modules
sub error_window {
    my ($w, $message, $onclose, @args) = @_;

    my $dialog = $w->Dialog(
        -title => 'ERROR!',
        -bitmap => 'error',
        -text => $message,
        -default_button => 'OK',
        -buttons => [ 'OK' ],
        );
    $dialog->Subwidget( 'bitmap' )->configure( -foreground => 'red' );
    $dialog->Subwidget( 'message' )->configure( -foreground => 'red' );
    $dialog->Show();

    &$onclose( @args ) if ref( $onclose ) eq 'CODE';

    1;
}

1;

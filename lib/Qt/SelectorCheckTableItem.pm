#########################################################################
#  File  : SelectorCheckTableItem.pm                                    #
#  Author: Terrence G. Fleury (tfleury@ncsa.uiuc.edu)                   #
#  Date  : October 29, 2003                                             #
#  This perl package is a subclass of a Qt QCheckTableItem.  I had to   #
#  subclass  QCheckTableItem since I need control over the color of the #
#  text in the table for when running the GUI as the 'Updater'.         #
#########################################################################
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
#  Copyright (c) 2003 The Board of Trustees of the University of Illinois.
#                     All rights reserved.
#########################################################################

use strict;
use utf8;

package SelectorCheckTableItem;
use Qt;
use Qt::isa qw(Qt::CheckTableItem);
use Qt::slots
    paint => [ 'QPainter*', 'const QColorGroup&', 'const QRect&', 'bool' ];

use Carp;

sub NEW
{
#########################################################################
#  Subroutine: NEW                                                      #
#  Parameters: (1) Parent of this table                                 #
#              (2) Text of the item in the table                        #
#  Returns   : Reference to a new SelectorCheckTableItem object.        #
#########################################################################

  shift->SUPER::NEW(@_[0..1]);
}

sub paint
{
#########################################################################
#  Subroutine: paint                                                    #
#  Parameters: (1) Pointer to a QPainter                                #
#              (2) Reference to a QColorGroup                           #
#              (3) Reference to a QRect                                 #
#              (4) bool for selected or not                             #
#  Returns   : Nothing                                                  #
#  This subroutine gets called when a checbox in the table needs to be  #
#  painted.  It gets the correct color for the text (based on if the    #
#  package needs to be installed/uninstalled or not) and then calls     #
#  the parent's paint method.                                           #
#########################################################################

  my $qpainter = shift;
  my $qcolorgroup = shift;
  my $qrect = shift;
  my $selected = shift;

  my $cg = SelectorUtils::getTableItemColorGroup(this,$qcolorgroup);

  SUPER->paint($qpainter,$cg,$qrect,$selected);
}

1;


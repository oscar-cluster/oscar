#########################################################################
#  File  : NodeMgmtTable.pm                                             #
#  Author: Jason Brechin (brechin@ncsa.uiuc.edu)                        #
#  Date  : April 24, 2003                                               #
#  This perl package is a subclass of a Qt QTable.  I had to subclass   #
#  QTable (rather than add a basic QTable in Designer) since I needed   #
#  control over the checkboxes and the sorting method.                  #
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

package NodeMgmtTable;
use Qt;
use Qt::isa qw(Qt::Table);
use Qt::slots
    populateTable => [ 'const QString&' ],
    cellValueChanged => [ 'int', 'int' ];

use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Database;
use Carp;

my $tablePopulated = 0;     # So we call populateTable only once

sub NEW
{
#########################################################################
#  Subroutine: NEW                                                      #
#  Parameters: (1) Parent of this table                                 #
#              (2) Name of this table                                   #
#  Returns   : Reference to a new SelectorTable object.                 #
#  This is the constructor for the SelectorTable.  It sets up the stuff #
#  for the table that never changes, like the number of columns,        #
#  headers, read-only status, etc.  Then it show()s it at the end.      #
#  The table is organized as follows:                                   #
#        Col 0       Col 1      Col 2   Col 3                           #
#        ShortName   LongName   Class   Location/Version                #
#  Column 0 is HIDDEN.  It's there just so that we have a key for the   #
#  $allPackages hash.                                                   #
#########################################################################

  shift->SUPER::NEW(@_[0..1]);

  setName("NodeMgmtTable") if (name() eq "unnamed");

  setNumCols(4);
  horizontalHeader()->setLabel(0,"Short Name");
  horizontalHeader()->setLabel(1,"Name");
  horizontalHeader()->setLabel(2,"IP");
  horizontalHeader()->setLabel(3,"MAC");
  hideColumn(0);
  setShowGrid(0);
  verticalHeader()->hide();   # Get rid of the numbers along the left side
  setLeftMargin(0);
  setSelectionMode(Qt::Table::SingleRow());
  setFocusStyle(Qt::Table::FollowStyle());
  setColumnMovingEnabled(0);
  setRowMovingEnabled(0);
  setSorting(1);              # Sort method overridden below
  setColumnStretchable(1,0);
  setColumnStretchable(2,0);
  setColumnStretchable(3,0);
  setColumnReadOnly(1,1);
  setColumnReadOnly(2,1);
  setColumnReadOnly(3,1);
  adjustColumn(1);            # Auto-set width of column 1
  adjustColumn(2);            # Auto-set width of column 2
  adjustColumn(3);
  # When the value of any cell changes, call cellValueChanged to 
  # catch checkboxes on/off.
  Qt::Object::connect(this, SIGNAL 'valueChanged(int,int)',
                            SLOT   'cellValueChanged(int,int)');
 
  show();
}

sub sortColumn
{
#########################################################################
#  Subroutine: sortColumn                                               #
#  Parameters: (1) Column number that was clicked (0-indexed)           #
#              (2) Ascending (= 1) or descending (= 0)                  #
#              (3) Sort whole rows (= 1) or just the one column (= 0)   #
#  Returns   : Nothing                                                  #
#  This subroutine overrides the default sortColumn method in the Table #
#  super class.  Basically, we always want to sort whole rows when one  #
#  of the column headings is clicked.                                   #
#########################################################################

  my $col = shift;
  my $ascending = shift;
  my $wholeRows = shift;

  my $currPack = "";

  # When the checkbox column header is clicked, sort based on long name instead
  $col = 2 if ($col == 1);

  # If we have a row selected, we need to unselect it and reselect it
  # later since it's row number will probably have changed after sorting.
  if (numSelections() == 1)
    {
      $currPack = item(selection(0)->bottomRow(),0)->text();
      clearSelection(1);
    }

  # Do the actual sorting by calling the parent's sortColumn routine
  SUPER->sortColumn($col,$ascending,1);

  # If we had a row selected, select the new row where the package is now.
  if ($currPack)
    { # Search for the new row number of the selected package
      my $found = 0;
      my $currRow = 0;
      while ((!$found) && ($currRow < numRows()))
        {
          $found = 1 if (item($currRow,0)->text() eq $currPack);
          $currRow++ if (!$found);
        }

      # If we found the package's new row, create a selection for it.
      if ($found)
        { 
          my $sel = Qt::TableSelection();
          $sel->init($currRow,0);
          $sel->expandTo($currRow,4);
          addSelection($sel);
        }
    }
}

sub populateTable
{
#########################################################################
#  Subroutine: populateTable                                            #
#  Parameter : Name of the selected package set                         #
#  Returns   : Nothing                                                  #
#  This subroutine should be called when you want to populate the       #
#  table, either from scratch, or a "refresh".  If this function has    #
#  never been called before, then it adds all of the packages and their #
#  corresponding info to the table.  Otherwise, it simply updates the   #
#  "checked" status for each package based on the currently selected    #
#  package set.   This slot is connected to the Package Set ComboBox    #
#  "activated" signal so that when a new package set is chosen, the     #
#  checkbox info is updated appropriately.                              #
#########################################################################

  my $success;         # Return result for database commands

  # Check to see if we have already built the table or not.
  if (!$tablePopulated)
    {
      $tablePopulated = 1;  # So we add stuff to the cells only once

      # Finally, sort the table on the second column and 
      # set its size automatically
      sortColumn(2,1,1);
      adjustColumn(1);
      adjustColumn(2);
      adjustColumn(3);
    }
}

sub cellValueChanged
{
#########################################################################
#  Subroutine: cellValueChanged                                         #
#  Parameter : (1) The row of the changed table cell.                   #
#              (2) The column of the changed table cell.                #
#  Returns   : Nothing                                                  #
#  This slot is called when the value of one of the packageTable's      #
#  cells is changed.  We then call the appropriate subroutine depending #
#  on if the GUI is being run as the 'Selector' or as the 'Updater'.    #
#  Note that this method gets called not only when the user clicks on   #
#  one of the checkboxes, but also when the user selects a new row.     #
#  So take action only when clicked on a checkbox.                      #
#########################################################################

  my $row = shift;
  my $col = shift;

  adjustColumn(1);
  adjustColumn(2);
  adjustColumn(3);
}

1;


#########################################################################
#  File  : OpderTable.pm                                                #
#  Author: Terrence G. Fleury (tfleury@ncsa.uiuc.edu)                   #
#  Date  : June 18, 2003                                                #
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

package OpderTable;
use Qt;
use Qt::isa qw(Qt::Table);
use Qt::slots
    populateTable => [],
    cellValueChanged => [ 'int', 'int' ];
use Qt::signals
    downloadButtonDisable => [],
    downloadButtonUpdate => [];

use Carp;
use Qt::OpderDownloadInfo;

my $tablePopulated = 0;

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
#        Col 0       Col 1        Col 2   Col 3    Col 4                #
#        ArrayPos    PackageName  Class   Version  opd Repository       #
#  Column 0 is HIDDEN.  It's there just so that we have an array index  #
#  into the @successfullyReadPackages array.                            #
#########################################################################

  shift->SUPER::NEW(@_[0..1]);

  setName("OpderTable") if (name() eq "unnamed");

  setNumCols(5);
  horizontalHeader()->setLabel(0,"Array Position");
  horizontalHeader()->setLabel(1,"Package Name");
  horizontalHeader()->setLabel(2,"Class");
  horizontalHeader()->setLabel(3,"Version");
  horizontalHeader()->setLabel(4,"Repository");
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
  setColumnStretchable(2,1);
  setColumnStretchable(3,1);
  setColumnStretchable(4,0);
  setColumnReadOnly(1,0);
  setColumnReadOnly(2,1);
  setColumnReadOnly(3,1);
  setColumnReadOnly(4,1);
  adjustColumn(1);            # Auto-set width of column 1

  # When the value of any cell changes, call cellValueChanged to 
  # catch checkboxes on/off.
  Qt::Object::connect(this, SIGNAL 'valueChanged(int,int)',
    this, SLOT 'cellValueChanged(int,int)');
 
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

  # If we have a row selected, we need to unselect it and reselect it
  # later since it's row number will probably have changed after sorting.
  if (numSelections() == 1)
    {
      $currPack = item(selection(0)->bottomRow(),0)->text();
      clearSelection(1);
    }

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
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine should be called when you want to populate the       #
#  table, either from scratch, or a "refresh".  This function will      #
#  completely rebuild the table from scratch each time it is called.    #
#########################################################################

  if ($tablePopulated)
    {
      for (my $row = numRows()-1; $row >= 0; $row--)
        {
          removeRow($row);
        }
      emit downloadButtonDisable();
    }

  # Now rebuild the table from scratch
  # The downloadInfoForm's parent is the centralWidget, and the
  # centralWidget's parent is the main window.  So go up two levels before
  # heading back down to find the 'downloadInfoForm' child widget. Ugh!
  my $readPackages = parent()->parent()->child(
                     'downloadInfoForm')->getReadPackages();
  my $numrows = scalar(@{$readPackages});
  setNumRows($numrows);
  my $rownum = 0;
  foreach my $href (@{$readPackages})
    {
      # Don't even bother to display non-installable packages
      next unless ($href->{installable} =~ /^[1|y]/i);

      # Column 0 contains array position of package in @{$readPackages}
      setText($rownum,0,$rownum);
      # Column 1 contains checkboxes and "long" package names
      my $checkbox=Qt::CheckTableItem(this,$href->{name});
      setItem($rownum,1,$checkbox);
      # Column 2 contains the "class" of packages
      setText($rownum,2,$href->{class});
      # Column 3 contains the "version" of the packages
      setText($rownum,3,$href->{version});
      # Column 4 contains the long repository name
      setText($rownum,4,$href->{repositoryName});

      $rownum++;
    }
  $tablePopulated = 1;

  # Finally, sort the table on the second column and set its size automatically
  sortColumn(1,1,1);
  adjustColumn(1);
  adjustColumn(4);

  # Now, go through all of the rows and set the checked status to off
  for (my $rownum = 0; $rownum < numRows(); $rownum++)
    {
      item($rownum,1)->setChecked(0);
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
#  cells is changed.  We need to catch when the checkboxes are checked/ #
#  unchecked so that we can check to see if we have a package with the  #
#  same name already checked.  Note that this method gets called not    #
#  only when the user clicks on one of the checkboxes, but also when    #
#  the user selects a new row after a checkbox had been clicked.        #
#########################################################################

  my $row = shift;
  my $col = shift;

  if ($col == 1)  # Column 1 contains the checkboxes
    {
      # We don't want to allow the user to change the checked status of core
      # packages.  So, when a core checkbox is clicked, always set it checked.
      item($row,1)->setChecked(1) if (item($row,2)->text() eq 'core');

      # Check to see if we have selected a package that has multiple
      # entries and uncheck all others of the same name.
      my $package = item($row,1)->text();
      for (my $rownum = 0; $rownum < numRows(); $rownum++)
        {
          next if ($rownum == $row);
          item($rownum,1)->setChecked(0) if
            (item($rownum,1)->text() eq $package);
        }

      # Update the enabled/disabled status of the "Download Packages" button
      emit downloadButtonUpdate();
    }
}

1;


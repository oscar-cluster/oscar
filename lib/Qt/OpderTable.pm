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
    populateTable => [ ],
    cellValueChanged => [ 'int', 'int' ];

use Carp;
use OpderDownloadInfo;

my $tablePopulated = 0;
my $downloadInfoFormRef;
my $downloadButtonRef;

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
#        ShortName   LongName   Class   Location                        #
#  Column 0 is HIDDEN.  It's there just so that we have a key for the   #
#  $allPackages hash.                                                   #
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

  SUPER->sortColumn($col,$ascending,1);
}

sub populateTable
{
#########################################################################
#  Subroutine: populateTable                                            #
#  Parameters: None                                                     #
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

  if ($tablePopulated)
    {
      # First clear out any old items in the table
      for (my $col = 0; $col < 5; $col++)
        {
          for (my $row = 0; $row < numRows(); $row++)
            {
              clearCell($row,$col);
            }
        }
      $downloadButtonRef->setEnabled(0);
    }


  # Now rebuild the table from scratch
  my $readPackages = $downloadInfoFormRef->getReadPackages();
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
#  unchecked so that we can add/delete the appropriate package from     #
#  the current package set.  Note that this method gets called not      #
#  only when the user clicks on one of the checkboxes, but also when    #
#  the user selects a new row after a checkbox had been clicked.  This  #
#  means that we should check to see if the package is in the package   #
#  set (or not) before trying to add/delete it.                         #
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

      # Count how many check boxes are checked.  If 0, then disable
      # the downloadButton.  Otherwise, enable it.
      my $numchecked = 0;
      for (my $rownum = 0; $rownum < numRows(); $rownum++)
        {
          $numchecked++ if item($rownum,1)->isChecked();
        }
      $downloadButtonRef->setEnabled($numchecked > 0);
    }
}

sub setObjectRefs
{
#########################################################################
#  Subroutine: setObjectRefs                                            #
#  Parameters: 1. Reference to the DownloadPackageInfo widget           #
#              2. Reference to the downloadButton                       #
#  Returns   : Nothing                                                  #
#########################################################################

  $downloadInfoFormRef = shift;
  $downloadButtonRef = shift;
}

1;


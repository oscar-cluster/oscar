#########################################################################
#  File  : nodemgmtTable.pm                                             #
#  Author: Terrence G. Fleury (tfleury@ncsa.uiuc.edu)                   #
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

package nodemgmtTable;
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

  setName("nodemgmtTable") if (name() eq "unnamed");

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

      # Get the list of all available packages
      my $allPackages = SelectorUtils::getAllPackages();

      my $rownum = 0;
      foreach my $pack (keys %{ $allPackages })
        {
          # Don't even bother to display non-installable packages
          next if ($allPackages->{$pack}{installable} != 1);

          setNumRows($rownum+1); 


          $rownum++;
        }

      # Finally, sort the table on the second column and 
      # set its size automatically
      sortColumn(2,1,1);
      adjustColumn(1);
      adjustColumn(2);
      adjustColumn(3);
    }

  if (parent()->parent()->installuninstall > 0)
    { # Running as the 'Updater'.  Check boxes according to 'installed' bit.
      # Get list of packages that have their 'installed' bit set.
      my $packagesInstalled = getPackagesInstalled();
      # Get the lists of packages marked to be installed/uninstalled
      my @packagesToBeInstalled;    # Array
      my $packagesToBeInstalled;    # Hash ref of transformed array
      my @packagesToBeUninstalled;  # Array
      my $packagesToBeUninstalled;  # Hash ref of transformed array
      $success = OSCAR::Database::database_execute_command(
        "packages_that_should_be_installed",\@packagesToBeInstalled);
      $success = OSCAR::Database::database_execute_command(
        "packages_that_should_be_uninstalled",\@packagesToBeUninstalled);
      # Transform these lists into hashes
      foreach my $pack (@packagesToBeInstalled)
        {
          $packagesToBeInstalled->{$pack} = 1;
        }
      foreach my $pack (@packagesToBeUninstalled)
        {
          $packagesToBeUninstalled->{$pack} = 1;
        }

      # Go through table and check the boxes ON if 
      #   (a) the package is supposed to be installed OR 
      #   (b) the package is currently installed and not supposed to be
      #       uninstalled.
      for (my $rownum = 0; $rownum < numRows(); $rownum++)
        {
          my $packname = text($rownum,0);
          item($rownum,1)->setChecked(1) if
            (((defined $packagesToBeInstalled->{$packname}) &&
              ($packagesToBeInstalled->{$packname} == 1))
            ||
             ((defined $packagesInstalled->{$packname}) &&
              ($packagesInstalled->{$packname} == 1) &&
              (!$packagesToBeUninstalled->{$packname})));
        }
    }
}

sub setCheckBoxForPackage
{
#########################################################################
#  Subroutine: setCheckBoxForPackage                                    #
#  Parameter : (1) The (short) name of the package to check/uncheck.    #
#              (2) Whether to check (1) or uncheck (0) the CheckBox.    #
#  Returns   : Nothing                                                  #
#  This subroutine allows you to check or uncheck the checkbox of a     #
#  particular package.  It also does the work of disconnecting the      #
#  signal/slot temporarily so that cellValueChanged doesn't get called  #
#  upon checking/unchecking a checkbox.                                 #
#########################################################################

  my $package = shift; 
  my $checkit = shift;

  # First, find the row corresponding to the given $package
  my $row = 0;
  my $found = 0;
  while ($row < numRows() && !$found)
    {
      if (text($row,0) eq $package)
        {
          $found = 1;
        }
      else
        {
          $row++;
        }
    }

  # We found the package's row - check/uncheck the box, making sure
  # that all signals are disabled before and re-enabled after.
  if ($found)
    {
      blockSignals(1);
      item($row,1)->setChecked($checkit);
      blockSignals(0);
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

  # Column 1 contains the checkboxes.  Don't do anything for other boxes.
  return if ($col != 1);  

  # We don't want to allow the user to uncheck core packages.  
  # So, when a core checkbox is clicked, make sure it's checked.
  if ((item($row,3)->text() eq 'core') &&
      (!(item($row,1)->isChecked())))
    {
      setCheckBoxForPackage(item($row,0)->text(),1);
      return;
    }

  # Then take appropriate action for the checkbox depending on if the 
  # GUI is running as the 'Selector' or as the 'Updater'. 
  (parent()->parent()->installuninstall > 0) ?
    checkboxChangedForUpdater($row) : checkboxChangedForSelector($row);
}

sub checkboxChangedForUpdater
{
#########################################################################
#  Subroutine: checkboxChangedForUpdater                                #
#  Parameter : The row of the changed table checkbox                    #
#  Returns   : Nothing                                                  #
#  This slot is called when the value of one of the packageTable's      #
#  checkbox is changed and the GUI is running as the 'Updater'.         #
#  We need to catch when the checkboxes are checked/unchecked so that   #
#  we can do requires/conflicts testing.                                #
#########################################################################

  my $row = shift;

  my $allPackages = SelectorUtils::getAllPackages();
  my $donothing = 0;
  my($reqhash,$conhash,$reqkey,$conkey);

  my $package = item($row,0)->text();

  # If we clicked on a checkbox, we should try to add/remove the 
  # corresponding package from the current package set.
  if (item($row,1)->isChecked())
    { # Checkbox has been checked.
      # Check for requires AND conflicts for the package.
      $reqhash = SelectorUtils::getRequiresList($reqhash,$package);
      $conhash = SelectorUtils::getConflictsList($reqhash);

      # Check to see if the conflicts and the requires list coincide
      foreach $conkey (keys %{ $conhash })
        {
          if ($reqhash->{$conkey})
            { # ERROR! Conflict - print error message and do nothing
              Carp::carp("ERROR! Package $conkey is required by AND " .
                         "conflicts with $package");
              $donothing = 1;
            }
        }

      # If there was no conflict, then select/unselect checkboxes
      if (!$donothing)
        { # Select all of the 'requires'
          foreach $reqkey (keys %{ $reqhash })
            {
              setCheckBoxForPackage($reqkey,1);
            }
          # Unselect all of the 'conflicts'
          foreach $conkey (keys %{ $conhash })
            {
              setCheckBoxForPackage($conkey,0);
            }
        }
    }
  else 
    { # Checkbox has been unchecked
      # Check for things that require it and unselect all of those
      # checkboxes EXCEPT for those buttons that are 'core'.
      $reqhash = SelectorUtils::getIsRequiredByList($reqhash,$package);
      foreach $reqkey (keys %{ $reqhash })
        {
          if (!((defined $allPackages->{$reqkey}{class}) &&
                ($allPackages->{$reqkey}{class} eq 'core')))
            {
              setCheckBoxForPackage($reqkey,0);
            }
        }
    }

  # We need to repaint the entire row in case there's a new text color.
  for (my $col = 0; $col < numCols(); $col++)
    {
      updateCell($row,$col);
    }
}

1;


package SelectorTable;

#########################################################################
                                                                                
=head1 NAME
                                                                                
SelectorTable - Specialized subclass of Qt::Table needed by the Selector.
                                                                                
=head1 SYNOPSIS

  my $selectTable = SelectorTable();
                                                                                
=head1 DESCRIPTION

I had to subclass QTable (rather than add a basic QTable in Designer) since
I needed control over the checkboxes, the "Config" pseudo-buttons, and the
sorting method when a column header is clicked.
                                                                                
=head1 METHODS
                                                                                
=over
                                                                                
=cut
                                                                                
#########################################################################
                                                                                
use strict;
use utf8;

use Qt;
use Qt::isa qw(Qt::Table);
use Qt::slots
    populateTable => [ 'const QString&' ],
    cellValueChanged => [ 'int', 'int' ],
    clickInCell => [ 'int', 'int', 'int', 'const QPoint&' ];

use lib "$ENV{OSCAR_HOME}/lib";
use lib "../Installer";
use OSCAR::Database;
use InstallerUtils;
use Carp;

# These local package variables/constants are used because I got tired 
# of renumbering all of the columns whenever I added a new column.
my $colShortName = 0;
my $colCheckbox = 1;
my $colConfig = 2;
my $colLongName = 3;
my $colClass = 4;
my $colLocation = 5;
my $colNumber = 6;    # Total number of columns

sub NEW
{
#########################################################################
 
=item C<NEW($parent, $name)>

The constructor for the SelectorTable class.

This returns a pointer to a new SelectorTable widget, which is a subclass of
Qt::Table.  It sets up the stuff for the table that never changes, like the
number of columns, headers, read-only status, etc.  Then it show()s it at
the end.  The table is organized as follows: 

  Col 0       Col 1      Col 2    Col 3      Col 4   Col 5
  ShortName   Checkbox   Config   LongName   Class   Location/Version

Column 0 is HIDDEN.  It's there just so that we have a key for the
$allPackages hash.  Column 1 is the checkbox without any text label.
Column 2 contains the pseudo-buttons (which are actually pixmaps) labeled
"Config" to launch the Configurator.

=cut

### @param $parent Pointer to the parent of this widget.  If empty (or null)
###                then this widget is a top-level window.
### @param $name   Name of the widget.  Will be set to "SelectorTable"
###                if empty (or null).

#########################################################################

  shift->SUPER::NEW(@_[0..1]);

  setName("SelectorTable") if (name() eq "unnamed");

  setNumCols($colNumber);
  horizontalHeader()->setLabel($colShortName,"Short Name");
  horizontalHeader()->setLabel($colCheckbox,"");
  horizontalHeader()->setLabel($colConfig,"Config");
  horizontalHeader()->setLabel($colLongName,"Package Name");
  horizontalHeader()->setLabel($colClass,"Class");
  horizontalHeader()->setLabel($colLocation,"Location/Version");
  hideColumn(0);   # The "ShortName" column is hidden, used for indexing only
  setShowGrid(0);
  verticalHeader()->hide();   # Get rid of the numbers along the left side
  setLeftMargin(0);
  setSelectionMode(Qt::Table::SingleRow());
  setFocusStyle(Qt::Table::FollowStyle());
  setColumnMovingEnabled(0);
  setRowMovingEnabled(0);
  setSorting(1);              # Sort method overridden below
  setColumnStretchable($colCheckbox,0);
  setColumnStretchable($colConfig,0);
  setColumnStretchable($colLongName,0);
  setColumnStretchable($colClass,1);
  setColumnStretchable($colLocation,1);
  setColumnReadOnly($colCheckbox,0);
  setColumnReadOnly($colConfig,1);
  setColumnReadOnly($colLongName,1);
  setColumnReadOnly($colClass,1);
  setColumnReadOnly($colLocation,1);
  adjustColumn($colCheckbox);    # Auto-resize these columns
  adjustColumn($colConfig);
  adjustColumn($colLongName);

  # When the value of any cell changes, call cellValueChanged.  Used so as 
  # to catch checkboxes changing on/off.
  Qt::Object::connect(this, SIGNAL 'valueChanged(int,int)',
                            SLOT   'cellValueChanged(int,int)');
  # When the user clicks on the "Config" buttons in Column 2, launch
  # the Configurator for that package.
  Qt::Object::connect(this, SIGNAL 'clicked(int,int,int,const QPoint&)',
                            SLOT   'clickInCell(int,int,int,const QPoint&)');
 
  show();
}

sub sortColumn
{
#########################################################################
 
=item C<sortColumn($column, $ascending, $wholeRows)>

Overridden sortColumn menthod.

This subroutine overrides the default sortColumn method in the QTable super
class.  Basically, we always want to sort whole rows when one of the column
headings is clicked.  Also, we want to keep the row selected the same so
that we don't have to change the information boxes.

=cut

### @param $column    The column number that was clicked (0-indexed).
### @param $ascending 1 for ascending sort, 0 for descending sort.
### @param $wholeRows 1 to sort whole rows, 0 to sort just 1 column

#########################################################################

  my $col = shift;
  my $ascending = shift;
  my $wholeRows = shift;

  my $currPack = "";

  # When the checkbox column header or "Config" pseudo-button column header
  # is clicked, sort based on long name instead.
  $col = $colLongName if (($col == $colCheckbox) || ($col == $colConfig));

  # If we have a row selected, we need to unselect it and reselect it
  # later since its row number will probably have changed after sorting.
  if (numSelections() == 1)
    {
      $currPack = item(selection(0)->bottomRow(),$colShortName)->text();
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
          $found = 1 if (item($currRow,$colShortName)->text() eq $currPack);
          $currRow++ if (!$found);
        }

      # If we found the package's new row, create a selection for it.
      if ($found)
        { 
          my $sel = Qt::TableSelection();
          $sel->init($currRow,$colShortName);
          $sel->expandTo($currRow,$colNumber-1);
          addSelection($sel);
          ensureCellVisible($currRow,$colCheckbox);
        }
    }
}

sub populateTable
{
#########################################################################
 
=item C<populateTable())>

Fill the SelectorTable with package information.

This subroutine should be called when you want to populate the table.  
It adds all of the packages and their corresponding info to the table.  

=cut

#########################################################################

  # Get the list of all available packages
  SelectorUtils::readAllPackages() if 
    (!$SelectorUtils::allPackagesReadIn);

  my $pixmap = InstallerUtils::getPixmap('config.png');

  my $rownum = 0;
  foreach my $pack (keys %{ $SelectorUtils::allPackages })
    {
      # Don't even bother to display non-installable packages
      next if ($SelectorUtils::allPackages->{$pack}{installable} != 1);

      setNumRows($rownum+1); 

      # Column 0 contains "short" names of packages
      my $item = Qt::TableItem(this,Qt::TableItem::Never(),$pack);
      setItem($rownum,$colShortName,$item);

      # Column 1 contains checkboxes
      my $checkbox = Qt::CheckTableItem(this,"");
      $checkbox->setChecked(
        $SelectorUtils::allPackages->{$pack}{install_allowed});
      setItem($rownum,$colCheckbox,$checkbox);

      # Column 2 contains the "Config" pixmap pseudo-buttons
      $item = Qt::TableItem(this,Qt::TableItem::Never(),"");
      $item->setPixmap($pixmap);
      setItem($rownum,$colConfig,$item);

      # Column 3 contains the long names of packages
      $item = Qt::TableItem(this,Qt::TableItem::Never(),
                $SelectorUtils::allPackages->{$pack}{package});
      setItem($rownum,$colLongName,$item);

      # Column 4 contains the "class" of packages
      $item = Qt::TableItem(this,Qt::TableItem::Never(),
                $SelectorUtils::allPackages->{$pack}{class});
      setItem($rownum,$colClass,$item);

      # Column 5 contains the Location + Version
      $item = Qt::TableItem(this,Qt::TableItem::Never(),
                $SelectorUtils::allPackages->{$pack}{location} . " " .
                  $SelectorUtils::allPackages->{$pack}{version});
      setItem($rownum,$colLocation,$item);

      $rownum++;
    }

  # Finally, sort the table on the LongName column and 
  # set its size automatically
  sortColumn($colLongName,1,1);
  adjustColumn($colCheckbox);
  adjustColumn($colConfig);
  adjustColumn($colLongName);
}

sub setCheckBoxForPackage
{
#########################################################################
 
=item C<setCheckBoxForPackage($package,$isChecked))>

Check/Uncheck the checkbox for a package.

This subroutine allows you to force check (C<$isChecked = 1>) or uncheck 
(C<$isChecked = 0>) the checkbox of a particular package.  It also does the
work of disconnecting the signal/slot temporarily so that cellValueChanged
doesn't get called upon checking/unchecking a checkbox.

=cut

### @param $package   The short name of the package to be (un)checked.
### @param $isChecked 1 for checked, 0 for unchecked.

#########################################################################

  my $package = shift; 
  my $isChecked = shift;

  # First, find the row corresponding to the given $package
  my $row = 0;
  my $found = 0;
  while ($row < numRows() && !$found)
    {
      if (text($row,$colShortName) eq $package)
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
      item($row,$colCheckbox)->setChecked($isChecked);
      setCheckboxForOda($package,$isChecked);    # Update oda database
      blockSignals(0);
    }
}

sub cellValueChanged
{
#########################################################################

=item C<cellValueChanged($row,$col))>

Slot called when one of the SelectorTable's cells is changed.

This slot is called when the value of one of the packageTable's cells is
changed.  Note that this method gets called not only when the user clicks on
one of the checkboxes, but also when the user selects a new row.  So take
action only when the user clicked on a checkbox.  We only want to update the
checked/unchecked status of packages.

=cut

### @param $row The row of the changed table cell.
### @param $col The column of the changed table cell.

#########################################################################

  my $row = shift;
  my $col = shift;

  # Column 1 contains the checkboxes.  Don't do anything for other boxes.
  return if ($col != $colCheckbox);  

  my $package   = item($row,$colShortName)->text();
  my $class     = item($row,$colClass)->text();
  my $isChecked = item($row,$colCheckbox)->isChecked();

  # We don't want to allow the user to uncheck core packages.  
  # So, when a core checkbox is clicked, make sure it's checked.
  if (($class eq 'core') && (!$isChecked))
    {
      setCheckBoxForPackage($package,1);
      return;
    }

  # Update the check/uncheck status for "install_allowed" in oda.
  setCheckboxForOda($package,$isChecked);
}

sub clickInCell
{
#########################################################################
 
=item C<clickInCell($row,$col,$button,$point)>

Slot called when user clicks on a cell in the table.

This subroutine is called when the user clicks on a cell in the table.  We
want to catch when the user clicks on one of the "Config" pseudo-buttons so
as to launch the Configurator for that package.  The first two parameters
are the row and column of the mouse click.  The third (mouse button pressed)
and fourth (mouse pointer location) parameters are not used here.

=cut

### @param $row    Table row of the mouse click.
### @param $col    Table column of the mouse click.
### @param $button Which mouse button was clicked.
### @param $point  Mouse position at time of the click.

#########################################################################

  my($row,$col,$button,$point) = @_;

  # Column 2 contains the "Config" button/pixmaps. 
  return if ($col != $colConfig);

  my $package = item($row,$colShortName)->text();

  print "Launch Configurator for $package\n";

}

sub setCheckboxForOda
{
#########################################################################
 
=item C<setCheckboxForOda($package,$isChecked)>

Update the check/uncheck data for "install_allowed" in oda.

When the user clicks on a checkbox, we need to update the "install_allowed"
information in oda for that package.  The "install_allowed" corresponds to
whether the package can be installed at all (or not).  If the checkbox is
checked (i.e. install_allowed = 1), then the information in the Configurator
for that package is used to determine where the package gets installed.  If
the checkbox is unchecked (i.e. install_allowed = 0), then the package does
NOT get installed ANYWHERE, regardless of the values set by the
Configurator for that package.

=cut

### @param $package   The short name of the package to be (un)checked.
### @param $isChecked 1 for checked, 0 for unchecked.

#########################################################################

  my($package,$isChecked) = @_;
  $isChecked = "0" if (!$isChecked);  # oda requirement

  # Update the oda database and $allPackages to reflect the 
  # new checkbox state.
  my $success = OSCAR::Database::database_execute_command(
    "modify_records packages packages.install_allowed~$isChecked " .
    "packages.name=$package");
  if ($success)
    { # Update the global $allPackages hash
      $SelectorUtils::allPackages->{$package}{install_allowed} = $isChecked;
    }
  else
    {
      Carp::carp("Could not do oda command " .
                 "'modify_records packages " .
                 "packages.install_allowed~$isChecked " .
                 "packages.name=$package'")
    }
}

1;

__END__
                                                                                
=back
                                                                                
=head1 SEE ALSO

http://doc.trolltech.com/
                                                                                
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
                                                                                
First Created on May 6, 2004
                                                                                
Last Modified on May 6, 2004
                                                                                
=cut
                                                                                
#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
#########################################################################


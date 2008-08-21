#########################################################################
#  File  : SelectorUtils.pm                                             #
#  Author: Terrence G. Fleury (tfleury@ncsa.uiuc.edu)                   #
#  Date  : April 24, 2003                                               #
#  This file contains a bunch of utility functions used by the          #
#  Selector.                                                            #
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
#  Copyright (c) 2005-2007 The Trustees of Indiana University.  
#                     All rights reserved.
#  Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                     Oak Ridge National Laboratory
#                     All rigths reserved.
#
# $Id$
#########################################################################

use strict;
use utf8;

package SelectorUtils;

use Qt;

use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Database;
use OSCAR::OpkgDB;
use OSCAR::OCA::OS_Detect;
use OSCAR::PackageSet qw (
                         get_local_package_set_list
                         );
use Data::Dumper;
use Carp;

my %options = ();
my @errors = ();

my $allPackages;        # Cached hash reference of all available packages
my $dependtree;         # Dependency tree for requires/conflicts
my $greenText;          # These are Qt::Color objects for the items in 
my $brightGreenText;    #    the SelectorTable when the GUI is run as
my $darkGreenText;      #    the 'Updater'.  Text gets colored Red or
my $redText;            #    Green depending if a package needs to be
my $brightRedText;      #    installed or uninstalled.  The 'darks' are
my $darkRedText;        #    the highlight colors.
my $colorsCreated = 0;  # Have we created the above colors yet?

sub addTypeNameFieldToPackage
{
#########################################################################
#  Subroutine: addTypeNameFieldToPackage                                #
#  Parameters: (1) The field name to add (ie. "provides", "requires",   #
#                  or "conflicts").                                     #
#              (2) The short name of the package to add the field to.   #
#  Returns   : Nothing                                                  #
#  This subroutine is called to add the "provides", "requires", and     #
#  "conflicts" fields to the $allPackages->{$package} hash.  Each of    #
#  these fields is actually an array of hash references, where each     #
#  hash reference has the two fields {name} and {type}.  So a sample    #
#  usage code fragment might look like this:                            #
#     my $requiresname = $allPackages->{lam}{requires}[0]->{name}       #
#     my $requirestype = $allPackages->{lam}{requires}[0]->{type}       #
#########################################################################

  my($field,$package) = @_;
  my $href;
  my @list = ();
  my $success = OSCAR::Database::get_packages_related_with_package (
        $field, $package, \@list, \%options, \@errors);
  Carp::carp("Could not do oda command 'get_packages_related_with_package " .
        "$field, $package'") if (!$success);
  foreach my $item_ref (@list)
    {
      my $type = $$item_ref{type};
      my $name = $$item_ref{p2_name};
      my $href;
      $href->{type} = $type;
      $href->{name} = $name;
      push @{ $allPackages->{$package}{$field} }, $href;
    }
}

sub getAllPackages # -> $allPackages
{
#########################################################################
#  Subroutine: getAllPackages                                           #
#  Parameters: None                                                     #
#  Returns   : Reference to a hash containing info about packages.      #
#  Any time you need to find out all the packages available for OSCAR   #
#  (and all associated information), call this subroutine.  It first    #
#  gets all package info from the oda database.  Then it uses opd       #
#  (OSCAR package downloader) to get information from various           #
#  repositories about additional packages available.  All information   #
#  is integrated into a single hash reference.  Info in the hash:       #
#     Information    How to access     Value                            #
#     -----------    -------------     -----                            #
#     ShortName      keys of the hash  string w/o spaces                #
#     ShortName      {name}            duplication of above info        #
#     LongName       {package}         long string                      #
#     Installable    {installable}     0 or 1                           #
#     Class          {class}           core/included/third party        #
#     Information    {description}     long string                      #
#     Version        {vesrion}         long version string              #
#     Location       {location}        OSCAR or OPD                     #
#     Provides       {provides}        array of hash references:        #
#     Requires       {requires}        array of hash references:        #
#     Conflicts      {conflicts}       array of hash references:        #
#                    {provides}[0]->{name} - Name of thing provided     #
#                    {provides}[0]->{type} - package, rpm, file, etc.   #
#     Packager Name  {packager_name}   Name(s) of packager              #
#     Packager Email {packager_email}  Email address(es) of packager(s) #
#########################################################################

  # If this function has been called once, then it should have already
  # found all available packages and stored it in the $allPackages cache.
  return $allPackages if ($allPackages);

  # First, get information on all packages in the local OSCAR packages dir
  my @requested = ("package", "__class", "description",
                   "version", "packager"
                   # "filter_architecture","filter_distribution",
                   # "filter_distribution_version"
                  );

  my %opkgs = ();

  my %scope = ();
  %opkgs  = OSCAR::OpkgDB::opkg_hash_available( class => "api", %scope);
    print "----------> Found OPKGs\n";
    print Dumper %opkgs;
  $allPackages = \%opkgs;

  my @packages = ();
  foreach my $pack_ref (values(%opkgs)){
    my $pack = $$pack_ref{package};
    foreach my $key (keys %$pack_ref){
        $allPackages->{$pack}{$key} = $$pack_ref{$key};
    }
  }

  my $version;
  my $href;
  foreach my $pack (keys %{ $allPackages })
    {
      undef $href;
      $allPackages->{$pack}{location} = "OSCAR";

      #no_yet# # Next, get the provides, requires, and conflicts lists for each
      #no_yet# # package.  Here the {provides}, {requires}, and {conflicts} fields
      #no_yet# # are arrays of hash references, each containing the two fields {name}
      #no_yet# # and {type}.  
      #no_yet# addTypeNameFieldToPackage("provides",$pack);
      #no_yet# if ((!defined $allPackages->{$pack}{provides}) ||
      #no_yet#     (scalar @{ $allPackages->{$pack}{provides} } < 1))
      #no_yet#   { # If nothing else, a package provides itself.
      #no_yet#     my $href;
      #no_yet#     $href->{type} = "package";
      #no_yet#     $href->{name} = $pack;
      #no_yet#     push @{ $allPackages->{$pack}{provides} }, $href;
      #no_yet#   }
      #no_yet# 
      #no_yet# addTypeNameFieldToPackage("requires",$pack);
      #no_yet# addTypeNameFieldToPackage("conflicts",$pack);
    }

#  getDependencyTree();
  return $allPackages;
}

sub getSubField ($$)
{
#########################################################################
#  Subroutine : getSubField                                             #
#  Parameters : 1. The short name of an OSCAR package.                  #
#               2. The subfield name (can be one of 'provides',         #
#                  'requires', or 'conflicts').                         #
#  Returns    : A hash reference containing all of the names for the    #
#               passed-in subfield.                                     #
#  This subroutine is called to get the "provides", "requires", and     #
#  conflicts.  It returns a list of those fields defined in             #
#  $allPackages.  Note that the "type" field must either be             #
#  'package' (meaning an OSCAR package) or empty (so default to an      #
#  OSCAR package).                                                      #
#########################################################################

  my($package, $field) = @_;
  my($rethash);

  if (!defined $package || !defined $field) {
    carp "ERROR: undefined package or field";
    return undef;
  }

  if ($package && $field && (defined $allPackages->{$package}{$field})) {
      foreach my $href (@{ $allPackages->{$package}{$field} } ) { 
          # If the 'type' field is undefined OR defined but empty, 
          # assume that 'type' is 'package'.
          if ( (!defined $href->{type}) ||
               ((defined $href->{type}) && ($href->{type} eq '')) ||
               ((defined $href->{type}) && ($href->{type} eq 'package')) ) {
              $rethash->{$href->{name}} = 1 if (defined $href->{name});
          }
      }
  }

  return $rethash;
}

sub getDependencyTree
{
#########################################################################
#  Subroutine : getDependencyTree                                       #
#  Parameters : None                                                    #
#  Returns    : Nothing                                                 #
#  This subroutine builds up the dependency tree for later use.  We     #
#  need to do this since the 'requires' and 'conflicts' fields can use  #
#  names (aliases) defined in the 'provides' fields which may be        #
#  different than the name of the package directory.  By building this  #
#  tree using only package directory names, it's easier to handle       #
#  checkbutton pushes later.  Each package might have other packages    #
#  it requires (which means that there are packages that are required   #
#  BY other packages) and other packages that it conflicts with.  Thus  #
#  each 'requires' and 'conflicts' needs a bidirectional link in the    #
#  dependency tree.  Access items in the dependency like this:          #
#      if ($dependtree->{packageA}{requires}{packageB}) { ... }         #
#      if ($dependtree->{packageB}{isrequiredby}{packageA}) { ... }     #
#      if ($dependtree->{packageC}{conflictswith}{packageD}) { ... }    #
#########################################################################

  return $dependtree if ($dependtree);

  # First, create a mapping for what provides what
  getAllPackages();
  my $providesmap;
  foreach my $package (keys %{ $allPackages })
    {
      my($providesaliashash) = getSubField($package,'provides');
      foreach my $provideskey (keys %{ $providesaliashash } )
        {
          $providesmap->{$provideskey} = $package;
        }
    }

  # Then build dependency tree for requirements and conflicts
  foreach my $package (keys %{ $allPackages })
    { # First the 'requires' list
      my($reqaliashash) = getSubField($package,'requires');
      foreach my $hashkey (keys %{ $reqaliashash } )
        { # If A requires B, then B is "required by" A
          $dependtree->{$package}{requires}{$providesmap->{$hashkey}} = 1;
          $dependtree->{$providesmap->{$hashkey}}{isrequiredby}{$package} = 1;
        }
      # Then the 'conflicts' list - notice conflicts are bidirectional
      my($conaliashash) = getSubField($package,'conflicts');
      foreach my $hashkey (keys %{ $conaliashash } )
        {
          $dependtree->{$package}{conflictswith}{$providesmap->{$hashkey}} = 1;
          $dependtree->{$providesmap->{$hashkey}}{conflictswith}{$package} = 1;
        }
    }

  return $dependtree;
}

sub getRequiresList
{
#########################################################################
#  Subroutine: getRequiresList                                          #
#  Parameters: 1. A hash of required packages.                          #
#              2. The package we are checking for requirements.         #
#  This recursive subroutine is called when a checkbutton is selected.  #
#  It takes the name of a package and (recursively) finds all of the    #
#  packages that it needs.  This list is a simple boolean hash returned #
#  as a hash ref with the required packages as the keys.                #
#########################################################################

  my($packhash,$package) = @_;

  # Mark this package as required
  $packhash->{$package} = 1;
  # For each package in the list, check for its list of required packages
  foreach my $hashkey (keys %{ $dependtree->{$package}{requires} } )
    {
      $packhash = getRequiresList($packhash,$hashkey) if
        (!defined $packhash->{$hashkey});
    }

  return $packhash;
}

sub getIsRequiredByList
{
#########################################################################
#  Subroutine: getIsRequiredByList                                      #
#  Parameters: 1. A hash of required packages.                          #
#              2. The package we are checking for dependencies.         #
#  This recursive subroutine is called when a checkbutton is            #
#  unselected.  Similar to getRequiresList, this subroutine takes the   #
#  name of a package and (recursively) finds all of the packages that   #
#  need it (ie. "is required by").  This list is a simple boolean hash  #
#  returned as a hash ref with the requiring packages as the keys.      #
#########################################################################

  my($packhash,$package) = @_;

  # Mark this package as "required by" something else
  $packhash->{$package} = 1;
  # For each package in the list, check for its list of requiring packages
  foreach my $hashkey (keys %{ $dependtree->{$package}{isrequiredby} } )
    {
      $packhash = getIsRequiredByList($packhash,$hashkey) if
        (!defined $packhash->{$hashkey});
    }

  return $packhash;
}

sub getConflictsList
{
#########################################################################
#  Subroutine: getConflictsList                                         #
#  Parameter : A hash of required packages.                             #
#  This subroutine is called when a checkbutton is selected.  It takes  #
#  in a list of required packages (generated by getRequiredList) and    #
#  checks each one for a list of conflicts.  The union of all of the    #
#  conflicts is returned as a hash ref with the conflicting packages    #
#  as the keys.                                                         #
#########################################################################

  my($reqhash) = @_;
  my($conhash);

  foreach my $reqkey (keys %{ $reqhash } )
    {
      foreach my $conkey (keys %{ $dependtree->{$reqkey}{conflictswith} } )
        {
          $conhash->{$conkey} = 1
        }
    }

  return $conhash;
}

# GV: this function should not be used anymore, the Default package set should be
# defined from share/package_sets/Default/{distro}-{version}-{arch}
sub createDefaultPackageSet # -> ($success)
{
#########################################################################
#  Subroutine: createDefaultPackageSet                                  #
#  Parameters: None                                                     #
#  Returns   : Success (1) or failure (0)                               #
#  This subroutine should be called when there are no package sets      #
#  currently in the oda database.  We first create a new package set    #
#  named "Default".  Then we make it the "selected" package set.        #
#  Finally we add all available packages to this package set.           #
#########################################################################

  # First create a new package set name 'Default'
  my $success = OSCAR::Database::set_groups(
        "Default",\%options,\@errors,undef);
  if ($success)
    { 
      # Make Default the "selected" package set
      $success = OSCAR::Database::set_groups_selected(
        "Default",\%options,\@errors);

      # Then, add all packages to this Default set
      getAllPackages();
      foreach my $pack (keys %{ $allPackages })
        {
          $success = OSCAR::Database::set_group_packages(
                "Default",$pack,2,\%options,\@errors);
          Carp::carp("Could not do oda command 'set_group_packages " .
            "$pack, Default'") if (!$success);
        }
    }

  return $success;
}

sub populatePackageSetList
{
#########################################################################
#  Subroutine: populatePackageSetList                                   #
#  Parameters: A widget to add items to.                                #
#  Returns   : Nothing                                                  #
#  This subroutine takes in a widget which has both the "insertItem"    #
#  and "clear" methods and adds package set names in alphabetical       #
#  order.  This is used by the packageSetComboBox and the               #
#  packageSetsListBox.                                                  #
#########################################################################

  my $widget = shift;

  return if (!$widget);

  $widget->clear();
  my @packageSets;           # List of package sets in oda
#  my $createDefault = 0;     # Should we create a "Default" package set?

  my @groups_list = ();  
  my $success = OSCAR::Database::get_groups_for_packages(
        \@groups_list,\%options,\@errors,undef);

  # We also scan package sets defined in share/package_sets
  my @local_package_sets = get_local_package_set_list ();
  @packageSets = (@packageSets, @local_package_sets);

  # !!!WARNING!!! Currently we treat package sets in share/package_sets and those 
  # defined in the database in different ways. That may create duplicate entries
  foreach my $groups_ref (@groups_list){
    push @packageSets, $$groups_ref{group_name};
  }  
  if ($success)
    {
      if ((scalar @packageSets) > 0) # Make sure there's at least 1 package set
        {
          foreach my $pkg (sort { lc($a) cmp lc($b) } @packageSets)
            { # Insert Package Set names in alphabetical order - ignore case
              $widget->insertItem($pkg,-1);
            }

          # For the packageSetComboBox, set the "selected" package set
          if ($widget->className() eq "QComboBox")
            {
              my $selected_group = OSCAR::Database::get_selected_group(\%options, \@errors);
              $widget->setCurrentText($selected_group) if (scalar @packageSets > 0);
            }
        }
    }
  emit SelectorManageSets::refreshPackageSets();
}

sub compactSpaces
{
#########################################################################
#  Subroutine: compactSpaces                                            #
#  Parameters: (1) The string from which to remove spaces               #
#              (2) If $compact==1, then compress multi spaces to 1      #
#              (3) If $commas==1, then change commas to spaces          #
#  Returns   : The new string with spaces removed/compressed.           #
#  This subroutine strips off the leading and trailing spaces from a    #
#  string.  You can also pass a second parameter flag (=1) to compact   #
#  multiple intervening spaces down to one space.  You can also pass a  #
#  third parameter flag (=1) to change commas to spaces prior to doing  #
#  the space removal/compression.                                       #
#########################################################################

  my($string,$compact,$commas) = @_;

  $string =~ s/,/ /g if ($commas);    # Change commas to spaces
  $string =~ s/^ *//;                 # Strip off leading spaces
  $string =~ s/ *$//;                 # Strip off trailing spaces
  $string =~ s/ +/ /g if ($compact);  # Compact multiple spaces

  $string;  # Return string to calling procedure;
}

sub getTableItemColorGroup
{
#########################################################################
#  Subroutine: getTableItemColorGroup                                   #
#  Parameters: (1) TableItem which (possibly) needs a new QColorGroup   #
#              (2) The current QColorGroup for the TableItem            #
#  Returns   : The updated QColorGroup                                  #
#  This subroutine gets called by the paint methods in                  #
#  SelectorTableItem and SelectorCheckTableItem.  If the GUI is being   #
#  run as the 'Updater', we want to change the color of the text in     #
#  the SelectorTable to reflect what actions need to be taken.  Red     #
#  text indicates that the package needs to be uninstalled.  Green      #
#  text indicates that the package needs to be installed.               #
#########################################################################

  my $tableItem = shift;
  my $qcolorgroup = shift;

  # Create a copy of the passed-in QColorGroup to possibly modify
  my $cg = Qt::ColorGroup($qcolorgroup);

  if ($tableItem->table()->parent()->parent()->installuninstall)
    { # Change font color depending on 'installed' bit
      my $row = $tableItem->row();
      my $col = $tableItem->col();
      my $packagesInstalled = $tableItem->table()->getPackagesInstalled();
      my $package = $tableItem->table()->item($row,0)->text();
      my $checked = $tableItem->table()->item($row,1)->isChecked();

      # If package is installed but unchecked, then need to uninstall
      if (($packagesInstalled->{$package}) && (!$checked))
        { # Need to uninstall => set color to 'red'
          $cg->setColor(Qt::ColorGroup::Text(),$redText);
          $cg->setColor(Qt::ColorGroup::Highlight(),$darkRedText);
          $cg->setColor(Qt::ColorGroup::HighlightedText(),$brightRedText);
        }

      # If package is uninstalled and checked, then need to install
      if ((!($packagesInstalled->{$package})) && ($checked))
        { # Need to install => set color to 'green'
          $cg->setColor(Qt::ColorGroup::Text(),$greenText);
          $cg->setColor(Qt::ColorGroup::Highlight(),$darkGreenText);
          $cg->setColor(Qt::ColorGroup::HighlightedText(),$brightGreenText);
        }
    }

  return $cg;
}

sub createColors
{
#########################################################################
#  Subroutine: createColor                                              #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine is called when the SelectorTable is created.  It     #
#  creates the QColors needed when the GUI is run as the 'Updater'.     #
#########################################################################

  if (!$colorsCreated)
    {
      $colorsCreated = 1;
      $greenText = Qt::Color(0,150,0);
      $brightGreenText = Qt::Color(100,255,100);
      $darkGreenText = Qt::Color(0,80,0);
      $redText = Qt::Color(150,0,0);
      $brightRedText = Qt::Color(255,100,100);
      $darkRedText = Qt::Color(80,0,0);
    }
}

1;


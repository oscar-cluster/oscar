package SelectorUtils;

#########################################################################
                                                                                
=head1 NAME
                                                                                
SelectorUtils - Various utility functions used by the Selector (and
                possibly other Tools).
                                                                                
=head1 SYNOPSIS

  use SelectorUtils;
  readAllPackages();
  my $longname = $allPackages->{kernel_picker}{description};

                                                                                
=head1 DESCRIPTION
                                                                                
=head1 METHODS
                                                                                
=over
                                                                                
=cut
                                                                                
#########################################################################

use strict;
use utf8;

use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Database;
use Carp;

use Exporter;
our (@ISA,@EXPORT,$VERSION);
$VERSION = 1.0;
@ISA = ("Exporter");
@EXPORT = qw( readAllPackages
              getRequiresList
              getIsRequiredByList
              getConflictsList
              $allPackages
              $allPackagesReadIn
            );

our $allPackages;           # Cached hash reference of all available packages
our $allPackagesReadIn = 0; # Flag if readAllPackages is called at least once
my $dependtree;             # Dependency tree for requires/conflicts

sub readAllPackages 
{
#########################################################################
                                                                               
=item C<readAllPackages()>

Read information about all packages into the global $allPackages
hash reference.

Any time you need to (re)read oda to get information about all the packages
available for OSCAR (and all associated information), call this subroutine.
It first gets all package info from the oda database.  All information is
integrated into a single hash reference which is stored in the global
variable $allPackages.

Info in the hash:

  Information    How to access     Value
  -----------    -------------     -----
  ShortName      keys of the hash  string w/o spaces
  ShortName      {name}            duplication of above info
  LongName       {package}         long string
  Installable    {installable}     0 or 1
  Class          {class}           core/included/third party
  Information    {description}     long string
  Version        {vesrion}         long version string
  Location       {location}        OSCAR or OPD
  Provides       {provides}        array of hash references:
  Requires       {requires}        array of hash references:
  Conflicts      {conflicts}       array of hash references:
                 {provides}[0]->{name} - Name of thing provided
                 {provides}[0]->{type} - package, rpm, file, etc.
  Packager Name  {packager_name}   Name(s) of packager
  Packager Email {packager_email}  Email address(es) of packager(s)

For example, to find out the version number string of the kernel_picker
package, you would do the following:

  readAllPackages();
  my $version = $allPackages->{kernel_picker}{version};

Usually, the information is read from the oda database only a single time to
save on execution time.  However, if you need to reread the oda database,
simply call this subroutine again.
                                                                               
=cut

#########################################################################

  # Clear out the global $allPackages hash reference
  my %opkgs = ();
  $allPackages = \%opkgs;
  $allPackagesReadIn = 1;

  # First, get information on all packages in the oda database
  my @packages = ();
  OSCAR::Database::get_packages(\@packages);
  foreach my $package_ref (@packages){
    $opkgs{$$package_ref{package}} = $package_ref;
  }

  my $version;
  my $href;
  foreach my $pack (keys %{ $allPackages })
    {
      undef $href;
      # For each of the OSCAR packages read in above, add a "location" field
      # to correspond to the Location column of the packagesTable.  
      $allPackages->{$pack}{location} = 
        (($allPackages->{$pack}{directory} =~ /\/var\/lib\/oscar\/packages/) ?
         "OPD" : "OSCAR");

      # Next, get the provides, requires, and conflicts lists for each
      # package.  Here the {provides}, {requires}, and {conflicts} fields
      # are arrays of hash references, each containing the two fields {name}
      # and {type}.  
      addTypeNameFieldToPackage($pack,"provides");
      if ((!defined $allPackages->{$pack}{provides}) ||
          (scalar @{ $allPackages->{$pack}{provides} } < 1))
        { # If nothing else, a package provides itself.
          my $href;
          $href->{type} = "package";
          $href->{name} = $pack;
          push @{ $allPackages->{$pack}{provides} }, $href;
        }

      addTypeNameFieldToPackage($pack,"requires");
      addTypeNameFieldToPackage($pack,"conflicts");
    }

  getDependencyTree();
}

sub addTypeNameFieldToPackage
{
#########################################################################
                                                                                
=item C<addTypeNameFieldToPackage($package,$field)>

Add the provides/requires/conflicts fields to the $allPackages->{$package}
hash.

This subroutine is called by readAllPackages() to add arrays to the
$allPackages hash for the 'provides', 'requires', and 'conflicts' field.
The first argument is the 'short' name of the package.  The second argument
is the name of the field to add ('provides', 'requires', or 'conflicts').  

Each of the provides/requires/conflicts fields is actually an array of hash
references where each hash reference has the two fields {name} and {type}.
So a sample usage code fragment would be:

  my $requiresname = $allPackages->{lam}{requires}[0]->{name} 
  my $requirestype = $allPackages->{lam}{requires}[0]->{type}

=cut

### @param $package The short name (i.e. directory) of the package.
### @param $field   The name of the field to add.  Should be one of 
###                 'provides', 'requires', or 'conflicts'.

#########################################################################

  my($package,$field) = @_;
  my $href;
  my @list = ();
#  my $success = OSCAR::Database::database_execute_command(
#    "read_records packages_$field package=$package type name", \@list);
#  Carp::carp("Could not do oda command 'read_records packages_$field ".
#       "package=$package type name'") if (!$success);
  foreach my $item (@list)
    {
      my($type,$name) = split / /, $item, 2;
      my $href;
      $href->{type} = $type;
      $href->{name} = $name;
      push @{ $allPackages->{$package}{$field} }, $href;
    }
}

sub getSubField
{
#########################################################################
                                                                                
=item C<getSubField($package,$field)>

Return a list of the provides/requires/conflicts for a package.

This subroutine is called by getDependencyTree to get a hash reference
containing all of the names for the passed-in subfield.  The keys of this
hash reference are the packages provided/required/conflicted by the
passed-in package.

B<Note> that right now, we only deal with 'type' fields equal to 'package'
(or empty).  This will need to be fixed so as to be able to deal with rpms,
files, etc.

=cut

### @param $package The short name (i.e. directory) of the package.
### @param $field   The name of the field to add.  Should be one of 
###                 'provides', 'requires', or 'conflicts'.
### @return A hash reference containing all of the names of the passed-in
###         field.

#########################################################################

  my($package,$field) = @_;
  my($rethash);

  if ($package && $field && (defined $allPackages->{$package}{$field}))
    {
      foreach my $href (@{ $allPackages->{$package}{$field} } )
        {
          if (((defined $href->{type}) && ($href->{type} eq 'package')) ||
              (!defined $href->{type}) )
            {
              $rethash->{$href->{name}} = 1 if (defined $href->{name});
            }
        }
    }

  return $rethash;
}

sub getDependencyTree
{
#########################################################################
                                                                                
=item C<getDependencyTree()>

Populate the package-scoped $dependtree hash reference for use later, and
return the dependency tree.

This subroutine builds up the dependency tree (stored in the
package-scoped variable $dependtree) for later use.  Once calculated, we
return the dependency tree to the calling routine.  

We need the dependency tree since the 'requires' and 'conflicts' fields can
use names (aliases) defined in the 'provides' fields which may be different
than the name of the package directory.  By building this tree using only
package directory names, it's easier to handle checkbutton pushes later.
Each package might have other packages it requires (which means that there
are packages that are required BY other packages) and other packages that it
conflicts with.  Thus each 'requires' and 'conflicts' needs a bidirectional
link in the dependency tree.  

Access items in the dependency like this:

  if ($dependtree->{packageA}{requires}{packageB}) { ... }
  if ($dependtree->{packageB}{isrequiredby}{packageA}) { ... }
  if ($dependtree->{packageC}{conflictswith}{packageD}) { ... }

=cut

### @return The dependency tree build from provides/requires/conflicts.

#########################################################################

  # If we already made the $dependtree, then just return it.
  return $dependtree if ($dependtree);

  # First, create a mapping for what provides what
  readAllPackages() if (!$allPackagesReadIn); # Results stored in $allPackages
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

=item C<getRequiresList($package,$packhash)>

Return a hash reference whose keys are all of the packages required by the
passed-in package.

This recursive subroutine is called when a checkbutton is selected.  It
takes the name of a package and (recursively) finds all of the packages that
it 'requires'.  This list is a simple boolean hash returned as a hash
reference with the required packages as the keys.  

=cut

### @param $package  The name of the package to search for required packages.
### @param $packhash A hash reference containing the growing collection of
###                  required packages.  Package names are keys, values are
###                  '1'.  This is needed for recursion.
### @return A hash reference of packages required by the passed-in package.

#########################################################################

  my($package,$packhash) = @_;

  # Mark this package as required
  $packhash->{$package} = 1;
  # For each package in the list, check for its list of required packages
  foreach my $hashkey (keys %{ $dependtree->{$package}{requires} } )
    {
      $packhash = getRequiresList($hashkey,$packhash) if
        (!defined $packhash->{$hashkey});
    }

  return $packhash;
}

sub getIsRequiredByList
{
#########################################################################

=item C<getIsRequiredByList($package,$packhash)>

Return a hash reference whose keys are all of the packages that require the
passed-in package.

This recursive subroutine is called when a checkbutton is unselected.
Similar to gerRequiresList, this subroutine takes the name of a package and
(recursively) finds all of the packages that need it (i.e. "is required
by").  This list is a simple boolean hash returned as a hash reference with
the required packages as the keys.  

=cut

### @param $package  The name of the package to search for packages
###                  requiring it.
### @param $packhash A hash reference containing the growing collection of
###                  requiring packages.  Package names are keys, values are
###                  '1'.  This is needed for recursion.
### @return A hash reference of packages requiring the passed-in package.

#########################################################################

  my($package,$packhash) = @_;

  # Mark this package as "required by" something else
  $packhash->{$package} = 1;
  # For each package in the list, check for its list of requiring packages
  foreach my $hashkey (keys %{ $dependtree->{$package}{isrequiredby} } )
    {
      $packhash = getIsRequiredByList($hashkey,$packhash) if
        (!defined $packhash->{$hashkey});
    }

  return $packhash;
}

sub getConflictsList
{
#########################################################################

=item C<getConflictsList($packhash)>

Return a hash reference whose keys are all of the packages that conflict
with the passed-in package.

This subroutine is called when a checkbutton is selected.  It takes in a
list of required packages (generated by getRequiresList) and checks each one
for a list of conflicts.  The union of all of the conflicting packages is
returned as a hash reference whose keys are the confliciting packages (and
values are '1').

=cut

### @param $packhash A hash reference containing the all packages for which
###                  you wish to find conflicts (typically generated by  
###                  getRequiresList).
### @return A hash reference of packages conflicting with the packages in 
###         the passed-in hash reference.

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

1;

__END__
                                                                                
=back
                                                                                
=head1 SEE ALSO
                                                                                
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


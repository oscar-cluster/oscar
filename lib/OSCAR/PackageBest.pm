package OSCAR::PackageBest;


# Copyright (c) 2003, The Board of Trustees of the University of Illinois.
#                     All rights reserved.

#   $Header: /home/user5/oscar-cvsroot/oscar/lib/OSCAR/PackageBest.pm,v 1.16 2003/06/27 15:16:53 brechin Exp $

#   Copyright (c) 2001 International Business Machines
 
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
 
#   Michael Chase-Salerno <mchasal@users.sf.net>
#   Sean Dague <sdague@users.sf.net>
#
#
#   ************THIS FILE IS FROM THE SYSTEMINSTALLER LIBRARY*************
#   Changes shoule be made to that version and resynced here. We will be 
#   doing something nicer in the future, but for now, manually sync the files.
#

use strict;

use Carp;

use vars qw($VERSION @EXPORT);
use POSIX;
use base qw(Exporter);

@EXPORT = qw(find_files find_best);


$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# Finds the best version of files to use based on an rpm list
# Input:  a parameter list containing the following:
#       PKGDIR  The location of the packages
#       PKGLIST A reference to a list of desired packages
#   and optionally:
#       ARCH    The target archtecture, default: current arch
#       RPMRC   The rpmrc filename, default: /usr/lib/rpm/rpmrc
#       CACHEFILE The name for the cachefile, default: .pkgcache
# 
# Output: A hash whose keys are the package name and whose
# values are the filenames, as well as a scalar indicating
# whether the routine succeeded (1) or not (0), since an empty
# hash is not necessarily indicative of an error.
sub find_files () {

    my %empty;
    my %args = (
            ARCH            => (uname)[4],
            RPMRC           => "/usr/lib/rpm/rpmrc",
            CACHEFILE       => ".pkgcache",
            PKGDIR          => "",
            PKGLIST         => [],
            @_,
    );

    my @compatlist; my $RPM_TABLE; 

    unless (cache_gen($args{PKGDIR},$args{CACHEFILE})) {
	return (0, %empty);
    }

    unless (@compatlist=gen_compat_list($args{ARCH},$args{RPMRC})) {
	return (0, %empty);
    }
    unless ($RPM_TABLE=populate_rpm_table($args{PKGDIR},$args{CACHEFILE})) {
	return (0, %empty);
    }

    return find_best_files($RPM_TABLE,\@compatlist,@{$args{PKGLIST}});
}

# Finds the highest versions and best architectures for rpms
# Input: Ref to the rpm table info
#        Ref to the ordered list of compatable rpms
#        List of rpms desired
# Output: filelist or null.
# TODO: it seems that the description of the output is just wrong... That should
# be fixed.
sub find_best_files {
    my $RPM_TABLE=shift;
    my $compatlist=shift;
    my @rpms = @_;
    my %files;
    my $missing;
    my $file;
    my $pkg;
    my $version; my $release; my $arch;

    foreach my $rpm (@rpms) {
        my $arch = find_best_arch($RPM_TABLE,$compatlist,$rpm);
        if(!$arch) {
                carp("Couldn't find file for $rpm.");
                $missing++;
                next;
        }

        if (defined $RPM_TABLE->{$arch}->{$rpm}->{FILENAME}) {
                $file=$RPM_TABLE->{$arch}->{$rpm}->{FILENAME};
                $pkg=$RPM_TABLE->{$arch}->{$rpm}->{PKGNAME};
        } else {
                my $version = find_best(keys %{$RPM_TABLE->{$arch}->{$rpm}});
                if(!defined($version)) {
                        carp("Couldn't find file for $rpm.");
                        $missing++;
                        next;
                }
                my $release = find_best(keys %{$RPM_TABLE->{$arch}->{$rpm}->{$version}});
                if(!defined($release)) {
                        carp("Couldn't find file for $rpm.");
                        $missing++;
                        next;
                }
                $file = $RPM_TABLE->{$arch}->{$rpm}->{$version}->{$release}->{FILENAME};
                $pkg = $RPM_TABLE->{$arch}->{$rpm}->{$version}->{$release}->{PKGNAME};
        }
        $files{$pkg}=$file;
    }
    if ($missing) {
	my %empty;
	return (0, %empty);
    }
    return (1, %files);
}

# Generates the compatability list from the rpmrc file.
# Input: the desired architecture.
# Output: return code and a list of data:
#         Return code           Data contents
#         0(ok)                 Ordered list of compat archs
#         1                     misc error messages
sub gen_compat_list {
    my $arch=shift;
    my $rpmrcfile=shift;
    my %RPM_COMPAT;
    my @list=@_;
    my $line;
    local *COMPF;

    # Read in the compat matrix from the rpmrc file
    if (! %RPM_COMPAT){
            if (! open(COMPF,"$rpmrcfile")) {
                    carp("Couldn't read rpmrc file $rpmrcfile");
                    return;
            }
            while ($line=<COMPF>) {
                    chomp $line;
                    my ($tag,$arch,$carchs)=split(/:/,$line);
                    next unless(defined $tag);
                    if ($tag eq "arch_compat") {
                            $carchs=~s/^ //;
                            $arch=~s/^ //;
                            # chuck multiples for now
                            my ($carch,$junk)=split(/ /,$carchs);
                            $RPM_COMPAT{$arch}=$carch; 
                    }
            }
            close(COMPF);
            $list[0]=$arch; # Prime the list with the requested arch.
    }
    return resolve_compat_chain(\%RPM_COMPAT,@list);
}

sub resolve_compat_chain {
        # Recursively generate a list based on the rpm compat data
        # Input: a ref to the rpm compat data
        #        the compatability list so-far
        # Output: the complete compat list.
        my $RPM_COMPAT=shift;
        my @list=@_;
        # Now do the recursive stuff to build a compat chain.
        my $last=scalar(@list)-1;
        if (defined $$RPM_COMPAT{$list[$last]}){
                push @list,$$RPM_COMPAT{$list[$last]};
                return resolve_compat_chain($RPM_COMPAT,@list);
        } else {
                return @list;
        }

}

sub populate_rpm_table {
    # Gathers the data from the rpm files
    # Input: directory with rpms
    # Output: return code and a scalar data item:
    #         Return code           Data contents
    #         0(ok)                 Reference to rpm table
    #         1                     Error message
    my $dir = shift;
    my $cachefile=shift;
    my $RPM_TABLE;
    local *CACHE;
    unless (open(CACHE,"<$dir/$cachefile")) {
            carp("Can't open cache file $dir/$cachefile.");
            return;
    }
    while(<CACHE>) {
        my ($name, $version, $release, $arch, $file, $size) = split;
        # Do some sanity checking to see that name is actually there
        if($name) {
            $RPM_TABLE->{$arch}->{$name}->{$version}->{$release}->{FILENAME} = $file;
            $RPM_TABLE->{$arch}->{$name}->{$version}->{$release}->{PKGNAME} = $name;
            my $rpmname="$name-$version-$release";
            $RPM_TABLE->{$arch}->{$name}->{$version}->{$release}->{RPMNAME} = $rpmname;
            # A shortcut for finding based on full name.
            $RPM_TABLE->{$arch}->{$rpmname} = $RPM_TABLE->{$arch}->{$name}->{$version}->{$release};
        }
    }
    close(CACHE);
    return $RPM_TABLE;
}

sub find_best {
        # Sort an array and return the top of the sort
        # Input: array to be sorted
        # Output: the "highest" element.
        my @versions = @_;

        my @best = ();

        @best = sort compare_versions @versions;

        return shift @best;
}

#########################################################################
#  Subroutine name : compareversion                                     #
#  Parameters : Two version strings to compare                          #
#  Returns    : +1 if the first version string is higher,               #
#                0 if the two version strings are equal,                #
#               -1 if the second version string is higher               #
#  Written by : Terry Fleury (tfleury@ncsa.uiuc.edu)                    #
#  This subroutine is used for comparing two version strings that you   #
#  might find in an rpm filename.  It is a recursive function.  It      #
#  strips off the leading digits/letters and compares until we find     #
#  a difference or until the strings are empty.  Note that this         #
#  subroutine is written so that you can use it as the sorting function #
#  for 'sort'.                                                          #
#########################################################################
sub compareversion ($$) # ($a,$b) -> +1|0|-1
{ 
  my($a,$b) = @_;

  my $retval = 0;  # The value to be returned

  # Break $a and $b into two parts - split by a period, dash, or comma.
  # The first parts are $acmp and $bcmp.  These are the substrings
  # that we are concerned about for this pass through.
  my($acmp,$aremain) = split /[\.\-\,]/, $a, 2;
  my($bcmp,$bremain) = split /[\.\-\,]/, $b, 2;

  if ((length $acmp == 0) && (length $bcmp == 0))
    {
      # If the parts of $a and $b before a period (or dash/comma) are
      # both empty, then check the remaining parts.  If either one of
      # the remains is not empty, then recurse.  Otherwise, everything
      # was empty and thus the versions are the same.
      if ((length $aremain > 0) || (length $bremain > 0))
        {
          return &compareversion($aremain,$bremain);
        }
      else
        {
          $retval = 0;
        }
    }
  elsif (length $acmp == 0)
    { # $bcmp is non-empty which means that $b is higher
      $retval = -1;
    }
  elsif (length $bcmp == 0)
    { # $acmp is non-empty which means that $a is higher
      $retval = +1;
    }
  else # Both $acmp and $bcmp are non-empty
    {
      my($a1,$atype,$arest);
      my($b1,$btype,$brest);

      # For $acmp, figure out if the beginning of the string is a bunch of
      # numbers or not.  The beginning of the string is stored in $a1.  The
      # remainder of the string (if any) is stored in $arest.  The type of
      # $a1 is stored in $atype is either 'digit' or 'other'.
      if ($acmp =~ /^(\d+)(.*)/)
        {
          $a1 = $1;
          $arest = $2;
          $atype = 'digit';
        }
      else
        {
          $acmp =~ /^([^\d]+)(.*)/;
          $a1 = $1;
          $arest = $2;
          $atype = 'other';
        }

      # Do something similar for $bcmp.
      if ($bcmp =~ /^(\d+)(.*)/)
        {
          $b1 = $1;
          $brest = $2;
          $btype = 'digit';
        }
      else
        {
          $bcmp =~ /^([^\d]+)(.*)/;
          $b1 = $1;
          $brest = $2;
          $btype = 'other';
        }

      # If both $atype and $btype are 'digit', then do a numerical
      # comparison on $a1 and $b1.  Otherwise, do a string comparison.
      if (($atype eq 'digit') && ($btype eq 'digit'))
        {
          if ($a1 == $b1)
            { # Must recurse on the rest of the string.  The new string is
              # built up by concatenating $arest and $aremain with a period
              # inbetween.  Note that this really has nothing to do with the
              # original string, but the newly inserted period gets removed
              # by the 'split' command.
              return &compareversion($arest.'.'.$aremain,$brest.'.'.$bremain);
            }
          else
            { # $a1 and $b1 are different, so just use numerical comparison
              $retval = ($a1 <=> $b1);
            }
        }
      else
        { # At least one of $a1,$b1 is not a digit, so do a string comparison.
          if ($a1 eq $b1)
            { # Must recurse on the rest of the string.
              return &compareversion($arest.'.'.$aremain,$brest.'.'.$bremain);
            }
          else
            { # $a1 and $b1 are different, so just use string comparison.
              $retval = ($a1 cmp $b1);
            }
        }
    }

  return $retval;
}

sub compare_versions {
    # Have to separate the comparison from the main function (find_best) so
    # that more complex operation on the string can be made in particular
    # saving the original value and not affecting the $a and $b variables...
    
    # Save the values of the input variable
    my $new_a=$a;
    my $new_b=$b;
    

    # Remove the mdk and oscar end version tag
    $new_a =~s/^(.+)(mdk|oscar)$/$1/;
    $new_b =~s/^(.+)(mdk|oscar)$/$1/;

    return compareversion($new_b,$new_a);
}

sub find_best_arch {
        # Finds the first architecture that we have an rpm for
        # based on the rpm compatability info.
        # Input: Ref to the rpm table info
        #        Ref to the ordered list of compatable rpms
        #        The package name we're looking for
        # Output: The best arch to use.
        my $RPM_TABLE=shift;
        my $compatlist=shift;
        my $pkg=shift;
        foreach my $arch (@$compatlist){
                if (defined $RPM_TABLE->{$arch}->{$pkg}) {
                        return $arch;
                }
        }
}


sub cache_gen {
# Generate/update the cache lists
# Input: dir name, cachefile, force flag
# Output: boolean success/failure

        my $path=shift;
        my $cachefile=shift;
        my $force=shift;
        my %CSIZES;
        my %CLINES;
        my %FSIZES;
        local *PKGDIR;
	my $rpmcmd="/bin/rpm";

        &verbose("Reading package directory");
        unless (opendir(PKGDIR,$path)) {
                carp("Can't open package directory $path");
                return 0;
        }
        while($_ = readdir(PKGDIR)) {
                my $file = "$path/$_";
                if($file !~ /\.rpm$/) {next;}
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
                $FSIZES{$_}=$size;
        }
        if ((!$force) && (-e "$path/$cachefile")) {
                &verbose("Reading cache file.");
                unless (open(CACHE,"<$path/$cachefile")) {
                        carp("Can't open cachefile in $path");
                        return 0;
                }
                while (<CACHE>){
                        chomp;
                        my ($name, $version, $release, $arch, $file, $size) = split;
                        $CSIZES{$file}=$size;
                        $CLINES{$file}=$_;
                }
                close(CACHE);
        }
        &verbose("Comparing cache to directory.");
        # Check that all files in the dir first.
        foreach (keys(%FSIZES)) {
                # Check if the file is in the cache at all
                if (! defined $CSIZES{$_}) {
                        # If not, add a blank entry
                        $CLINES{$_}="";
                }
                # Now see if the size is the same
                if ($FSIZES{$_} != $CSIZES{$_}){
                        # If not, blank the entry.
                        $CLINES{$_}="";
                }
        }
        foreach (keys(%CSIZES)) {
                if (! defined $FSIZES{$_}) {
                        # If the file isn't around, undef it in
                        # the hash
                        undef ($CLINES{$_});
                }
                if ($FSIZES{$_} != $CSIZES{$_}){
                        # If the sizes don't match, blank it
                        $CLINES{$_}="";
                }
        }
        &verbose("Writing new cache file.");
        unless (open(CACHE,">$path/$cachefile")) {
                carp("Can't open cachefile in $path");
                return 0;
        }
        foreach (keys %CLINES) {
                my $file = "$path/$_";
                if(!-f $file) {next;}
                if ($CLINES{$_} eq "") {
                        my $output = `$rpmcmd -qp --qf '\%{NAME} \%{VERSION} \%{RELEASE} \%{ARCH}' $file 2> /dev/null`;
                        my ($name, $version, $release, $arch) = split (/\s+/, $output);
                        # Do some sanity checking to see that name is actually there
                        if($name) {
                                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
                                print CACHE "$name $version $release $arch $_ $size\n";
                        }
                } else {
                        print CACHE "$CLINES{$_}\n";
                }
        }
        close(CACHE);
        return 1;

} #cache_gen

sub verbose {
        my $VERBOSE=1;
        my $FH = \*STDERR;
        if($VERBOSE) {
            my ($package, $filename, $line) = caller;
            print $FH  " [$package :: Line $line] " . join(', ', @_) . "\n";
        }
}

### POD from here down

=head1 NAME
 
SystemInstaller::Package::PackageBest - Choose best package file.
 
=head1 SYNOPSIS   

 use SystemInstaller::Package::PackageBest;

 my @pkglist = qw(bash filesystem basesystem nfs-utils);

 my %files = &find_files(PKGDIR=>"/tftpboot/rpm",ARCH=>"i386", PKGLIST=>\@pkglist);

=head1 DESCRIPTION

SystemInstaller::Package::PackageBest finds the best file to 
use for a given package name.

=head1 FUNCTIONS

&find_files(<parameters>);

Finds the best file to use from a directory  based on a list of
package names.

 find_files(
            PKGDIR  =>  "<directory that contains packages>",
            ARCH    =>  "<target architecture>",
            RPMRC   =>  "<filename of rpmrc file>",
            CACHEFILE=> "<filename of rpm cache file>",
            PKGLIST =>  "<ref to a list of packages>",
 );

If ARCH is not given, the current machine's architecture will be used.
If RPMRC is not given, /usr/lib/rpm/rpmrc will be used.
If CACHEFILE is not given, .pkgcache will be used.

The elements referred to by PKGLIST can be either an rpm name, like "bash" or the full
name version string as returned by rpm -q, like "bash-2.05-10mdk". In the 
former case, the best version present in PKGDIR will be used, in the latter,
only the specific version specified will be used.
        
The rpmrc file is used to determine the compatability chain. For example, you 
may request an architecture of i686, but some rpms are only available 
for i386. Since the rpmrc says that these 2 architectures are compatable,
if an i686 rpm doesn't exist and an i386 does, the i386 filename will be
used.

This function returns a hash whose keys are the package names and whose values are the corresponding best filenames, or null if errors.

=head1 AUTHOR
 
Michael Chase-Salerno <mchasal@users.sf.net>
        originally derived from some code from 
        Sean Dague <sdague@users.sf.net>
 
=head1 SEE ALSO

L<SystemInstaller::Package>
L<SystemInstaller::Package::Rpm>
 
=cut

1;

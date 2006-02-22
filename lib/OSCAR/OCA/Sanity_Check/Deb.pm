#!/usr/bin/env perl
#
# Copyright (c) 2006 Oak Ridge National Laboratory, Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved
#   - port the Summer of Code program contribution: avoid RPM dependencies
#
#   This file is part of the OSCAR software package.  For license
#   information, see the COPYING file in the top level directory of the
#   OSCAR source distribution.
#

package OCA::Sanity_Check::Deb;

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::OCA::OS_Detect;
use OSCAR::Logger;

sub check_repository
{
  # Check to see if packages for tftp and/or tftp-server are installed.
  # If so, remove them because they conflict with the tftp-hpa packages.
  my $id;
  foreach my $pkg ('tftp', 'tftp-server')
    {
      my $tftp_version = get_package_version ($pkg);
      if ($tftp_version == -1)
        {
          $id = "$pkg package doesnot exist\n";
          oca_debug_subsection($id);
          next;
        }
      $id = "Removing $pkg package";
      oca_debug_subsection($id);
      $id = remove_pkg($pkg);
      if ($id == 0)
        {
          oca_debug_subsection("Could not Remove Package");
          return 0;
        }

    }
  oca_debug_subsection($id);

  oca_debug_subsection("Quick sanity check for the local Debian repository in
/tftpboot/deb");
  if (! -d "/tftpboot/deb") {
    $id = "ERROR: the local Debian repository in the /tftpboot/deb directory does not exist.\n";
    oca_debug_subsection($id);
    return 0;
  }

  return 1;
}

sub check_prereqs
{
  my $id;
  my $perlQt = "libqt-perl";
  my $pqtv = get_package_version($perlQt);
  if($pqtv >= 3)
    {
      $id = "Found $perlQt package version $pqtv\n";
    }
  if ($pqtv == -1)
    {
      $id = "$perlQt package doesnot exist\n";
    }
  if ( $pqtv > 0 && $pqtv < 3 )
    {
      $id = "Removing perl-Qt package, version $pqtv";
      oca_debug_subsection($id);
      $id = remove_pkg ($perlQt);
      if ($id == 0)
        {
           oca_debug_subsection("Could not Remove Package");
           return 0;
         }
    }
  oca_debug_subsection($id);
  return 1;
}

sub open
{
  my $ret;

  # Bail out early if we're not on a "Debian" box.

  my $os = OSCAR::OCA::OS_Detect::open();
  if ($os->{pkg} ne "deb") {
    return undef;
  }

  # Check perl-qt
  $ret = check_prereqs ();
  if ($ret == 0) {
    return undef;
  }

  # Check the local repository for packages
  $ret = check_repository ();
  if ($ret == 0) {
    return undef;
  }

  return 1;
}

# If we got here, we're happy
1;


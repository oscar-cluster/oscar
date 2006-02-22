#!/usr/bin/env perl
#
# Copyright (c) 2006 Oak Ridge National Laboratory, Geoffroy Vallee <valleegr@ornl.gov>
# 		     All rights reserved
#   - port the Summer of Code program contribution: avoid RPM dependencies
#
#   This file is part of the OSCAR software package.  For license
#   information, see the COPYING file in the top level directory of the
#   OSCAR source distribution.
#

package OCA::Sanity_Check::RPM;

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::OCA::OS_Detect;
use OSCAR::OCA::Debugger;

#use vars qw(@EXPORT);
#use base qw(Exporter);

#@EXPORT = qw();

sub check_repository
{
  # get rid of installed tftp-server, it conflicts with atftp
  # (there should be a check whether this is an RPM based distro here!)
  if (!system("rpm -q tftp-server >/dev/null 2>&1")) {
    oca_debug_subsection("Removing installed tftp-server RPM, this conflicts with OSCAR atftp-server");
    if ( !system("rpm -e tftp-server") ) {
      return -1;
    }
  }
  
  # TJN (10/4/2005): Note, a fairly evil, totally non-obvious issue
  #    occurs if you have /tftpboot setup as a symlink,
  #    e.g., /tftpboot -> /var/tftpboot/,  and remove 'tftp-server'.
  #    What happens is the '/tftpboot' dir (symlink) gets removed!
  #    This is b/c '/tftpboot' is part of the RPM file manifest for
  #    tftp-server (at least as of v0.33-3 it does).
  #
  #    Adding a sanity check after the RPM removes to check for this case!

  if(! -d "/tftpboot" ) {
    oca_debug_subsection ("/tftpboot is not existing\n");
    return -1;
  }
  
  return 1;
}

sub check_prereqs
{
  my $pqtv = `rpm -q --qf '%{VERSION}' perl-Qt | sed -ne \"s/^\\([1-9]*\\)..*/\\1/p\"`;
  oca_debug_subsection ("perl-qt version: $pqtv\n");
  if ( $pqtv && $pqtv >= 3 ) {
    return 1;
  }
  if ( $pqtv && $pqtv < 3 ) {
    oca_debug_subsection("Removing installed perl-Qt RPM because version is < 3");
    if ( !system("rpm -e perl-Qt") ) {
      return -1;
    }
  }

  return -1;     
}

sub open
{
  my $ret;

  # Bail out early if we're not on an RPM based box.
  oca_debug_section ("Sanity_Check::RPM\n");
  
  my $os = OSCAR::OCA::OS_Detect::open();
  oca_debug_subsection("Sanity_Check::RPM the binary package format is $os->{pkg}\n");
  if ($os->{pkg} ne "rpm") {
    oca_debug_subsection ("The binary package format is not RPM\n");
    return -1; 
  }
    
  # Check perl-qt
  oca_debug_subsection("Sanity_Check::RPM, checking prereqs\n");
  $ret = check_prereqs ();
  if ($ret == -1) {
    oca_debug_subsection ("Prereqs are not installed\n");
    return -1;
  }
  # Check the local repository for packages
  oca_debug_subsection("Sanity_Check::RPM, checking repository\n");
  $ret = check_repository ();
  if ($ret == -1) {
    oca_debug_subsection ("Check_repository failed\n");
    return -1;
  }

  return 1;
}

# If we got here, we're happy
1;


#/usr/bin/perl
#
# Copyright (c) 2005 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $COPYRIGHT$
#

package OCA::OS_Detect::Debian;

use strict;
use POSIX;
use Config;

my $DEBUG = 1 if( $ENV{DEBUG_OCA_OS_DETECT} );

my $deb_ver_file = "/etc/debian_version";

 #
 # Bail out early if we're not on a Debian box.
 # Which is determined by having the deb version file.
 #
return 0 if( ! -e $deb_ver_file );


 #
 # Gather lots of information about the system
 #
open(FH, $deb_ver_file) or die "Error: unable to open '$deb_ver_file' $!\n";
my @file = grep { ! /^\s*#/ } <FH>;
close(FH);

 # 
 # Get version from one-line entry giving the version number in the
 # file "/etc/debian_version".  c.f.,
 # http://www.debian.org/doc/FAQ/ch-software.en.html#s-isitdebian
 #
my $deb_ver = $file[0];
chomp($deb_ver);

my ($os_name, $jnk1, $os_rel, $jnk2, $arch) = POSIX::uname();


 # Print our raw data if in DEBUG mode
if( $DEBUG ) {
	print <<EOF

  **DEBUG**  
  OCA::OS_Detect::Debian
                       os = $os_name
                     arch = $arch
               os_release = $os_rel
             linux-distro = Debian 
     linux-distro-version = $deb_ver 

EOF
}


 #
 # Now do some checks to make sure we're supported
 #

 # Limit support to only Debian v3.1 (sarge) 
if ($deb_ver !~ /^3\.1/) {
    print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Debian version support - ($deb_ver)\n\n" if( $DEBUG );
	return 0 
}

 # Limit suppor to Linux (sanity check)
if ($os_name !~ /linux/i) {
    print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed OS support - ($os_name)\n\n" if( $DEBUG );
	return 0;
}

# # Limit support to 2.6 kernels
if ($os_rel !~ /^2\.6/) {
    print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed OS release support - ($os_rel)\n\n" if( $DEBUG );
	return 0; 
}


 # Limit support to only x86 machines
if ($arch !~ /^i686$|^i586$|^i386$/ )
{
    print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
	return 0; 
}

 #
 # Setup our information hash and identification string
 #

our $id = {
    os => lc($os_name),
    arch => $arch,
    os_release => $os_rel,
    linux_distro => "debian",
    linux_distro_version => $deb_ver,
};


 # Example:  'linux-x86-2.6.11.7-debian-3.1'
 
$id->{ident}  = $id->{os}           . "-";
$id->{ident} .= $id->{arch}         . "-";
$id->{ident} .= $id->{os_release}   . "-";
$id->{ident} .= $id->{linux_distro} . "-";
$id->{ident} .= $id->{linux_distro_version};



# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}


1;

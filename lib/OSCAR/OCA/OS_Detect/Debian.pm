#!/usr/bin/env perl
#
# Copyright (c) 2005 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::Debian;

use strict;

my $DEBUG = 1 if( $ENV{DEBUG_OCA_OS_DETECT} );
my ($deb_ver, $deb_update);

my $detect_file = "/bin/bash";  # Common file used to determine arch


my $detect_pkg  = "base-files"; # Deb pkg containing '/etc/debian_version'
                                # therefore should always be available
                                # and the Version: is always accurate!

my $dpkg_bin = "/usr/bin/dpkg-query"; # Tool to query Deb package Database


#
#  End of all configuration/global variable setup
# 
#---------------------------------------------------------------------



# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect_dir {
    my ($root) = @_;
    my $release_string;

    # If /etc/debian_version exists, continue, otherwise, quit.
    if (-f "$root/etc/debian_version") {
    	my $cmd = "$dpkg_bin --show $detect_pkg 2>&1";
    	open(CMD, "$cmd|") or die "Error: unable to open $cmd - $!\n";
	my $rslt = <CMD>;
	chomp($rslt);
	close(CMD);

	$deb_ver = (split(/\s+/, $rslt))[1];  # [0]=name,  [1]=version

    } else {
	return undef;
    }


    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    #
    # Now do some checks to make sure we're supported
    #

    # Limit support to only Debian v3.1 (sarge)
    my $deb_update;
    $deb_ver =~ /^(\d+)\.(\d+)/;
    $deb_ver = $1;
    $deb_update = $2;
    if ($deb_ver != 3) {
	print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Debian version support - ($deb_ver)\n\n" if( $DEBUG );
	return undef;
    }

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root, $detect_file);
    $id->{arch} = $arch;

    # Limit support to only x86 machines
    if ($arch !~ /^i686$|^i586$|^i386$/ ) {
	print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
	return 0;
    }

    $id->{distro} = "debian";
    $id->{distro_flavor} = "sarge";
    $id->{distro_version} = $deb_ver;
    $id->{distro_update} = $deb_update;
    $id->{compat_distro} = "debian";
    $id->{compat_distrover} = $deb_ver;
    $id->{pkg} = "deb";

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
    return $id;
}



# FIXME: This needs to be added, just putting function name here for now.
sub detect_pool {
	print STDERR "Warning-STUB: method 'detect_pool()' not available.\n";
	return undef;
}


# FIXME: This needs to be added, just putting function name here for now.
sub detect_fake {
	print STDERR "Warning-STUB: method 'detect_fake()' not available.\n";
	return undef;
}


# If we got here, we're happy
1;

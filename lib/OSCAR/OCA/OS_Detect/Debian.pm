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

my $detect_pkg  = "base-files"; # Deb pkg containing '/etc/debian_version'
                                # therefore should always be available
                                # and the Version: is always accurate!

my $dpkg_bin = "/usr/bin/dpkg-query"; # Tool to query Deb package Database


my $distro = "debian";
my $compat_distro = "debian";
my $pkg = "deb";
my $detect_package = "base-files";
my $detect_file = "/bin/bash";



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

    # Limit support to only Debian v4 (etch)
    my $deb_update;
    # two cases: the version number is "x" or "x.<something>"
    $deb_ver = 4;
    if ($deb_ver =~ /^(\d+)\.(\d+)/) {
#	    $deb_ver =~ /^(\d+)\.(\d+)/;
	$deb_ver = $1;
	$deb_update = $2;
    } else {
    	$deb_update = 0;
    }
    if ($deb_ver != 4) {
	print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Debian version support - ($deb_ver)\n\n" if( $DEBUG );
	return undef;
    }

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root, $detect_file);
    $id->{arch} = $arch;

    # Limit support to only x86_64 machines
#    if ($arch !~ /^i686$|^i586$|^i386$/ ) {
    if ($arch !~ /^x86_64$/ ) {
	print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
	return 0;
    }

    $id->{distro} = $distro;
    $id->{distro_flavor} = "sarge";
    $id->{distro_version} = $deb_ver;
    $id->{distro_update} = $deb_update;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $deb_ver;
    $id->{pkg} = $pkg;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
    return $id;
}


# EF: simply copied the function from RedHat.pm, this is why we have common
# routines in OS_Detect, in order to avoid code replication
sub detect_pool {
    my ($pool) = @_;

    my $id = main::OSCAR::OCA::OS_Detect::detect_pool_rpm($pool,
							  $detect_package,
							  $distro,
							  $compat_distro);

    return $id;
}

# EF: simply copied the function from RedHat.pm
sub detect_fake {
    my ($fake) = @_;
    my $id = main::OSCAR::OCA::OS_Detect::detect_fake_common($fake,
							     $distro,
							     $compat_distro,
							     $pkg);
    return $id;
}

# If we got here, we're happy
1;

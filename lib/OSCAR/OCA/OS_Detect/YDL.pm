#!/usr/bin/env perl
#
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::YDL;

use strict;

my $distro = "yellowdog";
my $compat_distro = "ydl";
my $pkg = "rpm";
my $detect_package = "yellowdog-release";
my $detect_file = "/bin/bash";

# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect_dir {
    my ($root) = @_;
    my ($release_string, $ydl_release);
    my $dfile = "/etc/yellowdog-release";

    # If /etc/yellowdog-release exists, continue, otherwise, quit.
    if (-f "$root$dfile") {
	$release_string = `cat $root$dfile`;
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    if ($release_string =~ /Yellow Dog Linux release (\d+)/) {
	$ydl_release = $1;
    } else {
	return undef;
    }

    $id->{distro} = $distro;
    $id->{distro_version} = $ydl_release;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $ydl_release;
    $id->{pkg} = $pkg;

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root,$detect_file);
    $id->{arch} = $arch;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}";

    return $id;
}

sub detect_pool {
    my ($pool) = @_;

    my $id = main::OSCAR::OCA::OS_Detect::detect_pool_rpm($pool,
							  $detect_package,
							  $distro,
							  $compat_distro);

    return $id;
}

sub detect_fake {
    my ($fake) = @_;
    my $id = main::OSCAR::OCA::OS_Detect::detect_fake_common($fake,
							     $distro,
							     $compat_distro,
							     $pkg);
    return $id;
}

sub detect_oscar_pool ($) {
    my $pool = shift;
    my $ret = main::OSCAR::OCA::OS_Detect::detect_oscar_pool_common($pool,
        $compat_distro);

    if ($ret) {
        # The component can use the OSCAR pool
        my $id = {
            os => "linux",
        };
        $id->{distro} = $distro;
        $id->{pkg} = $pkg;
        return $id;
    } else {
        return undef;
    }
}


# If we got here, we're happy
1;

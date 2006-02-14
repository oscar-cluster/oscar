#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) Bernard Li <bli@bcgsc.ca>
# 
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#      - complete rewrite to enable use on top of images
#      - enabled use on top of package pools
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::Fedora;

use strict;

my $distro = "fedora";
my $compat_distro = "fc";
my $pkg = "rpm";
my $detect_package = "fedora-release";
my $detect_file = "/bin/bash";

# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect_dir {
    my ($root) = @_;
    my ($release_string, $fc_release);
    my $dfile = "/etc/fedora-release";

    # If /etc/fedora-release exists, continue, otherwise, quit.
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

    if ($release_string =~ /Fedora Core release (\d+) /) {
	$fc_release = $1;
    } else {
	return undef;
    }

    $id->{distro} = $distro;
    $id->{distro_version} = $fc_release;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $fc_release;
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

# If we got here, we're happy
1;

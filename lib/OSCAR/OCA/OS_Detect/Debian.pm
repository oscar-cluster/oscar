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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::LSBreleaseParser;
use OSCAR::Utils;

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
my $distro_flavor;

# The different Debian codenames, useful to set the distro_flavor variable
my %codenames = (
                '5.0'   => "lenny",
                '4.0'   => "etch",
                '3.1'   => "sarge",
                '3.0'   => "woody",
                '2.2'   => "potato",
                '2.1'   => "slink",
                '2.0'   => "hamm",
                );

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
        # There is a trick with Ubuntu systems: they have a non-valid 
        # /etc/debian_version and the ubuntu release data is actually in
        # /etc/lsb-release. So if we get data from this file and if it specifies
        # the system is an Ubuntu system we quit.
        my $distro_id = OSCAR::LSBreleaseParser::parse_lsbrelease($root);
        if (OSCAR::Utils::is_a_valid_string ($distro_id)) {
            require OSCAR::PackagePath;
            my ($d, $v, $a) = 
                OSCAR::PackagePath::decompose_distro_id ($distro_id);
            return undef if ($d eq "ubuntu");
        }


	# GV (2009/04/22): this is completely stupid (yes it is!) to use
	# the version of the base-files package since developers may trick
	# the version number as a work around to packaging issues. As a
	# result, it is a nigthmare to get the actual version from it,
	# especially when at the same time, a file (/etc/debian-version)
	# is there to give the version (even if the file may store a codename
	# or a version, it is still simpler).
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
    # three (freaking) cases: the version number is "x" or "x.<something>" 
    # or "xcodenamey"
    if ($deb_ver =~ /^(\d+)\.(\d+)/) {
        $deb_ver = $1;
        $deb_update = $2;
    } elsif ($deb_ver =~ /^(\d+)([A-z]+)(\d+)$/) {
        $deb_ver = $1;
        $deb_update = 0;
    } else {
    	$deb_update = 0;
    }

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root, $detect_file);
    $id->{arch} = $arch;

    # Limit support to only x86 and x86_64 machines
    if ($arch !~ /^x86_64$|^i686$|^i586$|^i386$/ ) {
        print "OCA::OS_Detect::Debian-";
        print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
        return 0;
    }

    $id->{distro} = $distro;
    $id->{distro_version} = $deb_ver;
    $id->{distro_update} = $deb_update;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $deb_ver;
    $id->{pkg} = $pkg;
    my $full_distro_ver = "$deb_ver.$deb_update";
    $id->{codename} = $codenames{$full_distro_ver};

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

sub detect_fake ($) {
    my ($fake) = @_;

    return undef if (!defined $fake);

    # From the parameter, we detect the distro codename and add it in the
    # description of the OS
    my $l_version = $fake->{'distro_version'};
    if ($l_version !~ /(.*)\.(.*)/) {
        $l_version .= ".0";
    }
    $fake->{'codename'} = $codenames{$l_version};

    my $id = main::OSCAR::OCA::OS_Detect::detect_fake_common($fake,
							     $distro,
							     $compat_distro,
                                 undef,
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

detect_dir ("/");

# If we got here, we're happy
1;

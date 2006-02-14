#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
#
# Copyright (c) 2006 Erich Focht <efocht@hpce.nec.com>
#                    All rights reserved
#      - complete rewrite to enable use on top of images
#      - enabled use on top of package pools
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OSCAR::OCA::OS_Detect;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA;

#
# Exports
#

@EXPORT = qw(detect_arch_file detect_arch_pool);

#
# Subroutine to open the OS_Detect framework
#
# Arguments and usage examples:
# open()              : detects distro/arch installed in "/"
# open($path)         : detects distro/arch in chroot directory $path
# open(chroot=>$path) : detects distro/arch in chroot directory $path
# open(pool=>$pool)   : detects distro/arch of package pool $pool
#

sub open {
    my %arg;
    if (@_) {
	if (scalar(@_) == 1) {
	    if (defined($_[0])) {
		$arg{chroot} = $_[0];
	    } else {
		$arg{chroot} = "/";
	    }
	} else {
	    %arg = @_;
	}
    } else {
	$arg{chroot} = "/";
    }

    my ($path,$pool);
    if (exists($arg{chroot})) {
	$path = $arg{chroot};
    } elsif (exists($arg{pool})) {
	$pool = $arg{pool};
    } else {
	print STDERR "ERROR: Unknown detection target in OS_Detect:".
	    join(",",keys(%arg))."\n";
	return undef;
    }

    # return immediately if path doesn't exist
    if ($path) {
	if (! -d $path) {
	    print STDERR "ERROR: Path $path does not exist!\n";
	    return undef;
	}
    }

    my $comps = OSCAR::OCA::find_components("OS_Detect");

    # Did we find one and only one?

    if (!defined($comps)) {
        # If we get undef, then find_components() already printed an
        # error, and we decide that we want to die
        die "Cannot continue, find_components returned undef";
    } elsif (scalar(@$comps) == 0) {
        print "Could not find an OS_Detect component for this system!\n";
        die "Cannot continue";
    }

    # Yes, we found some components. Check which one returns a valid id
    # hash.

    my $ret = undef;
    foreach my $comp (@$comps) {
	my $str;
	if ($path) {
	    $str = "\$ret = \&OCA::OS_Detect::".$comp."::detect_dir(\$path)";
	} elsif ($pool) {
	    $str = "\$ret = \&OCA::OS_Detect::".$comp."::detect_pool(\$pool)";
	}
	eval $str;
	if (defined($ret) && (ref($ret) eq "HASH")) {
	    last;
	}
    }
    return $ret;
}

# Determine architecture by checking the executable type of a wellknown
# program
sub detect_arch_file {
    my ($root,$file) = @_;
    my $arch="unknown";
    my $q = `env LC_ALL=C file $root/$file`;
    if ($q =~ m/executable,\ \S+\ (\S+),\ version/) {
	$arch = $1;
	if ($arch =~ m/386$/) {
	    $arch = "i386";
	} elsif ($arch =~ m/x86-64/) {
	    $arch = "x86_64";
	}
    }
    return $arch;
}

# common routine for arch detection of a package pool
sub detect_arch_pool {
    my ($pool,$pkg) = @_;

    if ($pkg eq "rpm") {
	my $known = "i?86,x86_64,ia64,ppc";
	my @files = glob("$pool/bash-*{$known}.rpm");
	my $arch;
	for my $f (@files) {
	    if ($f =~ /\.([^\.]+)\.rpm$/) {
		my $a = $1;
		if (!$arch) {
		    $arch = $a;
		} elsif ($a ne $arch) {
		    print STDERR "Multiple architectures detected in $pool.\n";
		    return "unknown";
		}
	    }
	}
	return $arch;
    } elsif ($pkg eq "deb") {
	my $known = "i?86,amd64,ia64,ppc";
	my @files = glob("$pool/bash_*_{$known}.deb");
	my $arch;
	for my $f (@files) {
	    if ($f =~ /_([^_]+)\.deb$/) {
		my $a = $1;
		if (!$arch) {
		    $arch = $a;
		} elsif ($a ne $arch) {
		    print STDERR "Multiple architectures detected in $pool.\n";
		    return "unknown";
		}
	    }
	}
	if ($arch eq "amd64") {
	    $arch = "x86_64";
	}
	return $arch;
    } else {
	print "Don't know how to detect package pool architecture for $pkg.\n";
    }
}

# common routine for pool distro/arch detection for rpm-based distributions
sub detect_pool_rpm {
    my ($pool,$detect_package,$distro,$compat) = @_;

    if (! -d "$pool") {
	return undef;
    }
    my @files = glob("$pool/$detect_package"."-"."*.rpm");
    if (!scalar(@files)) {
	return undef;
    }
    # these packages have simple version strings!
    my $version;
    for my $f (@files) {
	my $v = `rpm -q --qf "%{VERSION}" -p $f 2>/dev/null`;
	# don't care about release for pools, only version counts
	$v =~ s/\.\d+$//;
	# for redhat-el
	$v =~ s/(AS|WS|ES)$//;
	if (!$version) {
	    $version = $v;
	} else {
	    if ($v > $version) {
		$version = $v;
	    }
	}
    }
    return undef if (!$version);

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os               => "linux",
	pool             => $pool,
	distro           => $distro,
	distro_version   => $version,
	compat_distro    => $compat,
	compat_distrover => $version,
	pkg              => "rpm",
    };

    # determine architecture
    my $arch = detect_arch_pool($pool,"rpm");
    $id->{arch} = $arch;

    return $id;
}


1;

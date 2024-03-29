#
# Copyright (c) 2005, 2007 The Trustees of Indiana University.  
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
# $Id$
#

package OSCAR::OCA::OS_Detect;

use strict;
use vars qw(@EXPORT $LOCAL_NODE_OS);
use base qw(Exporter);
use File::Glob qw(:globally :nocase); # disabling case sensitivity so it
                                      # works under openSUSE: /etc/SuSE-release
                                      # vs suse-release-oss RPM
use Carp;

use OSCAR::OCA;
use OSCAR::Logger;
use OSCAR::LoggerDefs;

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
# open(fake=>{ distro=>$distro, distro_version=>$version, arch=>$arch})
#                     : build fake $id structure when distro is known but
#                       distro files are not accessible (e.g. for pools
#                       referenced by URLs). Main purpose: find compat distro
#                       and packaging method.
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

    my ($path,$pool,$oscar_pool,$fake);
    if (exists($arg{chroot})) {
        $path = $arg{chroot};
    } elsif (exists($arg{pool})) {
        $pool = $arg{pool};
    } elsif (exists($arg{oscar_pool})) {
        $oscar_pool = $arg{oscar_pool};
    } elsif (exists($arg{fake})) {
        $fake = $arg{fake};
    } else {
#        print STDERR "ERROR: Unknown detection target in OS_Detect: ".
#            join(",",keys(%arg))."\n";
        OSCAR::Logger::oscar_log(5, ERROR, "Unknown detection target in OS_Detect: ".
             join(",",keys(%arg)));
        OSCAR::Logger::oscar_log(1, ERROR, "Failed to detect OS");
        return undef;
    }

    if ($path) {
    # return immediately if path doesn't exist
    if (! -d $path) {
#        print STDERR "ERROR: Path $path does not exist!\n";
        OSCAR::Logger::oscar_log(5, ERROR, "Path $path does not exist!");
        OSCAR::Logger::oscar_log(1, ERROR, "Failed to detect OS");
        return undef;
    }
    # return cached value if detecting local OS
    if (($path eq "/") && $LOCAL_NODE_OS) {
        return $LOCAL_NODE_OS;
    }
    }

    my $comps = OSCAR::OCA::find_components("OS_Detect");

    # Did we find one and only one?

    if (!defined($comps)) {
        # If we get undef, then find_components() already printed an
        # error, and we decide that we want to die
#        print STDERR "Cannot continue, find_components returned undef";
        OSCAR::Logger::oscar_log(5, ERROR, "Cannot continue, find_components returned undef");
        OSCAR::Logger::oscar_log(1, ERROR, "Failed to detect OS");
        return undef;
    } elsif (scalar(@$comps) == 0) {
#        print STDERR "Could not find an OS_Detect component for this system!\n";
        OSCAR::Logger::oscar_log(5, ERROR, "Could not find an OS_Detect component for this system!");
        OSCAR::Logger::oscar_log(1, ERROR, "Failed to detect OS");
        return undef;
    }

    # Yes, we found some components. Check which one returns a valid id
    # hash.

    my $ret = undef;
    foreach my $comp (@$comps) {
        my $str;
#         print "Comp $comp\n";
        if ($path) {
            $str = "\$ret = \&OSCAR::OCA::OS_Detect::".$comp."::detect_dir(\$path)";
        } elsif ($pool) {
            $str = "\$ret = \&OSCAR::OCA::OS_Detect::".$comp."::detect_pool(\$pool)";
        } elsif ($oscar_pool) {
            $str = "\$ret = \&OSCAR::OCA::OS_Detect::".$comp."::detect_oscar_pool(\$oscar_pool)";
        } elsif ($fake) {
            $str = "\$ret = \&OSCAR::OCA::OS_Detect::".$comp."::detect_fake(\$fake)";
        }
        my $res = eval $str;
        if (defined($ret) && (ref($ret) eq "HASH")) {
            last;
        }
    }
    if ($path && ($path eq "/") && !$LOCAL_NODE_OS) {
        $LOCAL_NODE_OS = $ret;
    }
    return $ret;
}


# Determine architecture by checking the executable type of a wellknown
# program
sub detect_arch_file {
    my ($root,$file) = @_;
    my $arch="unknown";
    my $q = `env LC_ALL=C file $root/$file`;
    if ( ($q =~ m/executable,\ \S+\ (\S+),\ version/) ||
         ($q =~ m/executable\ (\S+),\ version/) ||
         ($q =~ m/executable,\ (\S+),\ version/) ||
         ($q =~ m/object,\ \S+ (\S+),\ version/) ||
         ($q =~ m/object,\ (\S+),\ version/) )
    {
        $arch = $1;
        if ($arch =~ m/386$/) {
            $arch = "i386";
        } elsif ($arch =~ m/x86-64/) {
            $arch = "x86_64";
        } elsif ($arch =~ m/aarch64/) {
            $arch = "aarch64"; # ARM 64bits
        } elsif ($arch =~ m/arm/) {
            $arch = "arm";     # ARM 32bits
        } elsif ($arch =~ m/IA-64/) {
            $arch = "ia64";
        } elsif ($arch =~ m/PowerPC/) { # OL: May need tunning. (iSeries)
            $arch = "ppc64";
        }
    }
    # DIKIM added this for YDL5
    if ($q =~ m/executable,\ (\S+)\ \S+\ \S+\ \S+,\ version/) {
        $arch = $1;
        if ($arch =~ m/PowerPC/){
            chomp(my $q2 = `uname -p`);
            $arch = $q2;
        }
    }
    return $arch;
}

# common routine for arch detection of a distro package pool
sub detect_arch_pool {
    my ($pool,$pkg) = @_;

    if ($pkg eq "rpm") {
        my $known = "i?86,x86_64,arm,aarch64,ia64,ppc,ppc64";
        my @files = glob("$pool/bash-*{$known}.rpm");
        my $arch;
        for my $f (@files) {
            if ($f =~ /\.([^\.]+)\.rpm$/) {
                my $a = $1;
                if (!$arch) {
                    $arch = $a;
                } elsif ($a ne $arch) {
#                    print STDERR "Multiple architectures detected in $pool.\n";
                    OSCAR::Logger::oscar_log(5, ERROR, "Multiple architectures detected in $pool.");
                    return "unknown";
                }
            }
        }
        $arch = "i386" if ($arch =~ /i.86/);
        return $arch;
    } elsif ($pkg eq "deb") {
        my $known = "i?86,amd64,arm64,ia64,ppc,ppc64";
        my @files = glob("$pool/bash_*_{$known}.deb");
        my $arch;
        for my $f (@files) {
            if ($f =~ /_([^_]+)\.deb$/) {
                my $a = $1;
                if (!$arch) {
                    $arch = $a;
                } elsif ($a ne $arch) {
#                    print STDERR "Multiple architectures detected in $pool.\n";
                    OSCAR::Logger::oscar_log(5, ERROR, "Multiple architectures detected in $pool.");
                    return "unknown";
                }
            }
        }
        if ($arch eq "amd64") {
            $arch = "x86_64";
        }
        $arch = "i386" if ($arch =~ /i.86/);
        return $arch;
    } else {
        OSCAR::Logger::oscar_log(5, ERROR, "Don't know how to detect package pool architecture for $pkg.");
        return "unknown";
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
    my ($version,$flavor);
    for my $f (@files) {
        my $v = `rpm -q --qf "%{VERSION}" -p $f 2>/dev/null`;
        # don't care about release for pools, only version counts (except for openSUSE)
        $v =~ s/\.\d+$// if ($distro ne "suse");
        # for redhat-el
        if ($v =~ /^(.*)(AS|WS|ES)$/) {
            $v = $1;
            $flavor = $2;
        } elsif ( $v =~ /^(\d*)[A-Za-z]*/){ # DI, Added to take care of RHEL-5
            $v = $1;
        }
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
    distro           => $flavor ? $distro."-".lc($flavor) : $distro,
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

# common routine for pool detection of debian based distros
sub detect_pool_deb {
    my ($pool,$detect_package,$distro,$compat) = @_;

    if (! -d "$pool") {
        return undef;
    }
    my @files = glob("$pool/$detect_package"."_"."*.deb");
    if (!scalar(@files)) {
        return undef;
    }

    # version recognition must be fixed!
    # debian's detect package is base-files, its version number
    # is not the same as the debian distro version!
    my ($version,$flavor);
    for my $f (@files) {
        my $v = `dpkg-query --queryformat %{VERSION} $f 2>/dev/null`;
        # don't care about release for pools, only version counts
        $v =~ s/\.\d+$//;
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
    pkg              => "deb",
    };
    # determine architecture
    my $arch = detect_arch_pool($pool,"deb");
    # FIXME: Should check $arch.
    $id->{arch} = $arch;
    return $id;
}

#
# For pools referenced by URL find compat distro name and generate
# fake $id structure
#
sub detect_fake_common ($$$$$) {
    my ($id, $distro, $compat_distro, $compat_distrover, $pkg) = @_;
    if (exists($id->{distro}) && exists($id->{distro_version}) &&
        exists($id->{arch})) {
        if ($id->{distro} eq $distro) {
            $id->{compat_distro} = $compat_distro;
            if (defined ($compat_distrover)) {
                $id->{compat_distrover} = $compat_distrover;
            } else {
                $id->{compat_distrover} = $id->{distro_version};
            }
            $id->{pkg} = $pkg;
            return $id;
        }
    }
    return undef;
}

sub detect_oscar_pool_common ($$) {
    my ($pool, $compat) = @_;

    my ($compat_distro, $arch, $version);
    my $arches = "i386|x86_64|aarch64|ia64|ppc64";
    if ( ($pool =~ /(.*)\-(\d+)\-($arches)(|\.url)$/) ||
        ($pool =~ /(.*)\-(\d+.\d+)\-($arches)(|\.url)$/) ) {
        $compat_distro = $1;
        $version = $2;
        $arch = $3;
    }

    if ($compat eq $compat_distro) {
        return 1;
    } else {
        return 0;
    }
}

sub parse_os_release {
    my $root='/';
    $root = shift if (@_); # If root specified as argument, use that instead of default '/'
    if (! -d "$root") {
        OSCAR::Logger::oscar_log(5, ERROR, "Invalid root path: $root");
        return undef;
    }
    $root =~ s|/+$||; # Cleanup trailing slash(es).
    if (! -f "$root/etc/os-release") {
        OSCAR::Logger::oscar_log(5, INFO, "$root/etc/os-release doesn't exists.");
        return undef;
    }

    my $os_release={};

    if( CORE::open(OS,"cat $root/etc/os-release|") ) {
        while (<OS>){
            my @os_param = split(/=/, $_);
	    next if (! defined($os_param[1] )); # Skip empty lines
	    next if $os_param[1] =~ /^\s*$/; # Skip blank lines
	    $os_param[1] =~ s/^"(.*)"$/$1/; # Remove surrounding strings
	    chomp($os_param[1]);
	    $os_param[1] = int($os_param[1]) if ($os_param[1] =~ /^[1-9][0-9]*$/);
            $os_release->{$os_param[0]}=$os_param[1];
        }
        close(OS);
    }

    return $os_release;
}

1;

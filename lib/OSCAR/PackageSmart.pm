package OSCAR::PackageSmart;
#
# Copyright (c) 2006 Erich Focht efocht@hpce.nec.com>
#                    All rights reserved.
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
# 
#   $Id: PackagePath.pm 4178 2006-01-26 11:07:13Z efocht $
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Build repository paths depending on distro, version, etc...

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use OSCAR::PackMan;           # this only works when PackMan has arrived!
use OSCAR::Distro;
use File::Basename;
use Switch;
use Cwd;
use Carp;

@EXPORT = qw(
            detect_pool_format
            checksum_write
            checksum_needed
            checksum_files
            );

my $verbose = $ENV{OSCAR_VERBOSE};


################################################################################
# Detect the format of a given repository, i.e., "deb" or "rpm".               #
#                                                                              #
# Input: pool, pool URL we have to analyse (for instance                       #
#              /tftpboot/oscar/debian-4-x86_640.                               #
# Return: "deb" if it is a Debian pool, "rpm" if it is a RPM pool.             #
################################################################################
sub detect_pool_format ($) {
    my $pool = shift;
    my $format = "";
    my $binaries = "rpm|deb";
    print "Analysing $pool\n" if $verbose;
    # Online repo
    if ( index($pool, "http", 0) >= 0) {
        print "This is an online repository ($pool)\n" if $verbose;
        my $url;
        if ( $pool =~ /\/$/ ) {
            $url = $pool . "repodata/repomd.xml";
        } else {
            $url = $pool . "/repodata/repomd.xml";
        }
        my $cmd = "wget -S --delete-after -q $url";
        print "Testing remote repository type by using command: $cmd... " if $verbose;
        if (!system("wget -S --delete-after -q $url")) {
            print "[yum]\n" if $verbose;
            $format = "rpm";
        } else {
            # if the repository is not a yum repository, we assume this is
            # a Debian repo. Therefore we assume that all specified repo
            # are valid.
            print "[deb]\n" if $verbose;
            $format = "deb";
        }
    } elsif (index($pool, "/tftpboot/", 0) == 0) {
        # Local pools
        # we check pools for common RPMs and common debs
        my $pool_id = basename ($pool);
        print "Pool id: $pool_id.\n" if $verbose;
        if ( ($pool_id =~ /common\-($binaries)s$/) ) {
            $format = $1;
            print "Pool format: $format\n" if $verbose;
        } else {
            # Finally we check pools in tftpboot for specific distros
            # TODO: we should have a unique function that allows us to validate
            # a distro ID.
            my ($distro, $arch, $version);
            my $arches = "i386|x86_64|ia64|ppc64";
            if ( ($pool_id =~ /(.*)\-(\d+)\-($arches)(|\.url)$/) ||
                ($pool_id =~ /(.*)\-(\d+.\d+)\-($arches)(|\.url)$/) ) {
                $distro = $1;
                $version = $2;
                $arch = $3;
            }
            print "Distro id (OS_Detect syntax distro-version-arch: ".
                  "$distro-$version-$arch\n" if $verbose;
            my $os = OSCAR::OCA::OS_Detect::open(fake=>{distro=>$distro,
                                distro_version=>$version,
                                arch=>$arch, }
                                );
            if (!defined($os) || (ref($os) ne "HASH")) {
                print "ERROR: OSCAR does not support to distro for the pool ".
                      $pool." ($distro, $arch, $version)\n";
                return undef;
            }
            $format = $os->{pkg};
            print "Pool format: $format\n\n\n" if $verbose;
        }
    } else {
        print "ERROR: Impossible to recognize pool $pool\n";
        return undef;
    }
    return $format;
}

################################################################################
# Generate the checksum for a given pool.                                      #
#                                                                              #
# Input: pool, pool URL for which we want to generate the checksum.            #
# Return: return the error code from pool_gencahe().                           #
################################################################################
sub generate_pool_checksum ($) {
    my $pool = @_;
    my $err;

    print "--- checking md5sum for $pool" if $verbose;
    if ($pool =~ /^(http|ftp|mirror)/) {
        print " ... remote repo, no check needed.\n" if $verbose;
        next;
    }
    print "\n" if $verbose;

    my $cfile = "$ENV{OSCAR_HOME}/tmp/pool_".basename(dirname($pool)).
                "_".basename($pool).".md5";
    my $md5 = &checksum_needed($pool,$cfile,"*.rpm","*.deb");
    if ($md5) {
        my $pm;
        my $pool_type = detect_pool_format ($pool);
        if ($pool_type eq "rpms") {
            $pm = PackMan::RPM->new;
        } elsif ($pool_type eq "debs") {
            $pm = PackMan::DEB->new;
        } else {
            # if the binary package format of the pool was not previously 
            # detected, we fall back to the PackMan mode by default.
            $pm = PackMan->new;
        }
        $err = &pool_gencache($pm,$pool);
        if (!$err) {
            &checksum_write($cfile,$md5);
        }
    }
    return $err;
}

################################################################################
#                        !!!!!!!! DEPRECATED !!!!!!!!                          #
# Prepare a serie of pools:                                                    #
#   - detect the pool format and returns a Packman handler for the specific    #
#     pool,                                                                    #
# The situation may be tricky: on Debian is possible to create images for      #
# Debian based systems but also for RPM based systems. Therefore, when we have #
# to prepare pools, we check first what is the binary package format of the    #
# distro. That also allow us to instantiate Packman according to the binary    #
# format used by the pools.                                                    #
#                                                                              #
# THIS FUNCTION IS TYPICALLY DEPRECATED BECAUSE IMPLEMENT SEVERAL LOOPS BASED  #
# ON THE LIST OF REPOSITORIES WE CAN POSSIBLY HAVE, INSTANCIATE PACKMAN AND    #
# TRY THEN TO USE PACKMAN. UNFORTUNATELY WE CURRENTLY SUPPORT DIFFERENT LINUX  #
# DISTRIBUTION THAT CAN HAVE DIFFERENT BINARY FORMAT (RPM VERSUS DEBIAN) IT IS #
# THEREFORE IMPOSSIBLE TO USE THE CURRENT IMPLEMENTATION OF THIS FUNCTION      #
# WHICH ASSUMES THAT ONE PACKMAN INSTANCIATION CAN BE USED FOR _ALL_ POOLS.    #
#                                                                              #
# Input: ???                                                                   #
# Return: an instance of Packman adapted to the pool prepared.                 #
################################################################################
sub prepare_pools {
    my ($verbose,@pargs) = @_;

    $verbose = 1;
    # demultiplex pool arguments
    my @pools;
    print "Preparing pools: " if $verbose;
    for my $p (@pargs) {
        print "$p " if $verbose;
        push @pools, split(",",$p);
    }
    print "\n" if $verbose;

    my $binaries = "rpms|debs";
    my $archs = "i386|x86_64|ia64";
    # List of all supported distros. 
    my @distros_list = OSCAR::Distro::get_list_of_supported_distros_id();
    my $distros = "";
    for (my $i=0; $i<scalar(@distros_list)-1; $i++) {
        $distros .= @distros_list[$i] . "|";
    }
    $distros .= $distros_list[scalar(@distros_list)-1];
    my $format = "";
    # Before to prepare a pool, we try to detect the binary package format
    # associated Not that for a specific pool or set of pools, it is not
    # possible to mix deb and rpm based pools.
    for my $pool (@pools) {
        $format = detect_pool_format ($pool);
    }
    print "Binary package format for the image: $format\n" if $verbose;

    # check if pool update is needed
    my $pm;
    if ($format eq "rpms") {
        $pm = PackMan::RPM->new;
    } elsif ($format eq "debs") {
        $pm = PackMan::DEB->new;
    } else {
        # if the binary package format of the pool was not previously detected,
        # we fall back to the PackMan mode by default.
        $pm = PackMan->new;
    }
    return undef if (!$pm);

    # follow output of smart installer
    if ($verbose) {
        $pm->output_callback(\&print_output);
    }

    my $perr;
    for my $pool (@pools) {
        # Check pool checksum
        $perr = generate_pool_checksum ($pool);
    }
    if ($perr) {
        undefine $pm;
        print "Error: could not setup or generate package pool metadata\n";
        return undef;
    }

    # prepare for smart installs
    $pm->repo(@pools);
    return $pm;
}

################################################################################
# Prepare a given pool, i.e., generation of the checksum and create a Packman  #
# object for future pool handling.                                             #
#                                                                              #
# Input: verbose, do you want logs or not (0 = no, anything else = yes)?       #
#        pool, pool URL we need to prepare.                                    #
# Return: Packman object that can handle the pool.                             #
################################################################################
sub prepare_pool ($$) {
    my ($verbose,$pool) = @_;

    $verbose = 1;
    # demultiplex pool arguments
    my @pools;
    print "Preparing pools: $pool\n" if $verbose;

    # Before to prepare a pool, we try to detect the associated binary package
    # format.
    my $format = detect_pool_format ($pool);
    print "Binary package format for the pool: $format\n" if $verbose;

    # check if pool update is needed
    my $pm;
    if ($format eq "rpms") {
        $pm = PackMan::RPM->new;
    } elsif ($format eq "debs") {
        $pm = PackMan::DEB->new;
    } else {
        # if the binary package format of the pool was not previously detected,
        # we fall back to the PackMan mode by default.
        $pm = PackMan->new;
    }
    return undef if (!$pm);

    # follow output of smart installer
    if ($verbose) {
        $pm->output_callback(\&print_output);
    }

    my $perr = generate_pool_checksum ($pool);
    if ($perr) {
        undefine $pm;
        print "Error: could not setup or generate package pool metadata\n";
        return undef;
    }

    # prepare for smart installs
    $pm->repo($pool);
    return $pm;
}

################################################################################
# Setup the pools associated to a specifc distro.                              #
#                                                                              #
# Input: os, hash representing OS data, hash returned by OS_Detect.            #
# Return: a packman object that handles the distro specifiec pools.            #
################################################################################
sub prepare_distro_pools ($) {
    my ($os) = shift;

    #
    # Locate package pools and create the directories if they don't exist, yet.
    #
    my $oscar_pkg_pool = &OSCAR::PackagePath::oscar_repo_url(os=>$os);
    my $distro_pkg_pool = &OSCAR::PackagePath::distro_repo_url(os=>$os);

    # We check that the two repos have the same format, it is a basic assert
    my $type1 = OSCAR::PackageSmart::detect_pool_format ($oscar_pkg_pool);
    my $type2 = OSCAR::PackageSmart::detect_pool_format ($distro_pkg_pool);
    if ($type1 ne $type2) {
        croak "ERROR: the two pools for the local distro are not of the same ".
              "type ($type1, $type2)\n";
    }

#     eval("require OSCAR::PackMan");
    my $pm = OSCAR::PackageSmart::prepare_pool($verbose,$oscar_pkg_pool);
    if (!$pm) {
        croak "\nERROR: Could not create PackMan instance!\n";
    }
    # gv: do we really need to create a pm2 object?
    my $pm2 = OSCAR::PackageSmart::prepare_pool($verbose,$distro_pkg_pool);
    if (!$pm2) {
        croak "\nERROR: Could not create PackMan instance!\n";
    }
    # we do not need anymore pm2, we used it only to prepare the repo and check
    # if everything was fine
    undefine $pm2;

    # To be able to manage the two repos with a single Packman object, we add
    # the second repo to the list of repos the first Packman can manage.
    $pm->repo($distro_pkg_pool);

    return $pm;
}

################################################################################
# Generate metadata cache for package pool.                                    #
#                                                                              #
# Input: pm, PackMan object associated to a specific pool.                     #
#        pool, pool URL that we have to deal with.                             #
# Return: 1 for success, 0 else.                                               #
################################################################################
sub pool_gencache ($$) {
    my ($pm, $pool) = @_;
    my @words = split("/", $pool);
    my $yum_cache_cookie = "/var/cache/yum/$words[-2]_$words[-1]/cachecookie";

    # yum 2.6.0+ creates a file called cachecookie in /var/cache/yum/<repo> and
    # inorder to refresh the yum cache, this file needs to be deleted
    if (-f $yum_cache_cookie) {
        print "Deleting file $yum_cache_cookie\n";
        unlink($yum_cache_cookie) or croak("Failed to delete file $yum_cache_cookie");
    }

    $pm->repo($pool);
    print "Calling gencache for $pool, this might take a minute ...";

    my ($err, @out) = $pm->gencache;
    if ($err) {
        print " success\n";
        return 0;
    } else {
        print " error. Output was:\n";
        print join("\n",@out)."\n";
        return 1;
    }
}

################################################################################
# Find files matching the patterns and generate a md5 checksum over its        #
# metadata. The file content is not considered, this would take too long.      #
#                                                                              #
# Input: ???                                                                   #
# Return: ???                                                                  #
################################################################################
sub checksum_files {
    my ($dir, @pattern) = @_;
    return 0 if (! -d $dir);
    my $wd = cwd();
    chdir($dir);
    my $md5sum_cmd;
    # Since some distros does not support "md5sum -" to get the std input
    # we check first what md5sum we have to use. Not that currently only
    # Debian Sarge seems to not support "md5sum -"
    if (system ("echo \"toto\" | md5sum - > /dev/null 2>&1")) {
        $md5sum_cmd = "md5sum ";
    } else {
        $md5sum_cmd = "md5sum - ";
    }
    print "Checksumming directory ".cwd()."\n" if ($verbose);
    @pattern = map { "-name '".$_."'" } @pattern;
    my $cmd = "find . -follow -type f \\( ".join(" -o ",@pattern).
	" \\) -printf \"%p %s %u %g %m %t\\n\" | sort ";
    if ($verbose > 7) {
	my $tee = $ENV{OSCAR_HOME}."/tmp/".basename($dir).".files";
	$cmd .= "| tee $tee | $md5sum_cmd ";
    } else {
	$cmd .= "| $md5sum_cmd ";
    }
    print "Executing: $cmd\n" if ($verbose);
    local *CMD;
    open CMD, "$cmd |" or croak "Could not run md5sum: $!";
    my ($md5sum,$junk) = split(" ",<CMD>);
    close CMD;
    chdir($wd);
    print "Checksum was: $md5sum\n" if ($verbose);
    return $md5sum;
}

################################################################################
# Write checksum file.                                                         #
#                                                                              #
# Input: file, file path we have to use to save the checksum.                  #
#        checksum, checksum to save.                                           #
################################################################################
sub checksum_write {
    my ($file,$checksum) = @_;
    local *OUT;
    open OUT, "> $file" or croak "Could not open $file: $!";
    print OUT "$checksum\n";
    close OUT;
    print "Wrote checksum file $file: $checksum\n" if ($verbose);
}

#
# Read a checksum file
#
sub checksum_read {
    my ($file) = @_;
    local *IN;
    open IN, "$file" or croak "Could not open $file: $!";
    my $in = <IN>;
    chomp $in;
    close IN;
    print "Read checksum file $file: $in\n" if ($verbose);
    return $in;
}

#
# Is a new checksum needed? Check current checksum for directory $dir and
# and file patterns @pattern, compare with checksum stored in file $cfile.
# Return current checksum if $cfile is missing or checksum is different from
# the one stored. Return 0 otherwise, i.e. if no new checksum is needed.
#
sub checksum_needed {
    my ($dir, $cfile, @pattern) = @_;

    my $md5 = &checksum_files($dir,@pattern);
    print "Current checksum ($cfile): $md5\n" if ($verbose);
    my $ifile = $dir . "/" . basename($cfile);
    if (-f $cfile) {
	my $omd5 = &checksum_read($cfile);
	print "Old checksum ($cfile): $omd5\n" if ($verbose);
	if ($md5 == $omd5) {
	    return 0;
	} else {
	    print "CHECKSUM: $cfile new:$md5 old:$omd5\n";
	}
    } elsif (-f $ifile) {
	#
	# repo-internal checksum for repositories delivered as tarballs
	# they should contain the metadata cache already, therefore
	# simply copy the internal checksum to the expected checksum file
	#
	my $imd5 = &checksum_read($ifile);
	print "Repo-internal checksum ($ifile): $imd5\n" if ($verbose);
	if ($md5 == $imd5) {
	    # [EF: is the failure handling appropriate?]
	    !system("cp $ifile $cfile")
		or carp("Could not copy internal checksum file to $cfile");
	    return 0;
	} else {
	    print "CHECKSUM: $cfile new:$md5 internal:$imd5\n";
	}
    }
    return $md5;
}

sub print_output {
    my ($line) = @_;
    $| = 1;
    print "$line\n";
}


1;

package OSCAR::PackageSmart;
#
# Copyright (c) 2006 Erich Focht efocht@hpce.nec.com>
#                    All rights reserved.
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
# 
#   $Id$
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
use OSCAR::Env;
use OSCAR::OCA::OS_Detect;
use OSCAR::Distro;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::Utils;
use File::Basename;
use Switch;
use Cwd;
use Carp;

@EXPORT = qw(
            checksum_write
            checksum_needed
            checksum_files
            detect_pool_format
            detect_pools_format
            prepare_distro_pools
            prepare_pool
            prepare_pools
            );

################################################################################
# The detection of the format associated to oscar pools is not trivial first of#
# all because these pools name are based on the compat_distro and _not_ the    #
# distro name. As a result, and since OS_Detect does not work only with a      #
# compat_distro, a distro name is actually mandatory, we cannot use OS_Detect  #
# to detect the pool format (which is very bad BTW! it removes a big interest  #
# of OS_Detect).                                                               #
# So we do the detection manually. :-(                                         #
# BTW remember that an OSCAR pool CAN be empty, you cannot assume the repo has #
# any kind of packages.                                                        #
#                                                                              #
# Return: the pool format (rpm or deb), undef if error.                        #
################################################################################
sub detect_oscar_pool_format ($) {
    my $pool_id = shift;
    my $binaries = "rpm|deb";
    my $format;
    my ($compat_distro, $arch, $version);
    oscar_log(5, INFO, "Detecting the OSCAR pool $pool_id");
    # Pools for common rpms and debs are fairly simple to deal with
    if ( ($pool_id =~ /common\-($binaries)s$/) ) {
        $format = $1;
        oscar_log(5, INFO, "Pool format: $format");
    } else {
        # Other pools are more difficult to deal with, OS_Detect cannot be 
        # with compat query for specific distros
        ($compat_distro, $version, $arch) =
            OSCAR::PackagePath::decompose_distro_id($pool_id);
        oscar_log(5, INFO, "Distro id (OS_Detect syntax distro-version-arch: ".
              "$compat_distro-$version-$arch)");
        my $os = OSCAR::OCA::OS_Detect::open(oscar_pool=>"$compat_distro-$version-$arch");
        if (!defined($os) || (ref($os) ne "HASH")) {
            oscar_log(5, ERROR, "OSCAR does not support the OSCAR pool ".
                 $pool_id." ($compat_distro, $arch, $version)");
            return undef;
        }
        $format = $os->{pkg};
    }
    return $format;
}

################################################################################
# The format detection for the distro pools is faily simple, the pool name     #
# strictly follow the OS_Detect syntax for distro names.                       #
################################################################################
sub detect_distro_pool_format ($) {
    my $pool_id = shift;
    my $format;

    oscar_log(5, INFO, "Detecting the distro pool $pool_id");
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
    # Note that directories in /tftpboot/dist and /tftpboot/oscar do not
    # follow the same naming rules. In /tftpboot/dist the distro name is
    # used, in /tftpboot/oscar the compat distro name is used.
    oscar_log(5, INFO, "Distro id (OS_Detect syntax distro-version-arch: ".
            "$distro-$version-$arch");
    my $os = OSCAR::OCA::OS_Detect::open(fake=>{distro=>$distro,
                        distro_version=>$version,
                        arch=>$arch, }
                        );
    if (!defined($os) || (ref($os) ne "HASH")) {
        oscar_log(5, INFO, "ERROR: OSCAR does not support the distro for the pool ".
             $pool_id." ($distro, $arch, $version)");
        return undef;
    }
    $format = $os->{pkg};
    oscar_log(5, INFO, "Pool format: $format");
    return $format;
}

################################################################################
# Detect the format of a given repository, i.e., "deb" or "rpm".               #
# Note that OS_Detect can currently only be used to detect the format of pools #
# in /tftpboot/distro since there are the only one to be based on the distro   #
# name, the only mode supported by OSCAR.                                      #
#                                                                              #
# Input: pool, pool URL we have to analyse (for instance                       #
#              /tftpboot/oscar/debian-4-x86_640.                               #
# Return: "deb" if it is a Debian pool, "rpm" if it is a RPM pool.             #
################################################################################
sub detect_pool_format ($) {
    my $pool = shift;
    my $format = "";
    my $binaries = "rpm|deb";
    oscar_log(5, INFO, "Analysing $pool");
    # Online repo
    require OSCAR::PackagePath;
    if (OSCAR::PackagePath::repo_local ($pool) == 0) {
#        OSCAR::Logger::oscar_log_subsection "This is an online repository ($pool)";
        oscar_log(5, INFO, "Not a local repo. Assuming this is an online repo");
        my $url;
        if ( $pool =~ /\/$/ ) {
            $url = $pool . "repodata/repomd.xml";
        } else {
            $url = $pool . "/repodata/repomd.xml";
        }
        my $cmd = "wget --tries 10 --timeout=9 -S --delete-after -q $url";
#        oscar_log_subsection "Testing remote repository type by using ".
#                             "command: $cmd... ";
        my @tokens = split (/\+/, $pool);
        my $rc = oscar_system($cmd);
        if(scalar (@tokens) > 1) {
            oscar_log(5, INFO, "Plus sign in pool, assuming this is a deb repo.");
            $format = "deb";
        } elsif ($rc == 0) {
            oscar_log(5, INFO, "Identified yum repo.");
            $format = "rpm";
        } elsif ($rc == 4) {
            # Not a deb repo (tested above) , but failed to connect.
            # Assuming pool is correct and is an yum repo (better than noting)
            oscar_log(5, WARNING, "Unable to get $url (cnx failed), can't test if it's a yum repo.\n".
                                  "As we are sure it's not a apt repo, we default to yum\n".
                                  "(Better than nothing)");
        } else {
            oscar_log(5, ERROR, "Malformed or non-existent url.\n\t Failed to detect the format of the online ".
                 "repository ($pool)");
            return undef;
        }
    } elsif (index($pool, "/tftpboot/distro", 0) == 0 
            || index($pool, "file:/tftpboot/distro", 0) == 0) {
        # Local pools for distros
        my $pool_id = basename ($pool);
        oscar_log(5, INFO, "Found local pool id: $pool_id.");
        $format = detect_distro_pool_format ($pool_id);
    } elsif (index($pool, "/tftpboot/oscar", 0) == 0 
            || index($pool, "file:/tftpboot/oscar", 0) == 0) {
        my $pool_id = basename ($pool);
        oscar_log(5, INFO, "Found local pool id: $pool_id.");
        $format = detect_oscar_pool_format ($pool_id);
    } else {
        # If we try to analyse a local repo that is not in /tftpboot, we try to
        # see if it is not a repo for OSCAR (such as a weborm repo).
        my $pool_id = basename ($pool);
        oscar_log(5, INFO, "Found pool id: $pool_id.");
        $format = detect_oscar_pool_format ($pool_id);
        if (!defined ($format)) {
            oscar_log(5, ERROR, "Fail to recognize pool $pool");
            return undef;
        }
    }
    oscar_log(5, INFO, "Detected format for pool $pool: $format");
    return $format;
}

################################################################################
# Generate the checksum for a given pool.                                      #
#                                                                              #
# Input: pool, pool URL for which we want to generate the checksum.            #
# Return: return the error code from pool_gencahe().                           #
################################################################################
sub generate_pool_checksum ($) {
    my $pool = shift;
    my $err;

    oscar_log(5, INFO, "Checking md5sum for $pool");
    if ($pool =~ /^(http|ftp|mirror)/) {
        oscar_log(5, INFO, " This is a remote repo, no check needed.");
    }

    my $cfile = "$ENV{OSCAR_HOME}/tmp/pool_".basename(dirname($pool)).
                "_".basename($pool).".md5";
    my $md5 = &checksum_needed($pool,$cfile,"*.rpm","*.deb");
    if ($md5) {
        my $pm;
        my $pool_type = detect_pool_format ($pool);
        oscar_log(5, INFO, "Pool type: $pool_type");
        require OSCAR::PackMan;
        if ($pool_type eq "rpm") {
            $pm = OSCAR::PackMan::RPM->new;
        } elsif ($pool_type eq "deb") {
            $pm = OSCAR::PackMan::DEB->new;
        } else {
            oscar_log(5, ERROR, "Unknown pool type");
            return -1;
        }
        $err = &pool_gencache($pm,$pool);
        if (!$err) {
            &checksum_write($cfile,$md5);
        }
    }
    return $err;
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

    # demultiplex pool arguments
    oscar_log(2, SUBSECTION, "Preparing pool: $pool");

    # Before to prepare a pool, we try to detect the associated binary package
    # format.
    my $format = detect_pool_format ($pool);
    oscar_log(5, INFO, "Binary package format for the pool: ".
        $format);

    # check if pool update is needed
    my $pm;
    require OSCAR::PackMan;
    if ($format eq "rpm") {
        $pm = OSCAR::PackMan::RPM->new;
    } elsif ($format eq "deb") {
        $pm = OSCAR::PackMan::DEB->new;
    } else {
        oscar_log(5, ERROR, "Impossible to detect the pool format ($pool)");
        return undef;
    }
    return undef if (!$pm);

    # follow output of smart installer
    if ($OSCAR::Env::oscar_verbos) {
        $pm->output_callback(\&print_output);
    }

    my $perr = generate_pool_checksum ($pool);
    if ($perr) {
        undefine $pm;
        oscar_log(5, ERROR, "Could not setup or generate package pool metadata");
        return undef;
    }

    # prepare for smart installs
    $pm->repo($pool);
    oscar_log(2, SUBSECTION, "Pool: $pool ready");
    return $pm;
}

# Return: the pools' format (e.g., deb, rpm), undef else.
sub detect_pools_format (@) {
    my @pools = @_;
    my $format = undef;

    foreach my $p (@pools) {
        next if ($p eq "");
        my $type = OSCAR::PackageSmart::detect_pool_format ($p);
        if (!defined $type) {
            oscar_log(5, ERROR, "Impossible to prepare pool $p, unknown format");
            return undef;
        }
        if (!defined $format || $format eq "") {
            # This is the first pool we analyze, we keep its format for later
            # comparison
            $format = $type;
        } else{
            if ($type ne $type) { # OL: There is a BUG here... Need to analyse
                oscar_log(5, ERROR, "The two pools for the local distro are not of".
                     "the same type ($format, $type)");
                return undef;
            }
        }
    }
    return $format;
}

################################################################################
# This function prepares a set of repositories.                                #
# !!!WARNING!!! All the repositories have to be based on the same binary       #
# package format (for instance RPM or Deb).                                    #
# We strongly encourage developers to use the function prepare_distro_repos()  #
# if they want to prepare repos assiocated to a specific distribution.         #
#                                                                              #
# Input: verbose, do you want verbose or not? 0 = no, anything else = yes      #
#        pools, array with the list of repos to prepare.                       #
# Return: the packman object that can handle these repos, undef if error.      #
################################################################################
sub prepare_pools ($@) {
    my ($v, @pools) = @_;

    oscar_log(2, SUBSECTION, "Preparing pools: @pools");
    if (scalar (@pools) == 0) {
        oscar_log(5, WARNING, "No repositories defined, nothing to do");
        return undef;
    }

    # First we check pools all support the same format (rpm vs. deb).
    my $format = detect_pools_format (@pools);
    if (!defined $format) {
        oscar_log(5, ERROR, "Impossibe to detect the pools' format");
        return undef;
    }

    # Then we actually prepare the pools
    my $pm;
    foreach my $p (@pools) {
        oscar_log(6, INFO, "Pool: $p");
        $pm = prepare_pool($v, $p);
        if (!$pm) {
            oscar_log(5, ERROR, "Could not create PackMan instance!");
            return undef;
        }
    }
    $pm->repo(@pools);

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
    my @repos;

    #
    # Locate package pools and create the directories if they don't exist, yet.
    # The pools are:
    #   - the pool related to the distro (e.g., /tftpboot/distro/centos-5-x86_64
    #   - the pool for common OSCAR binary packages (e.g., 
    #     /tftpboot/oscar/common-rpms)
    #   - the pool; for arch-dependent OSCAR binary packages (e.g., 
    #     /tftpboot/oscar/rhel-5-x86_64)
    #
    my $oscar_pkg_pool = OSCAR::PackagePath::oscar_repo_url(os=>$os);
    my $distro_id = "$os->{distro}-$os->{distro_version}-$os->{arch}";
    my $distro_pkg_pool = OSCAR::PackagePath::distro_repo_url(os=>$os);
    # OSCAR pools may be composed of two different parts: common binary package
    # and binary package specific to the distro
    my @pools = split(",", $oscar_pkg_pool);
    my @distro_pools = split(",", $distro_pkg_pool);
    foreach my $repo (@distro_pools) {
        next if $repo eq "";
        push (@pools, $repo);
    }
    oscar_log(5, INFO, "Pools to prepare for distro $distro_id:");
    OSCAR::Utils::print_array (@pools);

    my $pm = OSCAR::PackageSmart::prepare_pools ($OSCAR::Env::oscar_verbose, @pools);

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
        oscar_log(5, INFO, "Deleting file $yum_cache_cookie");
        unlink($yum_cache_cookie) 
            or (oscar_log(5, ERROR, "Failed to delete file $yum_cache_cookie"),
                return 0);
    }

    $pm->repo($pool);
    oscar_log(5, SUBSECTION, "Calling gencache for $pool, this ".
        "might take a minute...");

    # The packman return code is defined in PackManDefs.pm
    my ($err, @out) = $pm->gencache;
    if (!$err) {
        oscar_log(5, INFO, "Cache successfully generated");
        return 0;
    } else {
        oscar_log(5, ERROR, "Failed to generate cache ($err). Output was:"
            . join("\n",@out));
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
    oscar_log(5, INFO, "Checksumming directory ".cwd());
    @pattern = map { "-name '".$_."'" } @pattern;
    my $cmd = "find . -follow -type f \\( ".join(" -o ",@pattern).
    " \\) -printf \"%p %s %u %g %m %t\\n\" | sort ";
    if ($OSCAR::Env::oscar_verbose >= 7) {
        my $tee = $ENV{OSCAR_HOME}."/tmp/".basename($dir).".files";
        oscar_log(7, INFO, "Output of following command will be stored in $tee");
        $cmd .= "| tee $tee | $md5sum_cmd ";
    } else {
        $cmd .= "| $md5sum_cmd ";
    }
    oscar_log(7, ACTION, "About to run: $cmd");
    local *CMD;
    open CMD, "$cmd |" or (oscar_log(5, ERROR, "Could not run md5sum: $!"), return 0);
    my ($md5sum,$junk) = split(" ",<CMD>);
    close CMD;
    chdir($wd);
    oscar_log(5, INFO, "Checksum is: $md5sum");
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
    oscar_log(5, INFO, "Wrote checksum file $file: $checksum");
}

#
# Read a checksum file
#
sub checksum_read {
    my ($file) = @_;
    local *IN;
    open IN, "$file" or (oscar_log(5, ERROR, "Could not open $file: $!"), return 0);
    my $in = <IN>;
    chomp $in;
    close IN;
    oscar_log(5, INFO, "Read checksum file $file: $in");
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
    oscar_log(5, INFO, "Current checksum ($cfile): $md5");
    my $ifile = $dir . "/" . basename($cfile);
    if (-f $cfile) {
         my $omd5 = &checksum_read($cfile);
         oscar_log(5, INFO, "Old checksum ($cfile): $omd5");
         if ($md5 eq $omd5) {
             return 0;
         } else {
             oscar_log(5, INFO, "CHECKSUM: $cfile new:$md5 old:$omd5");
         }
    } elsif (-f $ifile) {
    #
    # repo-internal checksum for repositories delivered as tarballs
    # they should contain the metadata cache already, therefore
    # simply copy the internal checksum to the expected checksum file
    #
        my $imd5 = &checksum_read($ifile);
        oscar_log(5, INFO, "Repo-internal checksum ($ifile): $imd5");
        if ($md5 eq $imd5) {
            # [EF: is the failure handling appropriate?]
            !oscar_system("cp $ifile $cfile")
                or oscar_log(5, ERROR,"Could not copy internal checksum file to $cfile");
            return 0;
        } else {
            oscar_log(5, INFO, "CHECKSUM: $cfile new:$md5 internal:$imd5");
        }
    }
    return $md5;
}

sub print_output {
    my ($line) = @_;
    $| = 1;
    oscar_log(5, NONE, "$line");
}

1;

__END__

=head1 Exported Functions

=over 4

=item checksum_write

=item checksum_needed

=item checksum_files

=item detect_pool_format

=item detect_pools_format

=item prepare_distro_pools

=item prepare_pool

=item prepare_pools

=back

=cut

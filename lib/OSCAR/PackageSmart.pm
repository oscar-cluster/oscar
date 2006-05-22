package OSCAR::PackageSmart;
#
# Copyright (c) 2006 Erich Focht efocht@hpce.nec.com>
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
# Had to split this out of Package because it is needed during the prereqs
# install which happens such early that we cannot guarantee that XML::Simple
# (required by OSCAR::Package) is already available.
#
# Build repository paths depending on distro, version, etc...

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use OSCAR::PackMan;           # this only works when PackMan has arrived!
use File::Basename;
use Cwd;
use Carp;

@EXPORT = qw(
	     prepare_pools
	     checksum_write
	     checksum_needed
	     checksum_files
	     );

my $verbose = $ENV{OSCAR_VERBOSE};

sub prepare_pools {
    my ($verbose,@pargs) = @_;

    my $pm = PackMan->new;
    return undef if (!$pm);

    # follow output of smart installer
    if ($verbose) {
	$pm->output_callback(\&print_output);
    }

    # demultiplex pool arguments
    my @pools;
    for my $p (@pargs) {
	push @pools, split(",",$p);
    }
    # check if pool update is needed
    my $perr = 0;
    for my $pool (@pools) {
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
	    my $err = &pool_gencache($pm,$pool);
	    if ($err) {
		$perr++;
	    } else {
		&checksum_write($cfile,$md5);
	    }
	}
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

#
# Generate metadata cache for package pool
# 
sub pool_gencache {
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

#
# Find files matching the patterns and generate a md5 checksum
# over its metadata. The file content is not considered, this would
# take too long.
#
sub checksum_files {
    my ($dir, @pattern) = @_;
    return 0 if (! -d $dir);
    my $wd = cwd();
    chdir($dir);
    print "Checksumming directory ".cwd()."\n" if ($verbose);
    @pattern = map { "-name '".$_."'" } @pattern;
    my $cmd = "find . -follow -type f \\( ".join(" -o ",@pattern).
	" \\) -printf \"%p %s %u %g %m %t\\n\" | sort ";
    if ($verbose > 7) {
	my $tee = $ENV{OSCAR_HOME}."/tmp/".basename($dir).".files";
	$cmd .= "| tee $tee | md5sum -";
    } else {
	$cmd .= "| md5sum -";
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

#
# write checksum file
#
sub checksum_write {
    my ($file,$checksum) = @_;
    local *OUT;
    open OUT, "> $file" or croak "Could not open $file: $!";
    print OUT "$checksum\n";
    close OUT;
    print "Wrote checksum file $file: $checksum\n" if ($verbose);
}

#
# read checksum file
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

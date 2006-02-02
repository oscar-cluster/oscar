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
use OSCAR::Database;
use Cwd;
use Carp;

@EXPORT = qw(
	     prepare_pools
	     );

my $poolmd5 = "pool.md5";

sub prepare_pools {
    my ($verbose,$oscar_pkg_pool,$distro_pkg_pool) = @_;

    my $pm = PackMan->new;
    return undef if (!$pm);

    # check if pool update is needed
    for my $pool ($oscar_pkg_pool,$distro_pkg_pool) {
	if (&pool_needs_update($pool)) {
	    &pool_gencache($pm,$pool);
	    &mark_pool($pool);
	}
    }

    # prepare for smart installs
    $pm->repo($oscar_pkg_pool,$distro_pkg_pool);
    # follow output of smart installer
    if ($verbose) {
	$pm->output_callback(\&print_output);
    }
    return $pm;
}

#
# Generate metadata cache for package pool
# 
sub pool_gencache {
    my ($pm, $pool) = @_;

    $pm->repo($pool);
    print "Calling gencache for $pool, this might take a minute ...";
    my ($err, @out) = $pm->gencache;
    if ($err) {
	print " success\n";
    } else {
	print " error. Output was:\n";
	print join("\n",@out)."\n";
	# exit here?
    }
}


#
# Create a md5sum of the pool directory listing. This is stored in the file
# pool.md5 and used for detecting changes of the pool.
# 
sub mark_pool {
    my ($pool) = @_;

    local *OUT;
    my $wd = cwd();
    chdir($pool);
    my $out = `ls -Al -I "repocache" -I "repodata" -I "$poolmd5" | md5sum -`;
    my ($md5sum,$junk) = split(" ",$out);
    open OUT, "> $poolmd5" or die "Could not open $poolmd5 $!";
    print OUT "$md5sum\n";
    close OUT;
    chdir $wd;
}

#
# Create a md5sum of the pool directory listing. This is stored in the file
# pool.md5 and used for detecting changes of the pool.
# 
sub pool_needs_update {
    my ($pool) = @_;

    local *IN;
    my $wd = cwd();
    chdir($pool);
    my $out = `ls -Al -I "repocache" -I "repodata" -I "pool.md5" | md5sum -`;
    my ($md5sum,$junk) = split(" ",$out);
    # need update if no pool.md5 file
    if (! -f $poolmd5) {
	chdir $wd;
	return 1;
    }
    # load stored checksum
    open IN, "$poolmd5" or die "Could not open $poolmd5 $!";
    my $in = <IN>;
    chomp $in;
    close IN;
    chdir $wd;
    return ($in ne $md5sum);
}

sub print_output {
    my ($line) = @_;
    print "$line\n";
}


1;

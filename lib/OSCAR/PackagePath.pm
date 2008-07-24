package OSCAR::PackagePath;
#
# Copyright (c) 2006 Erich Focht efocht@hpce.nec.com>
#                    All rights reserved.
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                     Geoffroy R. Vallee <valleegr@ornl.gov>
#                     All rights reserved.
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
# Had to split this out of Package because it is needed during the prereqs
# install which happens such early that we cannot guarantee that XML::Simple
# (required by OSCAR::Package) is already available.
#
# Build repository paths depending on distro, version, etc...

use strict;
use vars qw(@EXPORT @PKG_SOURCE_LOCATIONS $PGROUP_PATH);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use OSCAR::Utils qw ( is_a_valid_string );
use OSCAR::FileUtils qw ( add_line_to_file_without_duplication );
use File::Basename;
use Data::Dumper;
use warnings "all";
use Carp;

@EXPORT = qw(
            distro_repo_url
	     oscar_repo_url
	     repo_empty
	     oscar_urlfile
	     distro_urlfile
	     repos_list_urlfile
	     repos_add_urlfile
	     repos_del_urlfile
	     os_distro_string
	     os_cdistro_string
	     pkg_extension
	     pkg_separator
	     distro_detect_or_die
	     list_distro_pools
            decompose_distro_id
            get_common_pool_id
            get_default_distro_repo
            get_default_oscar_repo
            get_repo_type
            get_list_setup_distros
            mirror_repo
            use_distro_repo
            use_oscar_repo
            use_default_distro_repo
            use_default_oscar_repo
	     @PKG_SOURCE_LOCATIONS
	     $PGROUP_PATH
	     );

my $tftpdir = "/tftpboot/";

# The possible places where packages may live.  
@PKG_SOURCE_LOCATIONS = ("/var/lib/oscar/packages");
if (defined $ENV{OSCAR_HOME}) {
    unshift (@PKG_SOURCE_LOCATIONS, "$ENV{OSCAR_HOME}/packages");
}

# Path of package group files used for client image generations
if (defined ($ENV{OSCAR_HOME})) {
    $PGROUP_PATH = "$ENV{OSCAR_HOME}/tmp";
} else {
    $PGROUP_PATH = "/tmp";
}

#
# Return an OS_Detect hash reference or die.
# Argument: $img
#           - if undefined, will detect distro of "/" on the current machine
#           - if set, will detect distro of the image located in that path
# Failure to detect the distro is a catastrophic event, so the program
# deserves to die.
#
# This routine might move to OSCAR::Distro when things stabilize...
#
sub distro_detect_or_die ($) {
    my ($img) = @_;
    my $os = OSCAR::OCA::OS_Detect::open($img);
    die "Unable to determine operating system for $img" if (!$os);
    return $os;
}


#
# Return list of repositories present in the URL file passed as argument.
#
sub repos_list_urlfile ($) {
    my ($path) = @_;

    my @remote;
    if (-f "$path") {
	local *IN;
	if (open IN, "$path") {
	    while (my $line = <IN>) {
		chomp $line;
		next if ($line !~ /^(http|ftp|file|mirror)/);
		next if (($line =~ /^\s*$/) || ($line =~ /^\s*\#/));
		push @remote, $line;
	    }
	    close IN;
	}
    }
    return @remote;
}

#
# Add repositories to a .url file. Create file if it doesn't exist.
#
# ERROR: 0 if success, -1 else.
sub repos_add_urlfile ($@) {
    my ($path, @repos) = (@_);

    # make sure local paths have "file:" prefix
    my %rhash;
    my @n;
    for (@repos) {
        s,^/,file:/,;
        if (!m,^(file|http|ftp|https|mirror):,) {
            carp "ERROR: Repository must either be a URL or an absolute path\n";
            return -1;
        }
	push @n, $_;
	$rhash{$_} = 1;
    }
    @repos = @n;

    local *OUT;
    if (! -f "$path") {
        carp "ERROR: Creating new .url file: $path with repositories\n  ".
        join("\n  ",@repos)."\n";
        my $dir = dirname($path);
        if (! -d $dir) {
            carp "ERROR: Creating directory $dir\n";
            !system("mkdir -p $dir")
                or (carp("ERROR: Could not create directory $dir! $!"),
                    return -1);
    }
	open OUT, "> $path" 
        or (carp("Could not open $path for writing. $!"), return -1);
	for (@repos) {
	    print OUT "$_\n";
	}
	close OUT;
	return 0;
    }
    #
    # if file exists, add at the end, but only if entry wasn't there.
    #
    local *IN;
    open IN, "$path" or croak("Could not open $path for reading. $!");
    my @orepos = <IN>;
    close IN;
    for (@orepos) {
	chomp;
	if (defined($rhash{$_})) {
	    delete $rhash{$_};
	}
    }
    return 0 if (!scalar(keys(%rhash)));

    #
    # write output file
    #
    open OUT, "> $path" or croak("Could not open $path for writing. $!");
    for (@orepos) {
	chomp;
	print OUT "$_\n";
    }
    # append the repos which need to be added
    for (sort(keys(%rhash))) {
	print OUT "$_\n";
    }
    close OUT;
    return 0;
}

#
# Delete repositories from a .url file.
#
# Input: - the .url file path,
#        - the list of repositories to remove (array).
# Output: 0 if success, -1 else.
sub repos_del_urlfile ($@) {
    my ($path, @repos) = (@_);

    if (! -f "$path") {
        carp ("ERROR: URL file $path does not exist!!!");
        return -1;
    }
    # build hash of repos to be deleted
    my %rhash;
    for (@repos) {
	s,^/,file:/,;
	if (!m,^(file|http|ftp|https|mirror):,) {
	    carp "ERROR: Repository must either be a URL or an absolute path\n";
	    return -1;
	}
	$rhash{$_} = 1;
    }
    local *IN;
    open IN, "$path"
        or (carp("Could not open $path for reading. $!"), return -1);
    my @orepos = <IN>;
    close IN;

    local *OUT;
    open OUT, "> $path" or croak("Could not open $path for writing. $!");
    for (@orepos) {
	chomp;
	if (!defined($rhash{$_})) {
	    print OUT "$_\n";
	} else {
	    delete $rhash{$_};
	}
    }
    close OUT;
    if (scalar(keys(%rhash))) {
        carp "WARNING: Following repositories were not found in $path:\n  ".
	    join("\  ",sort(keys(%rhash)))."\n";
        return -1;
    }
    return 0;
}

#
# Detect os for passed arguments.
# Common code for several subroutines.
#
sub query_os ($$) {
    my ($img, $os);
    if (scalar(@_) <= 1) {
	($img) = (@_);
    } elsif ($_[0] eq "os") {
	$os = $_[1];
    }
    if (!defined($os)) {
	$os = distro_detect_or_die($img);
    }
    return $os;
}

#
# Return distro .url file path for selected image or distro
#
# Return: the file path, undef if error.
sub distro_urlfile (%) {
    my $os = &query_os(@_);
    if (!defined($os) || ref($os) ne "HASH") {
        carp "ERROR: impossible to query the OS\n";
        return undef;
    }
    my $distro    = $os->{distro};
    my $distrover = $os->{distro_version};
    my $arch      = $os->{arch};
    return "/tftpboot/distro/$distro-$distrover-$arch.url";
}

#
# Return OSCAR .url file path for selected image or distro
# and packaging method.
#
# Return: the file path, undef if error.
sub oscar_urlfile (%) {
    my $os = &query_os(@_);
    if (!defined($os) || ref($os) ne "HASH") {
        print "ERROR: impossible to query the OS\n";
        return undef;
    }
    my $cdistro   = $os->{compat_distro};
    my $cdistrover= $os->{compat_distrover};
    my $arch      = $os->{arch};
    my $path = "/tftpboot/oscar/$cdistro-$cdistrover-$arch.url";
    return ($path, $os->{pkg});
}

#
# The URL where distribution packages are stored. When the files are
# stored locally they should go to:
# /tftpboot/distro/$distro-$version-$arch
# Doing this without subtrees of dirs has the advantage to immediately show
# the admin how many of these disk space consuming distro repositories are
# around.
#
# If the nodes have connectivity to the internet one could use a publicly
# accessible URL for the distro files. In that case place the URL of the
# repository (yum or apt) into the file
# /tftpboot/distro/$distro-$version-$arch.url
#
# Return: undef if error.
sub distro_repo_url (%) {
    my $url = &distro_urlfile(@_);
    my $os = &query_os(@_);
    if (!defined ($url) || $url eq "") {
        carp "ERROR: impossible to get a URL from OSCAR repo config file\n";
        return undef;
    }
    my $path = dirname($url)."/".basename($url, ".url");

    if (!-f "$url") {
	# create .url file and add local path as first entry
	&repos_add_urlfile("$url", "file:$path");

	if ( (! -d $path) && (! -l $path) ) {
	    #
	    # check if /tftpboot/rpm exists and has the distro we expect
	    #
	    my $oldpool = "/tftpboot/rpm";
	    if ( -d $oldpool || -l $oldpool) {
		my $ros = OSCAR::OCA::OS_Detect::open(pool => $oldpool);
		if (defined($ros) && (ref($ros) eq "HASH") &&
		    ($ros->{distro} eq $os->{distro}) &&
		    ($ros->{distro_version} eq $os->{distro_version}) &&
		    ($ros->{arch} eq $os->{arch}) ) {
		    print STDERR "Discovered correct distro repository in $oldpool!\n";
		    print STDERR "Linking it symbolically to $path.\n";
		    my $pdir = dirname($path);
		    if (! -d $pdir) {
			!system("mkdir -p $pdir") or
			    (carp "Could not make directory $pdir $!", return undef);
		    }
		    !system("ln -s $oldpool $path") or
			(carp "Could not link $oldpool to $path: $!", return undef);
		    return $url;
		}
	    }
	    print STDERR "Distro repository $path not found. "
		. "Creating empty directory.\n";
	    !system("mkdir -p $path") or
		(carp "Could not create directory $path! $!", return undef);
	}
    }
    my @repos = &repos_list_urlfile("$url");
    return join(",", @repos);
}

#
# The URL where OSCAR packages for a particular distro/version/arch
# combination are stored. This path is defined as:
# /tftpboot/oscar/$distro-$version-$arch
#
# Similar to the distro url, one can use a file called 
# /tftpboot/oscar/$distro-$version-$arch.url
# containing a list of URLs pointing at the repositories to be scanned for
# OSCAR packages. This allows having repositories located on the internet.
#
# The distro and version names used are those detected as "compat_distro"
# and "compat_distrover" in the OCA::OS_Detect framework. The reason is that
# OSCAR doesn't care about the particular flavor of a rebuilt distro, it
# uses the same packages eg. for rhel4, scientific linux 4 and centos 4.
#
# Usage:
#    $path = oscar_repo_url();         # detect distro of master ("/")
#    $path = oscar_repo_url($image);   # detect distro of image
#    $path = oscar_repo_url(os => $os);  # use given $os structure
#
# Usage logic:
# If a .url file exists, use the URLs listed inside.
# Otherwise expect local repositories to exist in the standard place. If the
# local repositories don't exist, create their directories.
#
# Return: undef if error.
sub oscar_repo_url (%) {
    my ($url, $pkg) = &oscar_urlfile(@_);
    if (!defined ($url) || $url eq "") {
        print "ERROR: impossible to get a URL from OSCAR repo config file\n";
        return undef;
    }
    my $path = dirname($url)."/".basename($url, ".url");
    my $comm = "/tftpboot/oscar/common-" . $pkg . "s";

    #
    # Add local paths to .url file, if not already there
    #
    &repos_add_urlfile("$url", "file:$path", "file:$comm");

    if (! -d $path && ! -l $path) {
        print STDERR "Distro repository $path not found. ".
            "Creating empty directory.\n";
        !system("mkdir -p $path") or
            (carp "Could not create directory $path!", return undef);
    }
    if (! -d $comm && ! -l $comm) {
        print STDERR "Commons repository $comm not found. ".
            "Creating empty directory.\n";
        !system("mkdir -p $comm") or
            croak "Could not create directory $comm!";
    }
    my @repos = &repos_list_urlfile("$url");
    return join(",", @repos);
}

#
# Check if local repo directory is empty.
# Returns 1 (true) if directory is empty, 0 else.
#
sub repo_empty ($) {
    my ($path) = (@_);
    my $entries = 0;
    local *DIR;
    opendir DIR, $path or (carp "Could not read directory $path!", return 0);
    for my $d (readdir DIR) {
	next if ($d eq "." || $d eq "..");
	$entries++ if (-f $d || -d $d);
    }
    return ($entries ? 0 : 1);
}

#
# List all available distro pools or distro URL files.
# Return: a hash, each key is composed by the distro id (e.g. debian-4-x86_64)
#         returned by OS_Detect; the value is composed of data from OS_Detect.
#         undef if error.
# Note that we assume here that /tftpboot/distro and /tftpboot/oscar are fully
# populated. If the directory /tftpboot/oscar and is not completely populated, 
# this function will create by defaults directories/files to have local 
# repositories.
sub list_distro_pools () {
    my $ddir = "/tftpboot/distro";
    # recognised architectures
    my $arches = "i386|x86_64|ia64|ppc64";
    my %pools;
    local *DIR;
    opendir DIR, $ddir 
        or (carp "Could not read directory $ddir!", return undef);
    for my $e (readdir DIR) {
        if ( ($e =~ /(.*)\-(\d+)\-($arches)(|\.url)$/) ||
            ($e =~ /(.*)\-(\d+.\d+)\-($arches)(|\.url)$/) ) {
            my $distro = "$1-$2-$3";
            my $os;
            if ($4) {
                $os = OSCAR::OCA::OS_Detect::open(fake=>{distro=>$1,
                                                distro_version=>$2,
                                                arch=>$3, }
                                                );
            } else {
                $os = OSCAR::OCA::OS_Detect::open(pool=>"$ddir/$e");
            }
            if (defined($os) && (ref($os) eq "HASH")) {
                $pools{$distro}{os} = $os;
                $pools{$distro}{oscar_repo} = &oscar_repo_url(os=>$os);
                $pools{$distro}{distro_repo} = &distro_repo_url(os=>$os);
                if ($4) {
                    $pools{$distro}{url} = "$ddir/$e";
                } else {
                    $pools{$distro}{path} = "$ddir/$e";
                }
            }
        }
    }
    return %pools;
}

#
# returns the package extension used for the packages in an image (or "/")
#
sub pkg_extension ($) {
    my ($img) = @_;   # can be undefined, in which case we query "/"
    my $os = distro_detect_or_die($img);
    my $pkg = $os->{pkg};
    if ($pkg =~ /^rpm$/) {
	return ".rpm";
    } elsif ($pkg =~ /^deb$/) {
	return ".deb";
    } else {
	return undef;
    }
}

#
# returns the package separator string used for packages in an image (or "/")
#
sub pkg_separator ($) {
    my ($img) = @_;   # can be undefined, in which case we query "/"
    my $os = distro_detect_or_die($img);
    my $pkg = $os->{pkg};
    if ($pkg =~ /^rpm$/) {
	return "-";
    } elsif ($pkg =~ /^deb$/) {
	return "_";
    } else {
	return undef;
    }
}

sub os_distro_string ($) {
    my ($os) = @_;
    return $os->{distro}."-".$os->{distro_version}.
	"-".$os->{arch};
}

sub os_cdistro_string {
    my ($os) = @_;
    return $os->{compat_distro}."-".$os->{compat_distrover}.
	"-".$os->{arch};
}

################################################################################
# Get the repository type (yum or apt).                                        #
#                                                                              #
# Input: repo_url, repository URL we want to check.                            #
# Return: apt if the repository is a debian repository, yum if it is a yum     #
#         repository.                                                          #
#                                                                              #
# TODO: check if the yume command does really work or not!                     #
################################################################################
sub get_repo_type ($) {
    my $repo_url = shift;

    # We determine the type of the repository. Note that we do not care
    # about the output, we only care about the return code.
    my $rapt_cmd = 
        "/usr/bin/rapt --repo $repo_url update 2>/dev/null 1>/dev/null";
    my $yume_cmd = "/usr/bin/yume $repo_url --repoquery";
    if (!system($rapt_cmd)) {
        return ("apt");
    } elsif (!system ($yume_cmd)) {
        return ("yum");
    } else {
        return undef;
    }
}

################################################################################
# Mirror the repo for which we have the URL. For that we first determine that  #
# kind of repo it is (e.g. apt repo versus yum repo) and than, we mirror it.   #
#                                                                              #
# Input: url, the repository URL we have to mirror.                            #
#        distro, the distribution ID (following the OS_Detect syntax) the      #
#                mirror is designed for.                                       #
#        destination, mirror path.                                             #
# Return: None.                                                                #
################################################################################
sub mirror_repo ($$$) {
    my ($url, $distro, $destination) = @_;
    my $repo_type = get_repo_type ($url);

    die "ERROR: Impossible to determine the repository type of $url ".
        "($repo_type)\n" if (!defined $repo_type);

    if ($repo_type eq "apt") {
        print "We need to put here the code to mirror an APT repo\n";
    } elsif ($repo_type eq "yum") {
        print "We need to put here the code to mirror a YUM repo\n";
    } else {
        carp "WARNING: we do not know how to mirror $repo_type repos\n";
    }
}

################################################################################
# Setup the default distro repository for a given Linux distribution. Note     #
# that this default repository is specified in the config file for supported   #
# distros.                              l                                      #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64).                                 #
# Return: None.                                                                #
################################################################################
sub use_default_distro_repo ($) {
    my ($distro) = @_;
    my $distro_repo_url = get_default_distro_repo ($distro);
    use_distro_repo ($distro, $distro_repo_url);
}

################################################################################
# Setup the default OSCAR repository for a given Linux distribution. Note that #
# this default repository is specified in the config file for supported        #
# distros.                                                                     #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64).                                 #
# Return: None.                                                                #
################################################################################
sub use_default_oscar_repo ($) {
    my ($distro) = @_;
    my $oscar_repo_url = get_default_oscar_repo ($distro);
    my $compat_distro = get_compat_distro ($distro);
    use_oscar_repo ($distro, $oscar_repo_url);
}

################################################################################
# Decompose a distro ID (OS_Detect syntax) into distro, version, arch.         #
#                                                                              #
# Input: distro_id, the Linux distribution ID we want to deal with (OS_Detect  #
#                   syntax, e.g., rhel-5-x86_64).                              #
# Return: the distro id (e.g., rhel), the distro version, and the arch.        #
################################################################################
sub decompose_distro_id ($) {
    my $distro_id= shift;
    my $arches = "i386|x86_64|ia64|ppc64";
    my ($distro,$version,$arch);
    if ( ($distro_id =~ /(.*)\-(\d+)\-($arches)(|\.url)$/) ||
        ($distro_id =~ /(.*)\-(\d+.\d+)\-($arches)(|\.url)$/) ) {
        $distro = $1;
        $version = $2;
        $arch = $3;
    } 

    return ($distro, $version, $arch);
}

################################################################################
# Gives the compatible distro based on a distro ID (OS_Detect syntax).         #
#                                                                              #
# Input: the distro ID we need to analyze (e.g., centos-5-x86_64).             #
# Return: the compat distro ID (e.g., rhel-5-x86_64).                          #
################################################################################
sub get_compat_distro ($) {
    my $distro_id = shift;
    my ($distro, $ver, $arch) = decompose_distro_id ($distro_id);
    my $os = OSCAR::OCA::OS_Detect::open (fake=>{ distro=>$distro, distro_version=>$ver, arch=>$arch});
    return (os_cdistro_string ($os));
}

################################################################################
# Gives the compatible distro based on a distro ID (OS_Detect syntax).         #
#                                                                              #
# Input: the distro ID we need to analyze (e.g., centos-5-x86_64).             #
# Return: the compat distro ID (e.g., rhel-5-x86_64).                          #
################################################################################
sub get_common_pool_id ($) {
    my $distro_id = shift;
    my ($distro, $ver, $arch) = decompose_distro_id ($distro_id);
    my $os = OSCAR::OCA::OS_Detect::open (fake=>{ distro=>$distro, distro_version=>$ver, arch=>$arch});
    return ("/tftpboot/oscar/common-$os->{pkg}s");
}

################################################################################
# Specify a new distro repository for a given Linux distribution.              #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64.                                  #
# Return: None.                                                                #
################################################################################
sub use_distro_repo ($$) {
    my ($distro, $repo) = @_;

    if (!is_a_valid_string ($distro) || !is_a_valid_string ($repo)) {
        die "ERROR: the distro or the repo URL are invalid ($distro, $repo)\n";
    }

    my $cmd = "mkdir -p " . $tftpdir . "distro/";
    die "ERROR: impossible to execute \"$cmd\"\n" if (system ($cmd));

    OSCAR::PackagePath::repos_add_urlfile ("/tftpboot/distro/".$distro.".url",
                                           $repo);
#     my $file_path = $tftpdir . "distro/" . $distro . ".url";
#     add_line_to_file_without_duplication ($repo, $file_path);
}

################################################################################
# Specify a new OSCAR repository for a given Linux distribution.               #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64.                                  #
# Return: None.                                                                #
################################################################################
sub use_oscar_repo ($$) {
    my ($distro, $repo) = @_;

    if (!is_a_valid_string ($distro) || !is_a_valid_string ($repo)) {
        die "ERROR: the distro or the repo URL are invalid ($distro, $repo)\n";
    }

    my @pools;
    my $compat = get_compat_distro ($distro);
    push (@pools, "/tftpboot/oscar/$compat");
    push (@pools, get_common_pool_id ($distro));
    OSCAR::PackagePath::repos_add_urlfile ("/tftpboot/oscar/".$compat.".url",
                                           @pools);
}

################################################################################
# Chech a specific repository (is it a valid repository or not). Currently we  #
# only check if the repository exists.                                         #
#                                                                              #
# Input: repository path (string).                                             #
# Return: 1 if the repository exists, 0 else.                                  #
################################################################################
sub check_repo_configuration ($) {
    my $path = shift;

    if (-f $path && !repo_empty ($path)) {
        return 1;
    } else {
        # is there a .url file?
        $path = $path . ".url";
        if (-f $path) {
            return 1;
        }
    }
    return 0;
}

################################################################################
# Check if the distro repository exists for a given Linux distribution.        #
#                                                                              #
# Input: distribution ID, following the OS_Detect syntax (e.g. rhel-5-x86_64). #
# Return: 1 if the repository exists, 0 else.                                  #
################################################################################
sub distro_repo_exists ($) {
    my $d = shift;
    my $path = $tftpdir . "distro/" . $d;
    return check_repo_configuration ($path);
}

################################################################################
# Check if the OSCAR repository exists for a given Linux distribution.         #
#                                                                              #
# Input: distribution ID, following the OS_Detect syntax (e.g. rhel-5-x86_64). #
# Return: 1 if the repository exists, 0 else.                                  #
################################################################################
sub oscar_repo_exists {
    my $d = shift;
    my $path = $tftpdir . "oscar/" . $d;
    return check_repo_configuration ($path);
}

################################################################################
# Gives the list of distros for which a repository is setup (both repositories #
# for the distro itself and repositories for OSCAR). For that we check what is #
# in /tftpboot.                                                                #
#                                                                              #
# Input: none.                                                                 #
# Return: an array witht the list of setup distros (e.g. debian-4-x86_64).     #
################################################################################
sub get_list_setup_distros {
    my @setup_distros = ();

    # We get the list of supported distros
    require OSCAR::Distro;
    my @supported_distros = OSCAR::Distro::get_list_of_supported_distros ();

    foreach my $d (@supported_distros) {
        if (distro_repo_exists($d) || oscar_repo_exists ($d)) {
            push (@setup_distros, $d);
        }
    }

    return (@setup_distros);
}

################################################################################
# Return the default repository for a given distribution.                      #
#                                                                              #
# Input: the distro ID (with the OS_Detect syntax).                            #
# Return: the default distro repository (string), empty string if no default   #
#         repo is defined.                                                     #
################################################################################
sub get_default_distro_repo ($) {
    my $distro = shift;

    my $d = OSCAR::Distro::find_distro ($distro);

    my $t = $d->{'default_distro_repo'};
    # if we do not have a default repo, we return an empty string
    if (ref($t) eq "HASH") {
        return "";
    } else {
        return $t;
    }
}

################################################################################
# Return the default OSCAR repository for a given distribution.                #
#                                                                              #
# Input: the distro ID (with the OS_Detect syntax).                            #
# Return: the default OSCAR repository (string), empty string if no default    #
#         repo is defined.                                                     #
################################################################################
sub get_default_oscar_repo ($) {
    my $distro = shift;

    my $d = OSCAR::Distro::find_distro ($distro);

    my $t = $d->{'default_oscar_repo'};
    # if we do not have a default repo, we return an empty string
    if (ref($t) eq "HASH") {
        return "";
    } else {
        return $t;
    }
}

1;

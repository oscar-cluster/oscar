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
use OSCAR::Logger;
use OSCAR::Utils;
use OSCAR::FileUtils;
use File::Basename;
use File::Path;
use Carp;

@EXPORT = qw(
            distro_repo_url
            oscar_repo_url
            repo_empty
            repo_local
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
            generate_default_urlfiles
            get_common_pool_id
            get_compat_distro
            get_default_distro_repo
            get_default_oscar_repo
            get_distro
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

my $verbose = $ENV{OSCAR_VERBOSE};

# The possible places where packages may live.  
@PKG_SOURCE_LOCATIONS = ("/usr/lib/oscar/packages");
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
    die "ERROR: Unable to determine operating system for $img" if (!$os);
    return $os;
}


#
# Return an array of repositories present in the URL file passed as argument.
# Empty local repos are ignored.
#
sub repos_list_urlfile ($) {
    my ($path) = @_;

    my @repos;
    if (-f "$path") {
	local *IN;
	if (open IN, "$path") {
	    while (my $line = <IN>) {
		chomp $line;
		next if ($line !~ /^(http|ftp|file|mirror)/);
		next if (($line =~ /^\s*$/) || ($line =~ /^\s*\#/));
		if (repo_local($line) == 1 && repo_empty ($line) == 1) {
                    OSCAR::Logger::oscar_log_subsection "Skipping empty repo ".
                        $line;
                    next;
                }
                if (repo_local ($line) == 0) {
                    OSCAR::Logger::oscar_log_subsection "Select online repo ".
                        $line;
                    push (@repos, $line);
                }
                if (repo_local ($line) == 1 && repo_empty ($line) == 0) {
                    OSCAR::Logger::oscar_log_subsection "Select valid local ".
                        "repo $line";
		    push (@repos, $line);
                }
	    }
	    close IN;
	}
    }
    return @repos;
}

#
# Add repositories to a .url file. Create file if it doesn't exist.
# Input: $path: full path to url file
#        @repos: array of repos
#
# Return: 0 if success, -1 else.
#
sub repos_add_urlfile ($@) {
    my ($path, @repos) = (@_);
    
    if ($ENV{OSCAR_VERBOSE}) {
        print "Adding the repositories: ";
        OSCAR::Utils::print_array (@repos);
    }

    # make sure local paths have "file:" prefix
    my @repos_to_add;
    for my $repo (@repos) {
        $repo =~ s,^/,file:/,;
        if ($repo  !~ m,^(oscar:file|oscar:http|oscar:ftp|oscar:https|oscar:mirror
                 |distro:file|distro:http|distro:ftp|distro:https|distro:mirror|
                 |file|http|ftp|https|mirror):,) {
            carp "ERROR: Repository must either be a URL or an absolute path\n";
            return -1;
        }
        if (repo_local($repo) == 0) {
            OSCAR::Logger::oscar_log_subsection "Adding online repo ($repo)";
            push (@repos_to_add, $repo);
        }
        if (repo_local($repo) == 1) {
            if (repo_empty ($repo) == 0) {
                OSCAR::Logger::oscar_log_subsection "Adding valid local repo ($repo)";
                push (@repos_to_add, $repo);
            } else {
                OSCAR::Logger::oscar_log_subsection "Skipping empty local repo ($repo)";
                next;
            }
        }
    }

    if (scalar (@repos_to_add) == 0) {
        OSCAR::Logger::oscar_log_subsection "[INFO] No repository to be added";
    }

    foreach my $repo (@repos_to_add) {
        OSCAR::Logger::oscar_log_subsection ("Adding $repo in $path");
        # Fixme: should check return code of function below
        OSCAR::FileUtils::add_line_to_file_without_duplication ("$repo\n", $path);
    }
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
# given the url_type (distro: or oscar:)
#
# Return: the file path, undef if error.
sub get_urlfile ($%) {
    my $url_type = shift;
    my $os = &query_os(@_);
    if (!defined($os) || ref($os) ne "HASH") {
        carp "ERROR: impossible to query the OS\n";
        return undef;
    }
    my $distro;
    if( "$url_type" eq "distro" ) {
        $distro    = $os->{distro};
    } else {
        $distro   = $os->{compat_distro};
    }
    my $distrover = $os->{distro_version};
    my $arch      = $os->{arch};
    return "/tftpboot/$url_type/$distro-$distrover-$arch.url";
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
# Return: comma separated string of repos added to url file.
#         undef if error.
sub distro_repo_url (%) {
    my %arg = @_;

    my $url = &distro_urlfile(%arg);
    my $os = &query_os(%arg);
    if (!OSCAR::Utils::is_a_valid_string($url)) {
        carp "ERROR: impossible to get a URL from OSCAR repo config file\n";
        return undef;
    }
    my $path = dirname($url)."/".basename($url, ".url");

    # create .url file and add local path as first entry
    if (repos_add_urlfile("$url", "file:$path")) {
        carp "ERROR: Impossible to add $path to $url";
        return undef;
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
        warn "Distro repository $path not found. Creating empty directory.";
        File::Path::mkpath ($path, 1, 0777) or
            (carp "ERROR: Could not create directory $path!", return undef);
    }
    if (! -d $comm && ! -l $comm) {
        warn "Commons repository $comm not found. Creating empty directory.\n";
        File::Path::mkpath ($comm, 1, 0777) or
            (carp "ERROR: Could not create directory $comm!", return undef);
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
    $path =~ s,^file:/,/,;
    if (! -d $path) {
        OSCAR::Logger::oscar_log_subsection "[WARN] $path does not exist";
        return 1;
    }
    my $entries = 0;
    opendir (DIR, $path)
        or (carp "ERROR: Could not read directory $path!", return 0);
    for my $d (readdir (DIR)) {
        next if ($d eq "." || $d eq "..");
        $entries++;
    }
    closedir (DIR);
    if ($entries > 0) {
        return 0;
    } else {
        return 1;
    }
}

################################################################################
# Check if a given repository is local or not.                                 #
#                                                                              #
# Input: URI of the repo to analyse.                                           #
# Return: 1 (true) if the repository is local, 0 else.                         #
################################################################################
sub repo_local ($) {
    my $repo = shift;
    $repo =~ s,^/,file:/,;
    if ($repo =~ /^(file):/) {
        return 1;
    } else {
        return 0;
    }
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
    closedir (DIR);
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

# Return: undef if error, distro_id (OS_Detect syntax) else.
sub os_distro_string ($) {
    my ($os) = @_;
    if (!defined ($os)) {
        carp "ERROR: undefined distro";
        return undef;
    }
    return $os->{distro}."-".$os->{distro_version}.
	"-".$os->{arch};
}

# Return: undef if error, distro_id (OS_Detect syntax) else.
sub os_cdistro_string {
    my ($os) = @_;
    if (!defined ($os)) {
        carp "ERROR: undefined distro";
        return undef;
    }
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
# Deprecated by OSCAR::PackageSmart::detect_pool_format();                     #
################################################################################
sub get_repo_type ($) {
    my $repo_url = shift;

    # We determine the type of the repository. Note that we do not care
    # about the output, we only care about the return code.
    my $rapt_cmd = 
        "/usr/bin/rapt --repo $repo_url update 2>/dev/null 1>/dev/null";
    my $yume_cmd = "wget -nd --delete-after $repo_url/repodata/filelists.xml.gz";
    if (!system($yume_cmd)) {
        return ("yum");
    } elsif (!system ($rapt_cmd)) {
        return ("apt");
    } else {
        return undef;
    }
}

sub mirror_yum_repo ($$$) {
    my ($distro, $url, $dest) = @_;

    OSCAR::Logger::oscar_log_subsection "Getting repo meta-data...";

    my $metafile = "primary.xml";
    my $path = "$dest/$distro";
    # We get the metadata file
    mkpath("$path/tmp") or (carp "ERROR: Impossible to create $dest/tmp", 
                            return -1);
    my $cmd = "cd $path/tmp; wget $url/repodata/$metafile.gz";
    if (system ($cmd)) {
        carp "ERROR: Impossible to execute $cmd";
        return -1;
    }

    # We uncompress the file
    $cmd = "cd $path/tmp; gunzip $metafile.gz";
    if (system ($cmd)) {
        carp "ERROR: Impossible to execute $cmd";
        return -1;
    }

    # We get the name of all packages
    my @locations = `cat $path/tmp/$metafile | grep \"<location\" | awk \' {print \$2 } \'`;
    foreach my $entry (@locations) {
        if ($entry =~ /^href=\"(.*)\"(.*)$/) {
            $entry = $1;
        }
    }

    OSCAR::Logger::oscar_log_subsection "Download packages...";
    OSCAR::Utils::print_array (@locations);

    # Now we can download the packages!
    for (my $i=0; $i < scalar (@locations); $i++) {
        my $cmd = "cd $path; wget $url/$locations[$i]";
        print "Executing $cmd\n";
        if (system ($cmd)) {
            carp "ERROR: Impossible to execute $cmd";
            return -1;
        }
    }

    # We do some cleanup.
    OSCAR::Logger::oscar_log_subsection "Cleaning up...";
    unlink ("$path/tmp/$metafile");
    unlink ("$path/tmp/$metafile.gz");

    # Now we generate the metadata of the new repo
    OSCAR::Logger::oscar_log_subsection "Generating the mirror meta-data...";
    my $pm = OSCAR::PackageSmart::prepare_pool ($ENV{OSCAR_VERBOSE},
                                                $path);
    if (!defined $pm) {
        carp "ERROR: impossible to generate the metadata of the mirror";
        return -1;
    }

    OSCAR::Logger::oscar_log_subsection "Successfully mirror the repo $url";

    return 0;
}

sub parse_aptrepo_metadata ($) {
    my $file = shift;
    my @pkgs;
    my $line;
    
    if (! -f $file) {
        carp "ERROR: Impossible to read $file";
        return undef;
    }

    open (FILE, "$file") or (carp "ERROR: Impossible to open $file",
                             return undef);
    while ($line = <FILE>) {
        if ($line =~ /^Filename: (.*)$/) {
            my $pkg_name = $1;
            chomp ($pkg_name);
            push (@pkgs, $pkg_name);
        }
    }
    close (FILE);

    return @pkgs;
}

# Return: 0 if success, -1 else.
sub mirror_apt_repo ($$$) {
    my ($distro_id, $url, $dest) = @_;

    OSCAR::Logger::oscar_log_subsection "Getting repo meta-data for $distro_id...";
    # The repo follows the RAPT notation, from it, we create the actual URL to
    # access meta-data
    my ($base_url, @keys) = split (/\+/, $url);
    my ($distro, $ver, $arch) = decompose_distro_id ($distro_id);
    my $os = OSCAR::OCA::OS_Detect::open (fake=>{ distro=>$distro, 
                                                  distro_version=>$ver,
                                                  arch=>$arch});
    if (!defined $os) {
        carp "ERROR: Impossible to get OS data";
        return -1;
    }

    # OS_Detect should give the codename
    OSCAR::Utils::print_hash ("", "", $os);
    my $codename = $os->{'codename'};
    my $metadata_url = "$base_url/dists/$codename/binary-$arch/Packages";
    # We check that the destination directory exists
    my $dest_dir = "$dest/$distro_id";
    if (! -d "$dest_dir") {
        mkdir ($dest_dir) or (carp "ERROR: Impossible to create $dest_dir",
                             return -1);
    }
    my $cmd = "cd $dest_dir; /usr/bin/wget $metadata_url";
    oscar_log_subsection ("Executing: $cmd");
    if (system ($cmd)) {
        carp "ERROR: Impossible to execute $cmd";
        return -1;
    }

    my @files = parse_aptrepo_metadata ("$dest_dir/Packages");
    foreach my $file (@files) {
        $cmd = "cd $dest_dir; /usr/bin/wget $base_url/$file";
        oscar_log_subsection ("Executing $cmd");
        if (system $cmd) {
            carp "ERROR: Impossible to download $base_url/$file";
            return -1;
        }
    }

    oscar_log_subsection "Cleaning up...";
    my $rm_file = "$dest_dir/Packages";
    unlink ("$rm_file") or (carp "ERROR: Impossible to delete $rm_file",
                            return -1);

    oscar_log_subsection "Generating the mirror meta-data...";
    my $pm = OSCAR::PackageSmart::prepare_pool ($ENV{OSCAR_VERBOSE},
                                                $dest_dir);
    if (!defined $pm) {
        carp "ERROR: impossible to generate the metadata of the mirror";
        return -1;
    }
    return 0;
}

################################################################################
# Mirror the repo for which we have the URL. For that we first determine that  #
# kind of repo it is (e.g. apt repo versus yum repo) and than, we mirror it.   #
#                                                                              #
# Input: url, the repository URL we have to mirror.                            #
#        distro, the distribution ID (following the OS_Detect syntax) the      #
#                mirror is designed for.                                       #
#        destination, mirror path.                                             #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub mirror_repo ($$$) {
    my ($url, $distro, $destination) = @_;

    require OSCAR::PackageSmart;
    my $repo_type = OSCAR::PackageSmart::detect_pool_format ($url);

    die "ERROR: Impossible to determine the repository type of $url ".
        "($repo_type)\n" if (!defined $repo_type);

    print "Mirroring repo of type: $repo_type\n";
    if ($repo_type eq "deb") {
        if (mirror_apt_repo ($distro, $url, $destination)) {
            carp "ERROR: We cannot mirror the APT repos ($distro, $url, ".
                 "$destination)";
            return -1;
        }
    } elsif ($repo_type eq "yum") {
        if (mirror_yum_repo ($distro, $url, $destination)) {
            carp "ERROR: Impossible to mirror the repository ($url, ".
                 "$destination";
            return -1;
        }
    } else {
        carp "WARNING: we do not know how to mirror $repo_type repos\n";
        return -1;
    }

    return 0;
}

################################################################################
# Setup the default distro repository for a given Linux distribution. Note     #
# that this default repository is specified in the config file for supported   #
# distros.                              l                                      #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64).                                 #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub use_default_distro_repo ($) {
    my ($distro) = @_;
    my @distro_repo_urls = ();
    @distro_repo_urls = get_default_distro_repo ($distro);
    if (!OSCAR::Utils::is_a_valid_string ($distro)) {
        carp "ERROR: undefined default distro repo for ($distro)";
        return -1;
    }
    if (@distro_repo_urls and $#distro_repo_urls >= 0 and defined $distro_repo_urls[0]) {
        OSCAR::Logger::oscar_log_subsection ("Using the following distro repo $distro for:\n");
        OSCAR::Utils::print_array (@distro_repo_urls);

        if (use_distro_repo ($distro, @distro_repo_urls)) {
            carp "ERROR: Impossible to set the distro repo\n";
            return -1;
        }
        return 0;
    } else {
        carp "ERROR: undefined default distro repo for ($distro)";
        return -1;
    }
}

################################################################################
# Setup the default OSCAR repository for a given Linux distribution. Note that #
# this default repository is specified in the config file for supported        #
# distros.                                                                     #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64).                                 #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub use_default_oscar_repo ($) {
    my ($distro) = @_;
    my @distro_oscar_urls = ();
    @distro_oscar_urls = get_default_oscar_repo ($distro);

    if (!OSCAR::Utils::is_a_valid_string ($distro)) {
        carp "ERROR: undefined oscar distro repo for ($distro)";
        return -1;
    }
    if (@distro_oscar_urls and $#distro_oscar_urls >= 0 and defined $distro_oscar_urls[0]) {
        OSCAR::Logger::oscar_log_subsection ("Using the following oscar repo $distro for:\n");
        OSCAR::Utils::print_array (@distro_oscar_urls);

        if (use_oscar_repo ($distro, @distro_oscar_urls)) {
            carp "ERROR: Impossible to set the OSCAR repos\n";
            return -1;
        }
        return 0;
    } else {
        carp "ERROR: undefined oscar distro repo for ($distro)";
        return -1;
    }
}

################################################################################
# Decompose a distro ID (OS_Detect syntax) into distro, version, arch.         #
#                                                                              #
# Input: distro_id, the Linux distribution ID we want to deal with (OS_Detect  #
#                   syntax, e.g., rhel-5-x86_64).                              #
# Return: the distro id (e.g., rhel), the distro version, and the arch.        #
################################################################################
sub decompose_distro_id ($) {
    my $distro_id = shift;
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

sub get_distro () {
    my $os = OSCAR::OCA::OS_Detect::open ();
    if (!defined $os || ref ($os) ne "HASH") {
        carp "ERROR: Impossible to detect the local distro";
        return undef;
    }
    return (os_distro_string ($os));
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
#        @repos, the array containing the repos to add.
# Return: -1 if error, 0 else.                                                 #
################################################################################
sub use_distro_repo ($$) {
    my ($distro, @repos) = @_;

    if (!OSCAR::Utils::is_a_valid_string ($distro)) {
        carp "ERROR: the distro is invalid ($distro)";
        return -1;
    }

    # FIXME: need to loop on @repos testing they are valid strings.

    my $path = $tftpdir . "distro";
    if (! -d $path) {
        OSCAR::Logger::oscar_log_subsection "Creating $path";
        File::Path::mkpath ($path, 1, 0777) 
            or (carp "ERROR: impossible to create the directory $path", 
                return -1);
    }

    OSCAR::Logger::oscar_log_subsection "Adding the following repos in $path/$distro.url";
    OSCAR::Utils::print_array (@repos);
    if (OSCAR::PackagePath::repos_add_urlfile ("$path/$distro.url", @repos)) {
        carp "ERROR: Impossible to create file $path.url";
        return -1;
    }
    return 0;
}

################################################################################
# Specify a new OSCAR repository for a given Linux distribution.               #
#                                                                              #
# Input: distro, the Linux distribution ID we want to deal with (OS_Detect     #
#                syntax, e.g., rhel-5-x86_64.                                  #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub use_oscar_repo ($$) {
    my ($distro, @repos) = @_;

    if (!OSCAR::Utils::is_a_valid_string ($distro)) {
        # FIXME: need to loop on @repos testing they are valid strings.
        carp "ERROR: the distro or the repo URL are invalid ($distro)";
        return -1;
    }

    my $compat = get_compat_distro ($distro);
    my $path = "/tftpboot/oscar/$compat";
    my $repo_file = "/tftpboot/oscar/".$compat.".url";
    push (@repos, $path) if (repo_empty ($path) == 0);
    $path = get_common_pool_id ($distro);
    push (@repos, $path) if (repo_empty ($path) == 0);
    if (scalar (@repos)) {
        if (repos_add_urlfile ($repo_file, @repos)) {
            carp "ERROR: Impossible to add repos in $repo_file";
            return -1;
        }
    }
    return 0;
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

    if (-f $path && (repo_empty ($path) == 0)) {
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
# Return: the default distro repository (array), empty array if no default     #
#         repo is defined, undef if error.                                     #
################################################################################
sub get_default_distro_repo ($) {
    my $distro = shift;

    if (!defined ($distro)) {
        carp "ERROR: Undefined distro";
        return undef;
    }
    require OSCAR::Distro;
    my %d = OSCAR::Distro::find_distro ($distro);
    # Returns empty hash if not supported distro

    my $t = $d{'default_distro_repos'};
    if(! defined $t) {
        return undef;
    } else {
        return @$t;
    }
}

################################################################################
# Return the default OSCAR repository for a given distribution.                #
#                                                                              #
# Input: the distro ID (with the OS_Detect syntax).                            #
# Return: the default OSCAR repository (array), empty array if no default      #
#         repo is defined, undef if error.                                     #
################################################################################
sub get_default_oscar_repo ($) {
    my $distro = shift;

    if (!defined ($distro)) {
        carp "ERROR: Undefined distro";
        return undef;
    }
    require OSCAR::Distro;
    my %d = OSCAR::Distro::find_distro ($distro);
    # Returns empty hash if not supported distro

    my $t = $d{'default_oscar_repos'};
    if(! defined $t) {
        return undef;
    } else {
        return @$t;
    }
}

################################################################################
# Generate the default distro configuration file in /tftpboot for a given      #
# Linux distribution.                                                          #
#                                                                              #
# Input: distro, distro ID (OS_Detect syntax) for which we want to generate    #
#                configuration files.                                          #
# Return: -1 if error, 0 if success, 1 if the file already exists.
################################################################################
sub generate_default_oscar_urlfile ($) {
    my $distro = shift;

    if (!defined ($distro)) {
        carp "ERROR: Undefined distro, impossible to create the default OSCAR ".
             "URL file.";
        return -1;
    }

    # TODO: we should validate the distro ID.
    my $compat_distro = get_compat_distro ($distro);
    OSCAR::Logger::oscar_log_subsection "[INFO] Generating oscar url file $$compat_distro";
    if (!defined ($compat_distro)) {
        carp "ERROR: Impossible to get the compat distro for $distro";
        return -1;
    }
    my $file = "/tftpboot/oscar/$compat_distro.url";
    if (-f $file) {
        warn "INFO: the $file already exists, we do nothing";
        return 1;
    }

    my $repo = get_default_oscar_repo ($distro);
    if (!defined ($repo)) {
        carp "ERROR: Impossible to get the default repository for $distro";
        return -1;
    }
    if ($repo eq "") {
        warn "No default distro repository for $distro";
        return 0;
    }
    if (OSCAR::FileUtils::add_line_to_file_without_duplication ("$repo\n",
                                                                $file)) {
        carp "ERROR: Impossible to add $repo in $file";
        return -1;
    }

    return 0;
}

################################################################################
# Generate the default distro configuration file in /tftpboot for a given      #
# Linux distribution.                                                          #
#                                                                              #
# Input: distro, distro ID (OS_Detect syntax) for which we want to generate    #
#                configuration files.                                          #
# Return: -1 if error, 0 if success, 1 if the file already exists.
################################################################################
sub generate_default_distro_urlfile ($) {
    my $distro = shift;

    if (!defined ($distro)) {
        carp "ERROR: Undefined distro, impossible to create the default ".
             "distro URL file /tftpboot/distro/<distroid>.url.";
        return -1;
    }

    # TODO: we should validate the distro ID.
    my $file = "/tftpboot/distro/$distro.url";
    OSCAR::Logger::oscar_log_subsection "[INFO] Generating distro url file $file";
    if (-f $file) {
        warn "INFO: the $file file already exists, we do nothing";
        return 1;
    }

    my $repo = get_default_distro_repo ($distro);
    if (!defined ($repo)) {
        carp "ERROR: Impossible to get the default repository for $distro";
        return -1;
    }
    if ($repo eq "") {
        warn "No default distro repository for $distro";
        return 0;
    }
    if (OSCAR::FileUtils::add_line_to_file_without_duplication ("$repo\n",
                                                                $file)) {
        carp "ERROR: Impossible to add $repo in $file";
        return -1;
    }

    return 0;
}

################################################################################
# Generate the default configuration files in /tftpboot. For that, we use      #
# information available about supported distros (e.g.,                         #
# /etc/oscar/supported_distros.txt). This allows users to be able to use OSCAR #
# with the default values out-of-the-box.                                      #
#                                                                              #
# Input: distro, distro ID (OS_Detect syntax) for which we want to generate    #
#                configuration files.                                          #
# Return: -1 if error, 0 else.                                                 #
################################################################################
sub generate_default_urlfiles ($) {
    my $distro = shift;

    if (!defined ($distro)) {
        carp "ERROR: Undefined distro";
        return -1;
    }
    if (generate_default_oscar_urlfile ($distro) == -1) {
        carp "ERROR: Impossible to generate the default OSCAR url file ".
             "($distro)";
        return -1;
    }

    if (generate_default_distro_urlfile ($distro) == -1) {
        carp "ERROR: Impossible to generate the default distro url file ".
             "($distro)";
        return -1;
    }
}

1;

__END__

=head1 Exported Functions

=over 4

=item distro_repo_url

=item oscar_repo_url

=item repo_empty

=item repo_local

=item oscar_urlfile

=item distro_urlfile

=item repos_list_urlfile

=item repos_add_urlfile

=item repos_del_urlfile

=item os_distro_string

=item os_cdistro_string

=item pkg_extension

=item pkg_separator

=item distro_detect_or_die

=item list_distro_pools

=item decompose_distro_id

=item generate_default_urlfiles

=item get_common_pool_id

=item get_default_distro_repo

=item get_default_oscar_repo

Get the default OSCAR repository for a given distro.
my $repo = OSCAR::PackagePath::get_default_oscar_repo ($oscar_repo_to_mirror);

=item get_repo_type

=item get_list_setup_distros

=item mirror_repo

Mirror an OSCAR repository. For instance:
mirror_repo ("http://bear.csm.ornl.gov/repos/rhel-5-i386", "rhel-5-i386", "/tmp/test_repo");

=item use_distro_repo

=item use_oscar_repo

=item use_default_distro_repo

=item use_default_oscar_repo

=back

=cut

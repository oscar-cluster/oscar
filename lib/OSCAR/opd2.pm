package OSCAR::opd2;

# Copyright (C) 2007    Oak Ridge National Laboratory
#                       Geoffroy Vallee <valleegr@ornl.gov>
#                       All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  US

use strict;
use XML::Simple;
use Data::Dumper;
use OSCAR::Utils qw (print_array);
use Carp;

use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw (
            add_repo_to_cache
            flush_cache
            get_available_repositories
            get_available_opkgs
            get_default_repositories
            get_included_opkgs
            init_cache
            init_opd
            list_available_opkgs
            list_available_repositories
            list_included_opkgs
             );

my $cachedir = "/var/cache/oscar/";
my $opkg_repo_cache = $cachedir . "opd_repos.txt";
my $opkg_list_cache = $cachedir . "opkgs.txt";
our @opkg_list;

my $opd2_lockfile = "/tmp/opd2.pid";

# List of OSCAR repositories used by default, using the yume or rapt syntax
my @default_oscar_repos = ("http://oscar.gforge.inria.fr/debian/+stable+oscar");

my $verbose = $ENV{OPD_VERBOSE};
our $xml_data;
#our $url;

#####################
# PRIVATE FUNCTIONS #
#####################

# This function creates an empty file.
# @param: the file path
# @return: 0 if success, -1 else
sub init_xml_file {
    my ($file) = @_;

    open (FILE, ">$file") or die "can't open $file $!";
    print FILE "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
    print FILE "<opt/>";
    close (FILE);

    return 0;
}

sub init_text_file {
    my ($file) = @_;

    open (FILE, ">$file") or die "can't open $file $!";
    close (FILE);

    return 0;
}

# This function initialize the cache used by OPD2
sub init_cachedir {
    # We first check that the cachedir is ready to be used
    if (! -d $cachedir) {
        print "The cache directory is not ready, ".
            "please wait for its initialization...\n"
            if $verbose > 0;
        mkdir ($cachedir, 0644);
        print "Cache directory created.\n" if $verbose > 0;
    }
}

# This function initialized the files used for caching.
# @return: 0 if success, -1 else
sub init_cachefiles {
    print "Cache initialization...\n" if $verbose > 0;
    if (! -f $opkg_list_cache) {
        if (init_text_file ($opkg_list_cache)) {
            carp ("Impossible to initialize cache ($opkg_list_cache)");
        }
    }
    if (! -f $opkg_repo_cache) {
        if (init_text_file ($opkg_repo_cache)) {
            carp ("Impossible to initialize cache ($opkg_repo_cache)");
        }
    }
    print "Initialization done.\n" if $verbose > 0;
    return 0;
}

# Create the OPD2 lock
# @return: 0 if success
sub opd2_lock {
    print "Locking OPD2\n" if $verbose > 0;
    if (-f $opd2_lockfile) {
        carp ("The OPD2 lock already exists ($opd2_lockfile), " .
            "check if another instance is running") if $verbose;
        return -1;
    }
    open (FILE, ">$opd2_lockfile") or die "can't open $opd2_lockfile";
    print FILE $$;
    close (FILE);
    print "OPD2 locked\n" if $verbose > 0;
    return 0;
}

# Remove the OPD2 lock
sub opd2_unlock {
    print "Unlocking OPD2\n" if $verbose > 0;
    if (! -f $opd2_lockfile) {
        print "Warning the lock does not exist, is it not normal." .
              "Continuing anyway.\n";
    } else {
        unlink ("$opd2_lockfile");
    }
}

# Check if a given OPKG is cached or not
sub find_opkg_in_cache {
    my $pkg_name = shift;
    print "Searching OPKG $pkg_name in cache...\n" if $verbose > 0;
    open (FILE, $opkg_list_cache)
        or die "Impossible to add the list of OPKGs to the cache";
    my $pkg;
    my $pos=0;
    foreach $pkg (<FILE>) {
        chomp($pkg);
        print $pkg if $verbose > 2;
        if ($pkg eq $pkg_name) {
            print "The OPKG ($pkg_name) is already cached\n" if $verbose;
            return $pos;
        }
        $pos += 1;
    }
    close (FILE);
    print "OPKG ($pkg_name) not in cache\n" if $verbose > 0;
    return -1;
}

# Check if a given repository is cached or not
sub find_repo_in_cache ($) {
    my $url = shift;
    print "Searching repo $url in cache...\n" if $verbose > 0;
    open (FILE, $opkg_repo_cache)
        or die "Impossible to add the repo to the cache";
    my $repo;
    my $pos=0;
    foreach $repo (<FILE>) {
        chomp($repo);
        print $repo if $verbose > 2;
        if ($repo eq $url) {
            print "The repo ($repo) is already cached\n" if $verbose;
            return $pos;
        } 
        $pos += 1;
    }
    close (FILE);
    print "Repo ($url) not in cache\n" if $verbose > 0;
    return -1;
}

# Add an entry in the list of available APT repositories
# @param: the repository entry to add (note that it _must_ be valid line
#         for /etc/apt/sources.list
# @return: 0 if success, -1 else.
sub add_apt_repo {
    my $repo_entry = shift;
    print "Updating the list of APT repositories..." if $verbose > 0;
    my $cmd = "/usr/bin/rapt --repo $repo_entry";
    if (!system ($cmd)) {
        carp ("Impossible to add the repository $repo_entry");
        return -1;
    }
    return 0;
}

# Add an entry in the list of available Yum repositories
# @param: the repository entry to add (note that it _must_ be valid line
#         for the yum configuration file.
# @return: 0 if success, -1 else.
sub add_yum_repo {
    my $repo_entry = shift;
    print "Updating the list of YUM repositories..." if $verbose > 0;
    my $cmd = "/usr/bin/yume --repo $repo_entry";
    if (!system ($cmd)) {
        carp ("Impossible to add the repository $repo_entry");
        return -1;
    }
    return 0;
}

# Add an OPKG to the list in cache
# @param: OPKG name
# @return: 0 if success
sub add_opkg_to_cache {
    open (CACHEFILE, ">>$opkg_list_cache")
        or die "Impossible to add the OPKG to the cache";
    my $base = $xml_data->{package};
    print "Nb of packagess: ".scalar(@{$base})."\n" if $verbose > 0;
    for (my $i=0; $i < scalar(@{$base}); $i++) {
        my $name = $xml_data->{package}->[$i]->{name};
        chomp($name);
        if (find_opkg_in_cache($name) == -1) {
            print "Adding $name in cache...\n" if $verbose;
            print CACHEFILE $name;
            print CACHEFILE "\n";
            
            for(my $j=0; $j < $#{$xml_data->{package}->[$i]->{download}->{repo}}; $j++) {
	            my $repo_uri = 
	                $xml_data->{package}->[$i]->{download}->{repo}->[$j]->{uri};
	            my $repo_type = 
	                $xml_data->{package}->[$i]->{download}->{repo}->[$j]->{type};
	            if ($repo_type eq "apt" && -f "/etc/apt/sources.list") {
	                add_apt_repo ($repo_uri);
	            }
	            if ($repo_type eq "yum" && -f "/etc/yum.conf") {
	                add_yum_repo ($repo_uri);
	            }
			}
        }
    }
    close (CACHEFILE);
    return 0;
}


###############################################################################
# Parse a opd_repo.xml file. DEPRACTED.                                       #
# @param: none.                                                               #
# @return: none.                                                              #
###############################################################################
# sub parse_repo_description {
#     my $data_file = "/tmp/opd_repo.xml";
# 
#     print "Parsing repository info...\n";
# 
#     my $simple = XML::Simple->new(KeyAttr => "package, name");
#     $xml_data = $simple->XMLin($data_file) or return -1;
# 
#     print Dumper($xml_data) if $verbose >= 5;
# 
#     add_repo_to_cache ();
#     add_opkg_to_cache ();
# }

# DEPRACTED
# sub download_debian_package_list {
#     my $file = "$cachedir/Packages";
#     # If the file has been downloaded before, we delete it.
#     if (-f "$file") {
#         unlink ("$file");
#     }
#     my $cmd = "cd $cachedir && wget $debian_url";
#     print "Executing: $cmd\n" if $verbose;
#     if (system($cmd)) {
#         die "ERROR: Impossible to get the list of available packages " .
#             "from OSCAR repository $repo_url";
#     }
# }


###############################################################################
# Parse the Package file downloaded from a Debian OSCAR repo in order to get  #
# the list of available OPKGs.                                                #
###############################################################################
sub parse_debian_package_file {
    my @list = ();
    my $file = "$cachedir/Packages";

    if (!-f "$file") {
        download_debian_package_list ();
    }

    open (FILE, "$file") or die "ERROR: Impossible to open $file";
    my @file_content = <FILE>;
    close (FILE);

    foreach my $line (@file_content) {
        if ($line =~ /^Package: opkg-(.*)-server/) {
            push (@list, $1);
        }
    }

    return (@list);
}


sub init_repos {
    foreach my $repo (@default_oscar_repos) {
        print "Adding the default repository $repo...\n" if $verbose;
        add_repo_to_cache ($repo);
    }
}




####################
# PUBLIC FUNCTIONS #
####################


# Add the repository into the cache. Note that this is done only if we can
# parse the opd_repo.xml file before
# @param: none
# @return: 0 if success
sub add_repo_to_cache ($) {
    my $url = shift;
    if (find_repo_in_cache($url) == -1) {
        open (FILE, ">>$opkg_repo_cache") 
            or die "Impossible to add the repo to the cache";
        print FILE $url;
        print FILE "\n";
        close (FILE);
    }
    return 0;
}

###############################################################################
# Initialize the OPD2 cache. Note that if the cache already has been          #
# initialized and if you call again the function, the cache is NOT erased.    #
# Input: None.                                                                #
# Return: None.                                                               #
###############################################################################
sub init_cache {
    init_cachedir ();
    init_cachefiles ();
}

sub init_opd {
    init_cache ();
    init_repos ();
}

# This function scans a specific repository to get the list of available OPKGs
# DEPRECATED
# @param: repository URL
# @return: array of OPKGs, -1 if error
# sub scan_repository {
#     my ($url) = @_;
#     my $cmd;
# 
#     chomp($url);
#     print "Scanning repository $url...\n" if $verbose > 1;
# 
#     if (opd2_lock () != 0) {
#         print "Exiting...\n";
#         return -1;
#     }
# 
#     init_cachedir ();
#     init_cachefiles ();
# 
#     # We first download the repository description
#     if (-f "/tmp/opd_repo.xml") {
#         print "A dowloaded OPD repo description is already there, ".
#               "we delete it...\n";
#         unlink ("/tmp/opd_repo.xml");
#     }
#     $cmd = "cd /tmp; wget " . $url;
#     if (system($cmd)) {
#         carp "Impossible to get OPD repository description (URL: $url)";
#         opd2_unlock ();
#         exit -1;
#     } 
# 
#     if (parse_repo_description () != 0) {
#         opd2_unlock();
#         exit -1;
#     }
# 
#     unlink ("/tmp/opd_repo.xml");
#     opd2_unlock ();
# }

###############################################################################
# List the list of available OPKG (using the cache if not repo is specified,  #
# query the specifies repo else).                                             #
# Input: None.                                                                #
# Return: array with the list of available OPKGs.                             #
###############################################################################
sub get_available_opkgs ($) {
    my $repo_url = shift;
    my @list = ();

    if ($repo_url eq "") {
        # We want the list of all OPKGs available via all the OSCAR repos
        my @repos = get_available_repositories ();
        # We query all the repositories
        foreach my $repo (@repos) {
            my @opkgs = ();
            @opkgs = get_available_opkgs ($repo);
            # We merge the list of OPKGs from the current repo to the global
            # list of OPKGs
            foreach my $opkg (@opkgs) {
                push (@list, $opkg);
            }
        }

#         # We go through the cache and get the list of OPKG
#         open (FILE, $opkg_list_cache)
#             or die "Impossible to open the OPKGs cache";
#         foreach my $pkg (<FILE>) {
#             push (@list, $pkg);
#         }
#         close (FILE);
    } else {

        # TODO: We should have here a Packman interface for repo query!!!!!

        # We determine the type of the repository. Note that we do not care
        # about the output, we only care about the return code.
        my $cmd = "/usr/bin/rapt --repo $repo_url update 2>/dev/null 1>/dev/null";
        if (!system($cmd)) {
            # This is a Debian repository
            $cmd="/usr/bin/rapt --repo $repo_url search 'opkg-.*-server' --names-only ";
        } else {
            $cmd="/usr/bin/yume $repo_url --repoquery --nevra opkg-*-server";
        }
        print "Executing: $cmd\n" if $verbose;
        open CMD, "$cmd |" or die "Error: $!";
        while (<CMD>) {
            my $opkg = $_;
            chomp ($opkg);
            if ($opkg =~ m/^opkg-(.*)-server\s*$/) {
                push (@list, $1);
            }
        }
    }

    return (@list);
}

###############################################################################
# Display the list of available OPKGs.                                        #
# Input: Repo URL, empty string for all the repositories.                     #
# Return: None.                                                               #
###############################################################################
sub list_available_opkgs ($) {
    my $repo_url = shift;
    my @list = get_available_opkgs ($repo_url);
    print_array (@list);
}

###############################################################################
# Get the list of available repositories.                                     #
# Parameter: none.                                                            #
# Return:    array of repositories URL.                                       #
###############################################################################
sub get_available_repositories {
    my @list = ();
    # We go through the cache and display the list of OPKG
    if(open (FILE, $opkg_repo_cache)) {
        foreach my $repo (<FILE>) {
            chomp ($repo);
            push (@list, $repo);
        }
    }
    return @list;
}

###############################################################################
# Print the list of repositories available via OPD2.                          #
# Parameter: None.                                                            #
# Return:    None.                                                            #
###############################################################################
sub list_available_repositories {
    my @list = get_available_repositories();
    print_array (@list);
}

###############################################################################
# Get the list of OPKGs available from the official OSCAR repository (e.g.    #
# via the INRIA forge).                                                       #
# Input: distro, identifier of the Linux distro for which we want the list of #
#                of available OPKGs. This should be the compat_distro id from #
#                OS_Detect.                                                   #
# Return: array with the list of available OPKGs.                             #
###############################################################################
sub get_included_opkgs {
    my $distro = shift;
    my @list = ();

    if ($distro eq "debian") {
        @list = parse_debian_package_file ();
    } else {
        carp ("Sorry, we cannot yet get the list of available OPKGs from the ".
              "official OSCAR repository for the Linux distribution $distro.".
              "\nThis is most certainly because this distribution is not yet ".
              "supported.\n");
    }

    return @list;
}

###############################################################################
# Display the list of available OPKGs from the official OSCAR repository      #
# (e.g. via the INRIA forge).                                                 #
# Input: distro, identifier of the Linux distro for which we want the list of #
#                of available OPKGs. This should be the compat_distro id from #
#                OS_Detect.                                                   #
# Return: None.                                                               #
###############################################################################
sub list_included_opkgs {
    my $distro = shift;
    my @list = get_included_opkgs ($distro);
    print_array (@list);
}

###############################################################################
# Flush the OPD2 cache. All files and directories related to the OPD2 cache   #
# are deleted.                                                                #
###############################################################################
sub flush_cache {
    print "Flushing cache...\n" if $verbose;
    unlink ("$opkg_repo_cache");
    unlink ("$opkg_list_cache");
    print "Cache cleaned\n" if $verbose;
}


sub get_default_repositories {
    return @default_oscar_repos;
}

1;

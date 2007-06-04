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
use Carp;
use XML::Simple;
use Data::Dumper;

use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw (
            scan_repository
            list_available_opkgs
            list_available_repositories
            flush_cache
             );

my $cachedir = "/var/cache/oscar/";
my $opkg_repo_cache = $cachedir . "opd_repos.txt";
my $opkg_list_cache = $cachedir . "opkgs.txt";
our @opkg_list;

my $opd2_lockfile = "/tmp/opd2.pid";

my $verbose = 1;
our $xml_data;
our $url;

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
    print "Initialization done." if $verbose > 0;
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
    return 0;
}

# Create the OPD2 lock
# @return" 0 if success
sub opd2_lock {
    print "Locking OPD2\n" if $verbose > 0;
    if (-f $opd2_lockfile) {
        carp ("The OPD2 lock already exists ($opd2_lockfile), " .
            "check if another instance is running");
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
            print "The OPKG ($pkg_name) is already cached\n";
            return $pos;
        }
        $pos += 1;
    }
    close (FILE);
    print "OPKG ($pkg_name) not in cache\n" if $verbose > 0;
    return -1;
}

# Check if a given repository is cached or not
sub find_repo_in_cache {
    print "Searching repo $url in cache...\n" if $verbose > 0;
    open (FILE, $opkg_repo_cache)
        or die "Impossible to add the repo to the cache";
    my $repo;
    my $pos=0;
    foreach $repo (<FILE>) {
        chomp($repo);
        print $repo if $verbose > 2;
        if ($repo eq $url) {
            print "The repo ($repo) is already cached\n";
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
            print "Adding $name in cache...\n";
            print CACHEFILE $name;
            print CACHEFILE "\n";
            my $repo_uri = 
                $xml_data->{package}->[$i]->{download}->{repo}->{uri};
            my $repo_type = 
                $xml_data->{package}->[$i]->{download}->{repo}->{type};
            if ($repo_type eq "apt" && -f "/etc/apt/sources.list") {
                add_apt_repo ($repo_uri);
            }
            if ($repo_type eq "yum" && -f "/etc/yum.conf") {
                add_yum_repo ($repo_uri);
            }
        }
    }
    close (CACHEFILE);
    return 0;
}

# Add the repository into the cache. Note that this is done only if we can
# parse the opd_repo.xml file before
# @param: none
# @return: 0 if success
sub add_repo_to_cache {
    if (find_repo_in_cache() == -1) {
        open (FILE, ">>$opkg_repo_cache") 
            or die "Impossible to add the repo to the cache";
        print FILE $url;
        print FILE "\n";
        close (FILE);
    }
    return 0;
}

# Parse a opd_repo.xml file
# @param: none
# @return: none
sub parse_repo_description {
    my $data_file = "/tmp/opd_repo.xml";

    print "Parsing repository info...\n";

    my $simple = XML::Simple->new(KeyAttr => "package, name");
    $xml_data = $simple->XMLin($data_file) or return -1;

    print Dumper($xml_data) if $verbose >= 5;

    add_repo_to_cache ();
    add_opkg_to_cache ();
}


####################
# PUBLIC FUNCTIONS #
####################

# This function scans a specific repository to get the list of available OPKGs
# @param: repository URL
# @return: array of OPKGs, -1 if error
sub scan_repository {
    ($url) = @_;
    my $cmd;

    chomp($url);
    print "Scanning repository $url...\n" if $verbose > 1;

    if (opd2_lock () != 0) {
        print "Exiting...\n";
        return -1;
    }

    init_cachedir ();
    init_cachefiles ();

    # We first download the repository description
    if (-f "/tmp/opd_repo.xml") {
        print "A dowloaded OPD repo description is already there, ".
              "we delete it...\n";
        unlink ("/tmp/opd_repo.xml");
    }
    $cmd = "cd /tmp; wget " . $url;
    if (system($cmd)) {
        carp "Impossible to get OPD repository description (URL: $url)";
        opd2_unlock ();
        exit -1;
    } 

    if (parse_repo_description () != 0) {
        opd2_unlock();
        exit -1;
    }

    unlink ("/tmp/opd_repo.xml");
    opd2_unlock ();
}

# List the list of available OPKG (using the cache)
sub list_available_opkgs {
    # We go through the cache and display the list of OPKG
    open (FILE, $opkg_list_cache)
        or die "Impossible to add the list of OPKGs to the cache";
    foreach my $pkg (<FILE>) {
        print $pkg;
    }
    close (FILE);
}

sub list_available_repositories {
    # We go through the cache and display the list of OPKG
    open (FILE, $opkg_repo_cache)
        or die "Impossible to add the list of repos to the cache";
    foreach my $pkg (<FILE>) {
        print $pkg;
    }
    close (FILE);
}

sub flush_cache {
    print "Flushing cache...\n";
    unlink ("$opkg_repo_cache");
    unlink ("$opkg_list_cache");
    print "Cache cleaned\n";
}

1;

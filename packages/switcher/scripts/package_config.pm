package scripts::package_config;

# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);
use Data::Dumper;
use OSCAR::Database;

@EXPORT = qw(get);
$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub get {

    # Query ODA to get the <switcher> blocks from other packages
    my $result = undef;
    my @sel_pkgs = database_return_list("packages_in_selected_package_set",1);
    if (!defined(@sel_pkgs)) {
	die("packages/switcher/scripts/package_config.pm failed to access the OSCAR database!");
    }
    my @tmp = database_return_list("switcher_list_packages_tags_names",1);
    if (!@tmp) {
	print "packages/switcher/scripts/package_config.pm: switcher tag list is empty";
    }
    while (@tmp) {
	my ($package, $tag, $name) = splice(@tmp, 0, 3);
	next if (!grep(/^$package$/,@sel_pkgs));
	$result->{$package} = { tag => $tag, name => $name, };
    }

    # Traverse the data returned and construct a data mapping tags to
    # names/packages.
    my %tags;
    foreach my $k (sort(keys(%$result))) {
	my $tag = $result->{$k}->{tag};
	if (defined($tags{$tag})) {
	    ++$tags{$tag}->{count};
	} else {
	    $tags{$tag} = {
		count => 1,
		names => [],
		packages => [],
	    };
	}
	my $names = $tags{$tag}->{names};
	push @$names, $result->{$k}->{name};
	my $packages = $tags{$tag}->{packages};
	push @$packages, $k;
    }
    
    # Return a reference to the hash
    \%tags;
}

1;

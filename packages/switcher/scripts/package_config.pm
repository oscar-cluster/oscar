package switcher::scripts::package_config;

# Copyright (c) 2002 The Trustees of Indiana University.  
#                    All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: package_config.pm,v 1.1 2002/11/01 04:48:28 jsquyres Exp $
#

use strict;
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);

@EXPORT = qw(get);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);


#
# This will be re-written when Neil introduces the ODA interface where
# I can search for this information in the database.  For the moment,
# I'm going to hard-code it...
#
sub get {

    # This is what I envision getting from ODA.  This is stuff from
    # the package config.xml files.

    my $result = {
	lam => {
	    tag => "mpi",
	    name => "lam-6.5.7",
	},
	mpich => {
	    tag => "mpi",
	    name => "mpich-1.2.4",
	},
    };

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

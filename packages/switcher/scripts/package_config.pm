package package_config;

# Copyright (c) 2002-2003,2007 The Trustees of Indiana University.  
#                         All rights reserved.
# Copyright (c) 2008 Geoffroy Vallee <valleegr at ornl dot gov>
#                    Oak Ridge National Laboratory
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#
# This module make the "glue" between OSCAR and Switcher: switcher data are
# saved into ODA, this module typically allow one to access this data with a
# user friendly reformatting (this is not the raw ODA data).
#
# TODO: with a good SwitcherAPI module, we should be able to remove this file.

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);
use Data::Dumper;
use OSCAR::Database;
use OSCAR::oda;
use OSCAR::SwitcherAPI;
use warnings "all";
use Carp;

@EXPORT = qw(get);
$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


sub get {

    # Query ODA to get the <switcher> blocks from other packages
    my %options = ();
    my @errors = ();
    my @results = ();
    if(OSCAR::SwitcherAPI::get_switcher_data (\@results,\%options,\@errors) ){
        carp ("ERROR: Impossible to get switcher data from the database");
        return undef;
    }
    my $result = undef;
    foreach my $result_ref (@results){
        my $package = $$result_ref{package};
        my $tag = $$result_ref{switcher_tag};
        my $name = $$result_ref{switcher_name};
        $result->{$package} = {
            tag => $tag,
            name => $name,
        };
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
    return \%tags;
}

1;

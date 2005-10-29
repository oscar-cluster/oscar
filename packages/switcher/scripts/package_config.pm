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
use OSCAR::oda

@EXPORT = qw(get);
$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#
# This will be re-written when Neil introduces the ODA interface where
# I can search for this information in the database.  For the moment,
# I'm going to hard-code it...
#
sub get {

    # Query ODA to get the <switcher> blocks from other packages
    my %options = ();
    my @errors = ();
    my @results = ();
    if(! get_packages_switcher(\@results,\%options,\@errors) ){
        die("packages/switcher/scripts/package_config.pm could not run ODA");
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
    #open(ODA, "oda switcher_list_packages_tags_names|") || 
	#die("packages/switcher/scripts/package_config.pm could not run ODA");
    #my $result = undef;
    #while (<ODA>) {
	#chomp($_);
	#my ($package, $tag, $name) = split(/ /, $_);
	#$result->{$package} = {
	#    tag => $tag,
	#    name => $name,
	#};
    #}
    #close(ODA);

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

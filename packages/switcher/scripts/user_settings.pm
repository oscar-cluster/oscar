package scripts::user_settings;

# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: user_settings.pm,v 1.2 2003/01/21 21:55:52 jsquyres Exp $
#

use strict;
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);

# Debugging
use Data::Dumper;

@EXPORT = qw(get);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

# Import some modules just for switcher

use lib "$ENV{OSCAR_PACKAGE_HOME}";
use scripts::package_config;


#
# This will be re-written when Neil introduces the ODA interface where
# I can search for this information in the database.  For the moment,
# I'm going to hard-code it...
#

sub get {

    # Read in the data from the results of the configurator step

    my $infile = "$ENV{OSCAR_PACKAGE_HOME}/.configurator.values";
    my $xs = new XML::Simple(keyattr => {});
    my $results;
    if (-e $infile) {
	$results = $xs->XMLin($infile);
    }

    # Read in all the <switcher> blocks from the package
    # configurations
    
    my $pkg_config = switcher::scripts::package_config::get();

    # Merge the two together.  Wherever there is no user-specified
    # setting from the configurator, make a default setting.

    my @tags_keys = keys(%$pkg_config);
    if ($#tags_keys >= 0) {
	foreach my $tag (sort(@tags_keys)) {
	    my $info = $pkg_config->{$tag};
	    if ($info->{count} > 1) {
		if (!$results->{$tag}) {
		    my @names = sort(@{$info->{names}});
		    $results->{$tag} = $names[0];
		}
	    }
	}
    }

    $results;
}

1;

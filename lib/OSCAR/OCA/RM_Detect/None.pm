#!/usr/bin/perl
#
# Copyright (c) 2005 Bernard Li <bli@bcgsc.ca>
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OCA::RM_Detect::None;

use strict;
use POSIX;
use Config;
use Data::Dumper;

# First set of data

our $id = {
    name => "None",
};

# Make final string

$id->{ident} = "$id->{name}";

# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}

# If we got here, we're happy

1;

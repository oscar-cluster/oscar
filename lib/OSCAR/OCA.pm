#
# Copyright (c) 2005 The Trustees of Indiana University.
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OSCAR::OCA;

use strict;

#######################################################
# Subroutine to find components in a given framework. #
# Return: Array with the list of components.          #
#######################################################
sub find_components {
    my ($framework, $basedir) = @_;

    # If framework is not specified, this is an error

    if (!$framework) {
        print "OCA::find_components invoked without a framework name\n";
        return undef;
    }

    # If basedir is not provided, use the default

    if (! $basedir) {
        if ($ENV{OSCAR_HOME}) {
            if (-d $ENV{OSCAR_HOME}) {
                $basedir = $ENV{OSCAR_HOME};
            }
        }
        if (! $basedir) {
            if (-d "/opt/oscar") {
                $basedir = "/opt/oscar";
            } else {
                print "Unable to find an OSCAR directory to look for components (no \$OSCAR_HOME\nand no /opt/oscar)\n";
                return undef;
            }
        }
    }

    # Append on the framework subdirectory that we're looking in

    $basedir .= "/lib/OSCAR/OCA/$framework";

    # Return on bozo error

    if (! -d $basedir) {
        print "Unable to find framework directory\n($basedir)\n";
        return undef;
    }

    # Scan the framework directory for .pm and .pmc files of the form:
    # $basedir/$comp.pm[c].

    opendir(DIR, $basedir);
    my @comps = 
        grep { ( /\.pm[c]{0,1}$/ || /\.pmc$/) && -f "$basedir/$_" } readdir(DIR);
    closedir(DIR);

    # We need to augment @INC here so that we can do a simple
    # "require", so save the current @INC and then augment it.

    my @INC_save = @INC;
    push(@INC, "$basedir");

    # Try opening all the .pm[c] files that we found above

    my @opened;
    foreach my $comp (@comps) {

        # Do a little trickiness: remove any trailing .pm or .pmc so
        # that when "require" rolls around, all we do is "require
        # <component_name>".

        $comp =~ s/.pm[c]{0,1}$//;

        # Do the require inside an eval so that if it fails, we won't
        # get a nasty error and/or abort.  The success status of the
        # eval'ed require will be in $@.

        eval "require $comp";
        if (! $@) {
            push(@opened, $comp);
        }
    }

    # Restore @INC

    @INC = @INC_save;

    # Return the names of the opened components

    \@opened;
}

1;

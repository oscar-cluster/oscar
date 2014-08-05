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
use OSCAR::Logger;
use OSCAR::LoggerDefs;

#######################################################
# Subroutine to find components in a given framework. #
# Return: Array with the list of components.          #
#######################################################
sub find_components {
    my ($framework, $basedir) = @_;

    # If framework is not specified, this is an error

    if (!$framework) {
        oscar_log(5, ERROR, "OCA::find_components invoked without a framework name");
        return undef;
    }

    # If basedir is not provided, use the default

    if (! $basedir) {
        if ($ENV{OSCAR_HOME}) {
            if (-d $ENV{OSCAR_HOME}) {
                $basedir = "$ENV{OSCAR_HOME}/lib";
            }
        } else {
            # Maybe OSCAR is installed directly on the system. In that case,
            # we try to see if OCA is not available in the default Perl
            # directories
            my $systemdir = `perl -V:vendorlib`;
            # Now we have to "format" the result that looks like
            # "vendorlib='/usr/lib/perl5'"
            chomp $systemdir;
            if ($systemdir =~ /^vendorlib=\'(.*)\';$/) {
                $basedir = $1;
            }
        }
        if ((! defined($basedir)) || (! -d $basedir)) {
            if (-d "/opt/oscar") {
                $basedir = "/opt/oscar/lib";
            } else {
                oscar_log(5, ERROR, "Unable to find an OSCAR directory to look for components (no \$OSCAR_HOME\nand no /opt/oscar)");
                return undef;
            }
        }
    }

    # Append on the framework subdirectory that we're looking in

    $basedir .= "/OSCAR/OCA/$framework";

    # Return on bozo error

    if (! -d $basedir) {
        oscar_log(5, ERROR, "Unable to find framework directory\n($basedir)");
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

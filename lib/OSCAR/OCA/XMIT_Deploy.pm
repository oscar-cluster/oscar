#
# Copyright (c) 2022 Olivier Lahaye <olivier.lahaye@cea.fr>
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OSCAR::OCA::XMIT_Deploy;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use 5.013; # use /r to do a non destructive substitution:
use Carp;

use OSCAR::OCA;
use OSCAR:Logger;
use OSCAR::LoggerDefs;
#
# Exports
#

@EXPORT = qw(name enable disable);

#
# Globals
#


###############################################################################
# Subroutine to open the XMIT_Deploy framework                                #
# Input:  None.                                                               #
# Return: Returns an array of XMIT available systemimager deploymentprotocols #
#         supported by OSCAR (None, Rsync, Bittorrent, Flamethrower)          #
###############################################################################
sub open {
    my @xmit_deployment_methods = ();
    my $comps = OSCAR::OCA::find_components("XMIT_Deploy");
    if (!defined($comps)) {
        # If we get undef, then find_components() already printed an
        # error, and we decide that we want to die
        OSCAR::Logger::oscar_log(5, ERROR, "Cannot continue, find_components returned undef");
        OSCAR::Logger::oscar_log(1, ERROR, "Failed to enumerate available XMIT deployment methods.");
        return undef;
    } elsif (scalar(@$comps) == 0) {
#        print STDERR "Could not find an OS_Detect component for this system!\n";
        OSCAR::Logger::oscar_log(5, ERROR, "Could not find an XMIT_Deploy component for this system!");
        OSCAR::Logger::oscar_log(1, ERROR, "Failed to find a XMIT deployment method.");
        return undef;
    }

    # Yes, we found some components. Check which one returns a valid id
    # hash.

    my $ret = undef;
    foreach my $comp (@$comps) {
        my $str;
	$str = "\$ret = \&OSCAR::OCA::XMIT_Deploy::".$comp."::available()";
	my $res = eval $str;
	if($res && $ret) {
            # If XMIT Component is available, than add it to the available components.
	    (my $comp_name = $comp) =~ s/XMIT_//g;
	    push @xmit_deployment_methods, $comp_name;
	}
    }
    return @xmit_deployment_methods;
#
}



###############################################################################
# Subroutine to get the name of XMIT deployment method (for GUI)              #
# Input:  Component name without the leading XMIT_                            #
# Return: Returns a string with SystemImager XMIT deployment name             #
#         supported by OSCAR (rsync, bittorrent, flamethrower)                #
###############################################################################
sub name {
    my $str;
    my $name;
    $str = "\$name = \&OSCAR::OCA::XMIT_Deploy::XMIT_".$comp."::name()";
    my $res = eval $str;
    return $name if($res);
    # Failed
    oscar_log(5, ERROR, "OSCAR::OCA::XMIT_Deploy::XMIT_".$comp."::name() failed");
    return undef;
}


###############################################################################
# Subroutine to configure enable and start the required services for this     #
# XMIT Deployment method.
# Input:  Component name without the leading XMIT_                            #
# Return: Returns 1 on success (0 on failure)
###############################################################################
sub enable {
}

###############################################################################
# Subroutine to disable and stop the required services for this XMIT          #
# Deployment method.                                                          #
# Input:  Component name without the leading XMIT_                            #
# Return: Returns 1 on success (0 on failure)
###############################################################################
sub disable {
}


1;

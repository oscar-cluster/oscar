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

package OSCAR::OCA::XMIT_Deploy::XMIT_None;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::OCA::OS_Settings;
use OSCAR::OCA::XMIT_Deploy;
#
# Exports
#

@EXPORT = qw(name available enable disable);

#
# Globals
#

our $xmit_name = __PACKAGE__;
$xmit_name =~ s/^.*::XMIT_//g;

# Return the name of the deployment method as user can see in GUI.
sub name {
    return "flamethrower";
}

# Return 1 if deployment method is available (0 if not)
sub available {
    oscar_log(5, INFO, "$xmit_name deplyoment method is not (and will never be) available.");
    oscar_log(5, INFO, "Please chose something else.");
    return 0;
}

# Disable all other method and do nothing None is a stubb xmit deployment method.
sub enable {
    OSCAR::OCA::XMIT_Deploy::disable_all_but("$xmit_name");
    oscar_log(5, ERROR, "$xmit_name can't be enabled.");

    return 0;
}

# Disable None method.
sub disable {
	oscar_log(5, INFO, "$xmit_name is always disabled. Nothing to do");
        return 1;
}


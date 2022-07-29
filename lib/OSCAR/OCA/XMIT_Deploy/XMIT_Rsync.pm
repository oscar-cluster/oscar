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

package OSCAR::OCA::XMIT_Deploy::XMIT_Rsync;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::SystemServices;
use OSCAR::SystemServicesDefs;

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
    return "rsync";
}

# Return 1 if deployment method is available (0 if not)
sub available {
    my $file = OSCAR::OCA::OS_Settings::getitem(SI_RSYNC . "_configfile");
    return 1 if (-f "$file");
    oscar_log(5, INFO, "$xmit_name deplyoment method is not available.");
    oscar_log(5, INFO, "Please check your systemimager installation (rsync should always be available.");
    return 0;
}

# Disable all other method and enable Rsync and start daemon.
sub enable {
    OSCAR::OCA::XMIT_Deploy::disable_all_but("Rsync");
    # Restart systemimager-server-rsyncd
    !system_service(SI_RSYNC,RESTART)
        or (oscar_log(5, ERROR, "Couldn't restart systemimager-rsync."), return 0);

    # Enable systemimager-server-rsyncd
    !enable_system_services( (SI_RSYNC) )
        or (oscar_log(5, ERROR, "Couldn't enable systemimager-rsync."), return 0);

    return 1;
}

# Disable rsync method.
sub disable {
    !disable_system_services( (SI_RSYNC) )
        or (oscar_log(5, ERROR, "Couldn't disable systemimager-rsync."), return 0);
    !system_service(SI_RSYNC,STOP)
        or (oscar_log(5, ERROR, "Couldn't stop systemimager-rsync."), return 0);
    return 1;
}


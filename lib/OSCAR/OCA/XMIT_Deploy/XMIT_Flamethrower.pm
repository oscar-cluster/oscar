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

package OSCAR::OCA::XMIT_Deploy::XMIT_Flamethrower;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::SystemServices;
use OSCAR::SystemServicesDefs;
use OSCAR::Database;
use OSCAR::OCA::OS_Settings;
use OSCAR::OCA::OS_Detect;
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
    my $file = OSCAR::OCA::OS_Settings::getitem(SI_FLAMETHROWER . "_configfile");
    return 1 if (-f "$file");
    oscar_log(5, INFO, "$xmit_name deplyoment method is not available.");
    oscar_log(5, INFO, "Please install systemimager-server-".name().".");
    return 0;
}

# Disable all other method and enable flamethrowerd and start daemon.
sub enable {
    OSCAR::OCA::XMIT_Deploy::disable_all_but("$xmit_name");
    my $os = OSCAR::OCA::OS_Detect::open();
    my $interface = OSCAR::Database::get_headnode_iface(undef, undef);

    # Backup original bittorrent.conf
    my $file = OSCAR::OCA::OS_Settings::getitem(SI_FLAMETHROWER . "_configfile");
    if (-f $file) {
        # 1st, create a backup of the config file if not already done.
        backup_file_if_not_exist($file) or return 0;

        # 2nd, Update config (enable daemon mode, and set the net iface).
        my $cmd = "sed -i -e 's/START_FLAMETHROWER_DAEMON = no/START_FLAMETHROWER_DAEMON = yes/' -e 's/INTERFACE = eth[0-9][0-9]*/INTERFACE = $interface/' $file";
        if( oscar_system( $cmd ) ) {
            oscar_log(5, ERROR, "ERROR: Failed to update $file");
            return 0;
        }

        # add entry for boot-<arch>-standard module
        my $march = $os->{'arch'};
        $march =~ s/i.86/i386/;
        $cmd = "/usr/lib/systemimager/confedit --file $file --entry boot-$march-standard --data \" DIR=/usr/share/systemimager/boot/$march/standard/\"";
        if( oscar_system( $cmd ) ) {
            return 0;
        }

        oscar_log(5, INFO, "Successfully updated $file");

        # Restart systemimager-server-flamethrowerd
        !system_service(SI_FLAMETHROWER,RESTART)
            or (oscar_log(5, ERROR, "Couldn't stop systemimager-server-flamethrowerd."), return 0);

        # Add systemimager-server-flamethrowerd to chkconfig
        !enable_system_services( (SI_FLAMETHROWER) )
            or (oscar_log(5, ERROR, "Couldn't disable si_flametrhower and si_bittorrent."), return 0);
    } else {
        oscar_log(5, ERROR, "Flamethrower config file not found [$file]");
        return 0;
    }

    # Restart systemimager-server-bittorrent
    !system_service(SI_FLAMETHROWER,RESTART)
        or (oscar_log(5, ERROR, "Couldn't restart systemimager-bittorrent."), return 0);

    # Enable systemimager-server-bittorrent
    !enable_system_services( (SI_FLAMETHROWER) )
        or (oscar_log(5, ERROR, "Couldn't enable systemimager-bittorrent."), return 0);

    # Restart systemimager-server-rsyncd (needed by netbootmond and also for calculating image size in si_monitortk)
    !system_service(SI_RSYNC,RESTART)
        or (oscar_log(5, ERROR, "Couldn't restart systemimager-rsync."), return 0);

    return 1;
}

# Disable Flamethrower method.
sub disable {
	!disable_system_services( (SI_FLAMETHROWER) )
	    or (oscar_log(5, ERROR, "Couldn't disable systemimager-bittorrent."), return 0);
        !system_service(SI_FLAMETHROWER,STOP)
	    or (oscar_log(5, ERROR, "Couldn't stop systemimager-bittorrent."), return 0);
        return 1;
}


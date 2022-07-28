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

package OSCAR::OCA::XMIT_Deploy::XMIT_Bittorrent;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

use OSCAR:Logger;
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
$xmit_name ~= s/^.*::XMIT_//g;

# Return the name of the deployment method as user can see in GUI.
sub name {
    return "bittorrent";
}

# Return 1 if deployment method is available (0 if not)
sub available {
    my $file = OSCAR::OCA::OS_Settings::getitem(SI_BITTORRENT . "_configfile");
    return 1 if (-f "$file");
    oscar_log(5, INFO, "$xmit_name deplyoment method is not available.");
    oscar_log(5, INFO, "Please install systemimager-server-".name().".");
    return 0;
}

# Disable all other method and enable Bittorrent and start daemon.
sub enable {
    OSCAR::OCA::XMIT_Deploy::disable_all_but("$xmit_name");

    # Backup original bittorrent.conf
    my $file = OSCAR::OCA::OS_Settings::getitem(SI_BITTORRENT . "_configfile");
    if (-f $file) {
        # 1st, create a backup of the config file if not already done.
        backup_file_if_not_exist($file) or return 0;

        my @images = list_image();
        # FIXME: Check @images is defined.

        my $images_list = join(",", map { $_->name } @images);

        # 2nd, set the net interface to use.
        $cmd = "sed -i -e 's/BT_INTERFACE=eth[0-9][0-9]*/BT_INTERFACE=$interface/' -e 's/BT_IMAGES=.*/BT_IMAGES=$images_list/' -e 's/BT_OVERRIDES=.*/BT_OVERRIDES=$images_list/' $file";
        if( oscar_system( $cmd ) ) {
            oscar_log(5, ERROR, "Failed to update $file");
            return 0;
        }

        oscar_log(4, INFO, "Successfully updated $file");
    } else {
        oscar_log(5, ERROR, "Bittorrent config file [$file] does not exists!");
     return 0;
    }

    # Restart systemimager-server-bittorrent
    !system_service(SI_BITTORRENT,RESTART)
        or (oscar_log(5, ERROR, "Couldn't restart systemimager-bittorrent."), return 0);

    # Enable systemimager-server-bittorrent
    !enable_system_services( (SI_BITTORRENT) )
        or (oscar_log(5, ERROR, "Couldn't enable systemimager-bittorrent."), return 0);

    # Restart systemimager-server-rsyncd (needed by netbootmond and also for calculating image size in si_monitortk)
    !system_service(SI_RSYNC,RESTART)
        or (oscar_log(5, ERROR, "Couldn't restart systemimager-rsync."), return 0);

    return 1;
}

# Disable Bittorrent method.
sub disable {
	!disable_system_services( (SI_BITTORRENT) )
	    or (oscar_log(5, ERROR, "Couldn't disable systemimager-bittorrent."), return 0);
        !system_service(SI_BITTORRENT,STOP)
	    or (oscar_log(5, ERROR, "Couldn't stop systemimager-bittorrent."), return 0);
        return 1;
}


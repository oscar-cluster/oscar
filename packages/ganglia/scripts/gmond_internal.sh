#!/bin/bash

# $Id: gmond_internal.sh,v 1.5 2002/08/22 09:14:09 sad Exp $

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#   script to add internal interface to invocation of gmond daemon
#   in it's init script
#   Steven A. DuChene  <linux-clusters@mindspring.com>

internal_interface=${$OSCAR_HEAD_INTERNAL_INTERFACE:?"undefined!"}

if [ -f /etc/init.d/gmond ]; then
    sed "s/daemon \$GMOND/daemon \$GMOND -i$OSCAR_HEAD_INTERNAL_INTERFACE/" < /etc/init.d/gmond > /tmp/gmond.new
    mv /etc/init.d/gmond /etc/init.d/gmond.orig
    mv /tmp/gmond.new /etc/init.d/gmond
    chmod 755 /etc/init.d/gmond
    service gmond restart

else
    echo "/etc/init.d/gmond is missing"
    exit 1
fi

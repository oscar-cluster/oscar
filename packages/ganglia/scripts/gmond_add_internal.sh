#!/bin/bash

# $Id: gmond_add_internal.sh,v 1.3 2002/10/31 18:49:23 sad Exp $

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

# the following is for the old version of ganglia-monitor-core
# may need some of this later to work on oscar upgrade stuff

#grep -q OSCAR /etc/init.d/gmond 

#if [ $? = 0 ]; then
#    echo "/etc/init.d/gmond is already modified with internal interface"
#    exit 0
#elif [ -z $OSCAR_HEAD_INTERNAL_INTERFACE ]; then
#    echo "no internal interface being passed"
#    exit 1
#elif ! [ -f /etc/init.d/gmond ]; then
#    echo "/etc/init.d/gmond is missing"
#    exit 1
#else
#    sed -e "s/daemon \$GMOND$/daemon \$GMOND -i$OSCAR_HEAD_INTERNAL_INTERFACE/" -e '/# description: gmond startup script/a\
#    # OSCAR internal interface mods done' < /etc/init.d/gmond > /tmp/gmond.new
#    mv /etc/init.d/gmond /etc/init.d/gmond.orig
#    mv /tmp/gmond.new /etc/init.d/gmond
#    chmod 755 /etc/init.d/gmond
#    service gmond restart
#    echo successfully added internal interface to gmond startup script
#fi

grep -q OSCAR /etc/gmond.conf

if [ $? = 0 ]; then
    echo "/etc/gmond.conf is already modified with internal interface"
    exit 0
elif [ -z $OSCAR_HEAD_INTERNAL_INTERFACE ]; then
    echo "no internal interface being passed"
    exit 1
elif ! [ -f /etc/gmond.conf ]; then
    echo "/etc/gmond.conf is missing"
    exit 1
else
    sed -e "s/# mcast_if  eth1$/mcast_if  $OSCAR_HEAD_INTERNAL_INTERFACE/" -e '/# default: the kernel decides based on routing configuration/a\
    # OSCAR internal interface mods done' < /etc/gmond.conf > /tmp/gmond.conf.new
    mv /etc/gmond.conf /etc/gmond.conf_before_oscar
    mv /tmp/gmond.conf.new /etc/gmond.conf
    chmod 755 /etc/gmond.conf
    service gmond restart
    echo successfully added internal interface to gmond.conf
fi

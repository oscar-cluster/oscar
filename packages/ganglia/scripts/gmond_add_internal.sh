#!/bin/bash

# $Id: gmond_add_internal.sh,v 1.9 2002/12/29 18:05:48 sad Exp $

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

grep -q rrdtool /etc/ld.so.conf

if [ $? = 0 ]; then
    echo "/etc/ld.so.conf is already modified with rrdtool lib path"
else 
echo adding library path to /etc/ld.so.conf for rrdtool libs
echo "/opt/rrdtool-1.0.35/lib" >> /etc/ld.so.conf
/sbin/ldconfig
fi

grep -q OSCAR /etc/gmond.conf

if [ $? = 0 ]; then
    echo "/etc/gmond.conf is already modified with internal interface"
elif [ -z $OSCAR_HEAD_INTERNAL_INTERFACE ]; then
    echo "no internal interface being passed"
elif ! [ -f /etc/gmond.conf ]; then
    echo "/etc/gmond.conf is missing"
    exit 1
else
    sed -e "s/# mcast_if  eth1$/mcast_if  $OSCAR_HEAD_INTERNAL_INTERFACE/" -e '/# default: the kernel decides based on routing configuration/a\
# OSCAR internal interface mods done' < /etc/gmond.conf > /tmp/gmond.conf.new
    mv /etc/gmond.conf /etc/gmond.conf_before_oscar
    mv /tmp/gmond.conf.new /etc/gmond.conf
    chmod 755 /etc/gmond.conf
    echo successfully added internal interface to gmond.conf
fi

grep -q OSCAR /etc/gmetad.conf

if [ $? = 0 ]; then
    echo "/etc/gmetad.conf is already modified with internal interface"
    exit 0
elif ! [ -f /etc/gmetad.conf ]; then
    echo "/etc/gmetad.conf is missing"
    exit 1
else
    sed -e '/# data_source \"another source\"  1.3.4.7:8655  1.3.4.8/a\
data_source \"OSCAR\" localhost' -e '/# trusted_hosts 127.0.0.1 169.229.50.165/a\
trusted_hosts 127.0.0.1' -e '/# rrd_rootdir \"\/some\/other\/place\"/a\
rrd_rootdir \"\/var\/log\/ganglia\/rrds\"' -e '/#                http:\/\/ganglia.sourceforge.net\//a\
# OSCAR gmetad.conf mods done' < /etc/gmetad.conf > /tmp/gmetad.conf.new
    mv /etc/gmetad.conf /etc/gmetad.conf_before_oscar
    mv /tmp/gmetad.conf.new /etc/gmetad.conf
    chmod 755 /etc/gmetad.conf
    echo successfully added internal interface to gmetad.conf
fi

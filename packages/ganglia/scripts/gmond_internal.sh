#!/bin/bash

internal_interface=${$OSCAR_HEAD_INTERNAL_INTERFACE:?"undefined!"}

if [ -f /etc/init.d/gmond ]; then
    sed "s/daemon \$GMOND/daemon \$GMOND -i$OSCAR_HEAD_INTERNAL_INTERFACE/" < /etc/init.d/gmond > /tmp/gmond.new
    mv /etc/init.d/gmond /etc/init.d/gmond.orig
    mv /tmp/gmond.new /etc/init.d/gmond
    service gmond restart

else
    echo "/etc/init.d/gmond is missing"
    exit 1
fi

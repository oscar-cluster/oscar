#!/bin/bash

# $Id: ganglia_test.sh,v 1.2 2002/08/22 09:01:02 sad Exp $

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

#   ganglia Server test script
#   Steven A. DuChene  <linux-clusters@mindspring.com>

gang=/usr/sbin/ganglia

 if [ -x $gang ]; then
        echo ganglia command line tools are installed
        $gang >&-
        if [ $? != 0 ]; then
              echo 'gmond not available - is it running?'
              exit 1
        else
              echo ganglia command line tool is able to connect to gmond daemon
              howmany=$($gang noacounthosts | wc -l)
              echo There are $howmany hosts responding with running gmond processes
        fi
    else
         echo 'no /usr/sbin/ganglia - are command line tools installed?'
  fi


#!/bin/bash

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


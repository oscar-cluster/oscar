---
layout: wiki
title: DevelNewDistro
meta: 
permalink: "/wiki/DevelNewDistro"
category: wiki
---
<!-- Name: DevelNewDistro -->
<!-- Version: 5 -->
<!-- Author: dikim -->

## bootstrap oscar-packager for a new yum based linux distribution.

This quick and dirty script gives a good idea of what needs to be done in order to have an up and running oscar-packager on a blank new distro.

(Example) - name the script to "make_oscar.sh"
    | ./make_oscar.sh | Builds all the OSCAR packages for rhel-6-x86_64 \\ when it is run for the first time. Builds only the failed packages after the first trial. |
    | ./make_oscar.sh -f | Builds all the OSCAR packages for rhel-6-x86_64 no matter \\ whether it is the first-time run or not. |
    | ./make_oscar.sh -d fedora-19-x86_64 | Builds all the packages for fedora-19-x86_64 \\ when it is run for the first time. Builds only the failed packages after that. |
    | ./make_oscar.sh -f -d centos-7-x86_64 | Builds all the packages for centos-7-x86_64 no matter \\ whether it is the first-time run or not. |


    #!/bin/bash
    
    force=""
    distro="rhel-6-x86_64"
    while getopts ":d:f" opt; do
        case $opt in
            f)
                echo "oscar-packager's option '-f' or '--force' was triggered!" >&2
                force="--force"
                ;;
            d)
                echo "The distro name ($OPTARG) is invoked!" >&2
                distro=$OPTARG
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                ;;
        esac
    done
    
    # Download svn sources
    if [ ! -d OSCAR ]; then
        mkdir OSCAR
    fi
    cd OSCAR
    
    if [ ! -d oscar/.svn ]; then
        svn co https://svn.oscar.openclustergroup.org/svn/oscar/trunk oscar
    else
        cd oscar; svn up; cd ..
    fi
    
    if [ ! -d pkgsrc/.svn ]; then
        svn co https://svn.oscar.openclustergroup.org/svn/oscar/pkgsrc pkgsrc
    else
        cd pkgsrc; svn up; cd ..
    fi
    
    # Install required packages for the build.
    sudo yum -y install rpm-build automake autoconf python-devel xmlto
    
    # Build main oscar packages and install lib files.
    cd oscar
    make rpm
    sudo yum -y install $(rpm --eval '%_rpmdir')/noarch/oscar-base-lib*\
    6.1.2r*.noarch.rpm
    
    # Build opkgc and install it (required by oscar-packager)
    cd ../pkgsrc/opkgc/trunk/
    ./autogen.sh
    ./configure
    make dist
    sudo rpmbuild -tb opkgc-*.tar.gz
    sudo yum -y install $(rpm --eval '%_rpmdir')/noarch/opkgc-*.noarch.rpm
    
    # Build yume and install it (required by packman)
    # Build packman and install it (required by oscar-packager)
    # Build oscar-packager and install it.
    cd ../..
    for package in yume packman oscar-packager
    do
        (cd ${package}/trunk; make rpm)
        sudo yum -y install $(rpm --eval '%_rpmdir')/noarch/${package}*.noarch.rpm
    done
    
    # Install oscar-config so we can setup distro. We do this without deps as those
    # deps are not required for what we'll do. (need oscar-base-scripts for
    # oscar-config and oscar-base for supported_distros.txt
    
    sudo rpm -Uvh --nodeps $(rpm --eval '%_rpmdir')/noarch\
    /oscar-{base,scripts*}-6.1.2r*.noarch.rpm
    
    # Setup the distro and yume local repo.
    sudo oscar-config --setup-distro $distro
    
    # Build all oscar packages
    sudo oscar-packager $force --all unstable
    
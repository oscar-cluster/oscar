#!/bin/sh
#
# $Id: make-dist.sh,v 1.2 2001/12/19 02:36:54 jsquyres Exp $
#
# $COPYRIGHT$
#

distdir="`pwd`/$1"

echo "*** Customizing OSCAR distribution"

#
# Make the docs
#

if ! test -f configure; then
    echo " - running GNU auto tools"
    sh ./autogen.sh
fi
if ! test -f Makefile; then
    echo " - running configure"
    ./configure
fi

echo " - building installation docs"
cd doc/installation
make clean ps
make mostlyclean pdf
make mostlyclean
cp install.ps install.pdf $distdir/doc/installation

echo " - building introduction docs"
cd ../introduction
make clean ps
make mostlyclean pdf
make mostlyclean
cp intro.ps intro.pdf $distdir/doc/introduction

#
# All done
#

echo "*** All done!"
exit 0

#!/bin/sh

source defs.sh

# Let's delete existing dir
pushd ../../../doc;
for dir in $DOC; do \
    rm -rf $dir;\
done
popd

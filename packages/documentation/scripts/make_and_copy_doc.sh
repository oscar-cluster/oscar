#!/bin/sh

source defs.sh;

# Let's generate the doc
for dir in $SRC; do \
    echo "Generating $dir";\
    pushd ../../../doc/$dir;\
    make html;\
    popd;\
done

# Let's copy the relevant directories
for dir in $DOC; do \
    echo "Generating $dir";\
    cp -rf ../../../doc/$dir ../html;\
    popd;\
done

# Delete and copy the html directory in /var/www/html/oscar

rm -rf /var/www/html/oscar
cp -rf ../html /var/www/html/oscar

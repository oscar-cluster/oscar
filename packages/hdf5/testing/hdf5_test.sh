#!/bin/bash

HDF5_TMP=/tmp/hdf5_test

# The HDF5 test itself
# Test that we can compile two HDF5 example programs and run them.

echo "Running HDF5 test on $HOSTNAME"
mkdir -p $HDF5_TMP
cd $HDF5_TMP
cp /opt/hdf5-oscar-1.4.5-post2/examples/h5_read.c .
cp /opt/hdf5-oscar-1.4.5-post2/examples/h5_write.c .

( h5cc h5_write.c -o h5_write && \
h5cc h5_read.c -o h5_read && \
./h5_write && ./h5_read && \
echo && echo "HDF5 SUCCESS") || echo "HDF5 FAILED"

# Remove temporary directory
rm -rf $HDF5_TMP

echo
echo "HDF5 test complete"
echo


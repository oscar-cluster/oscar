package OSCAR::SystemSanity;
# $Id$
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# Semantics: The tool reads a directory of check scripts, which either
#            success (0), failure (255), or warning (1..254), printing 
#            such info and having the respective return codes.
#
#            NOTE: Due to a single unsigned byte used in process tables on
#             many system, we are limited to process/shell return codes 
#             of 0..255.
#
#  See also: $OSCAR_HOME/scripts/{system-sanity, system-sanity.d/}
#

use strict;
use base qw(Exporter);

use constant { SUCCESS => 0,
               WARNING => 1,    # can be 1..254
               FAILURE => 255,
              };

# NOTE: required so the @EXPORT (default exported to all) works ok
my @ISA = qw(Exporter);

our @EXPORT = qw(SUCCESS WARNING FAILURE);

1;

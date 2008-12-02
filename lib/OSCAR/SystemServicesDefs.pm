package OSCAR::SystemServicesDefs;

# $Id$
#
# Copyright (c) 2008 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory.
#                    All rights reserved.

use strict;
use base qw(Exporter);

# TODO: we do not deal with the case where a service is not disabled/enabled
# for all 2, 3, 4, and 5 runlevels.
use constant SERVICE_DISABLED => 0;
use constant SERVICE_ENABLED  => 1;

my @ISA = qw(Exporter);

our @EXPORT = qw(
                SERVICE_DISABLED
                SERVICE_ENABLED
                );

1;

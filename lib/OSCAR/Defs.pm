package OSCAR::Defs;

# $Id$
#
# Copyright (c) 2009 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory.
#                    All rights reserved.

use strict;
use base qw(Exporter);

# Definition of some options commonly used by OSCAR functions
use constant NO_OVERWRITE       => 0;
use constant OVERWRITE          => 1;

# Some macros specific to file management: the different file types are support
use constant TARBALL            => 'tarball';
use constant SRPM               => 'srpm';
use constant SVN                => 'svn';

my @ISA = qw(Exporter);

our @EXPORT = qw(
                NO_OVERWRITE
                OVERWRITE

                TARBALL
                SRPM
                );

1;

package OSCAR::LoggerDefs;

#
# Copyright (c) 2008-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This package provides a set of functions for the management of system
# services.
#

#
# $Id: LoggerDefs.pm ol222822 $
#

use strict;
use base qw(Exporter);

# Constants used for log messsages categories.
use constant ACTION         => 'ACTION';
use constant DB             => 'DB';
use constant ERROR          => 'ERROR';
use constant INFO           => 'INFO';
use constant SECTION        => 'SECTION';
use constant SUBSECTION     => 'SUBSECTION';
use constant WARNING        => 'WARNING';
use constant NONE           => 'NONE';

my @ISA = qw(Exporter);

our @EXPORT = qw (
                ACTION
                DB
                ERROR
                INFO
                SECTION
                SUBSECTION
                WARNING
                NONE
                 );

1;

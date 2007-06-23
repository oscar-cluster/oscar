package OSCAR::OCA::Debugger;

#
# Copyright (c) 2006 Oak Ridge National Laboratory 
#                    Geoffroy Vallee <valleegr.ornl.gov>
#                    All rights reserved.
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

use strict;
use OSCAR::Logger;
use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw(oca_debug_section oca_debug_subsection);


sub oca_debug_section {
  my $debug_text = shift;
  if ( defined $ENV{OCA_DEBUG} && $ENV{OCA_DEBUG} eq "y" ) {
    oscar_log_section ($debug_text);
  }
}


sub oca_debug_subsection {
  my $debug_text = shift;
  if ( defined $ENV{OCA_DEBUG} && $ENV{OCA_DEBUG} eq "y" ) {
    oscar_log_subsection ($debug_text);
  }
}

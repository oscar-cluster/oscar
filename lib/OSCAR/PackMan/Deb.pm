#
#   $Id: Deb.pm,v 1.1 2004/02/17 17:06:58 tuelusr Exp $
#
# Copyright (c) 2003 Adam Lazur <laz@progeny.com>
#
# Deb.pm
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

package PackMan::Deb;

use 5.008;
use strict;
use warnings;

use constant { AGGREGATEABLE => 1, NOT_AGGREGATEABLE => 0 };
use Carp;

our $VERSION;

#$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/); # cvs style
$VERSION = sprintf("%d", q$Rev: 14 $ =~ /(\d+)/); # svn style

# Must use this form due to compile-time checks by PackMan.
use base qw(PackMan);

# Preloaded methods go here.
# boilerplate constructor because PackMan's is "abstract"
sub new {
  ref (my $class = shift) and croak ("constructor called on instance");
  my $new  = { ChRoot => shift };
  bless ($new, $class);
  return ($new);
}

# convenient constructor alias
sub Deb { 
  return (new (@_))
}

# Called by PackMan->new to determine which installed concrete PackMan handler
# claims to be able to manage packages on the target system. Args are the
# root directory being passed to the PackMan constructor.
sub usable {
  use OSCAR::Distro qw(which_distro_server);
  ref (shift) and croak ("usable is a class method");
  my $chroot = shift;
  my ($distro, undef) = which_distro_server ($chroot);
  return ($distro eq "debian");
}

# How dpkg installs packages (aggregatable)
sub install_command_line {
  AGGREGATEABLE, 'dpkg --install #args'
}

# How dpkg upgrades installed packages (aggregatable)
sub update_command_line {
  AGGREGATEABLE, 'dpkg --install #args'
}

# How dpkg removes installed packages (aggregatable)
sub remove_command_line {
  AGGREGATEABLE, 'dpkg --remove #args'
}

# How dpkg queries installed packages (not aggregatable)
sub query_installed_command_line {
  NOT_AGGREGATEABLE, 'dpkg --list #args'
}

# How dpkg queries installed package versions (not aggregatable)
sub query_version_command_line {
  # Wish I could use this instead of the /bin/sh hackery below to conform to
  # the API:
  # NOT_AGGREGATEABLE, 'dpkg-query --showformat=${Version} --show #args'
  NOT_AGGREGATEABLE, 'dpkg -s #args 2>/dev/null | awk \'BEGIN {rc=1} /Version: / {print $2; rc=0} END {exit rc}\''
}

# How rpm(8) changes root
sub chroot_arg_command_line {
  '--root=#chroot'
}

1;
__END__
=head1 NAME

PackMan::Deb - Perl extension for Package Manager abstraction for debs

=head1 SYNOPSIS

  Constructors

  # in environment where Deb is the default package manager:
  use PackMan;
  $pm = PackMan->new;

  use PackMan::Deb;
  $pm = Deb->new;	or Deb->Deb;

  use PackMan;
  $pm = PackMan->Deb;

  use PackMan;
  $pm = PackMan::Deb->new;	or PackMan::Deb->Deb;

  For more, see PackMan.

=cut

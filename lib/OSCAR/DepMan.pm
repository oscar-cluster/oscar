package DepMan;

#   Copyright (c) 2003 The Trustees of Indiana University.
#                      All rights reserved.
#
#  This file is part of the OSCAR software package.  For license
#  information, see the COPYING file in the top level directory of the
#  OSCAR source distribution.
#
#  $Id: DepMan.pm,v 1.2 2004/01/28 01:18:03 tuelusr Exp $

use 5.008;
use strict;
use warnings;

use Carp;
use File::Spec;

our $VERSION;
$VERSION = '0.01';
# initial release

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

# concrete dependency manager order of preference, for breaking ties on
# systems where multiple dependency manager modules might claim usability.
# see below
my @preference;

# populated by BEGIN block with keys usable in @preference and values of
# where each DepMan module is located
my %concrete;

my $installed_dir;

# Preloaded methods go here.
BEGIN {
  $installed_dir = "OSCAR";	# ugly hack

# change to qw() when Deb gets written
# If, by hook or crook, you are on a system where both RPM and Deb (and
# whatever other package managers) will claim usability for a given
# filesystem, rank them in @preference. Recognition as the default package
# manager is on a first-come, first-served basis out of @preference. If no
# default package manager can be determined, all available package managers
# will be consulted in an indeterminant order in a final attempt to find one
# that's usable.
  @preference = qw(Update_RPMs);

  my $depman_dir = File::Spec->catdir ($installed_dir,
					split ("::", __PACKAGE__));
  my $full_dir;

  foreach my $inc (@INC) {
    $full_dir = File::Spec->catdir ($inc, $depman_dir);
    if (-d $full_dir) {
      last;
    } else {
      undef ($full_dir);
    }
  }

  defined ($full_dir) or
    croak "No directory of concrete " . __PACKAGE__ .
	  " implementations could be found!";

  opendir (DEPMANDIR, $full_dir) or
    croak "Couldn't access concrete " . __PACKAGE__ . " implementations: $!";

  foreach my $dm (readdir (DEPMANDIR)) {
    # only process .pm files
    if ($dm =~ m/\.pm$/) {
      require File::Spec->catfile ($depman_dir, $dm);
      $dm =~ s/\.pm$//;
      my $module = $depman_dir;
      # Calling isa requires that the installed directory be stripped.
      $module =~ s:^$installed_dir/::;
      $module = join ("::", File::Spec->splitdir ($module)) . "::" . $dm;
      # if it's actually a DepMan module, remember it
      if ("$module"->isa (__PACKAGE__)) {
	$concrete{$dm} = $module;
      }
    }
  }
  closedir (DEPMANDIR);

  scalar %concrete or
    croak "No concrete " . __PACKAGE__ . " implementations could be found!";

  @preference = grep { defined $concrete{$_} } @preference;
}

# AUTOLOAD named constructors for the concrete modules
# Makes DepMan->Update_RPMs (<root dir>, <cache location>) do the same as
# DepMan::Update_RPMs->new (<root dir>, <cache location>)
sub AUTOLOAD {
  no strict 'refs';
  our $AUTOLOAD;
  if ($AUTOLOAD =~ m/::(\w+)$/ and grep $1 eq $_, keys %concrete) {
    my $module = $concrete{$1}; # uninitialized hash element error otherwise
    *{$1} = sub {
      ref (shift) and croak $1 . " constructor is a class method";
      return ("$module"->new (@_))
    };
    die $@ if $@;
    goto &$1;
  } else {
    die "$_[0] does not understand $AUTOLOAD\n";
  }
}

# Primary constructor
# doesn't actually create/bless any new objects itself (hence is class is
# abstract).
sub new {
  # require clauses are not necessary here, since each module's been
  # require'd in the BEGIN block to determine if it's actually a DepMan
  # object.
  ref (shift) and
    croak __PACKAGE__ . " constructor is a class method.";

  foreach my $dm (@preference) {
    if ("$concrete{$dm}"->usable (@_)) {
      # first come, first served
      return ("$concrete{$dm}"->new (@_));
    }
  }
  # Wasn't found among the preferences, second chance, all of %concrete
  # Can this be made more efficient by filtering out all values belonging to
  # modules in @preferences? Perhaps.
  foreach my $dm (values %concrete) {
    if ("$dm"->usable (@_)) {
      return ("$dm"->new (@_));
    }
  }
  # Here, we're solidly S.O.L.
  croak "No usable concrete " . __PACKAGE__ . " module was found.";
}

# "instance constructor", creates a copy of an existing object with instance
# variable values.
sub clone {
  ref (my $self = shift) or croak "clone is an instance method";
  my $new  = { ChRoot => $self->{ChRoot}, Cache => $self->{Cache} };
  bless ($new, ref ($self));
  return ($new);
}

# destructor, essentialy to quell some annoying warning messages.
sub DESTROY {
  ref (my $self = shift) or croak "DESTROY is an instance method";
  delete $self->{ChRoot};
  delete $self->{Cache};
}

# Set the ChRoot instance variable for this object. A value of undef is
# treated as a directive to quash all chrooted tags, ostensibly operating on
# the real root filesystem.
sub chroot {
  ref (my $self = shift) or croak "chroot is an instance method";
  if (@_) {
    my $chroot = shift;
    if (defined ($chroot) && (($chroot =~ m/\s+/) || ! ($chroot =~ m/^\//))) {
      croak "Root value invalid " .
            "(contains whitespace or doesn't start with /)";
    } else {
      $self->{ChRoot} = $chroot;
    }
    return ($self);
  } else {
    return ($self->{ChRoot});
  }
}

# Set the Cache instance variable for this object. A value of undef is
# treated as a directive to quash all cache tags, ostensibly operating from
# the local cache.
sub cache {
  ref (my $self = shift) or croak "cache is an instance method";
  if (@_) {
    my $cache = shift;
    if (defined ($cache) && ($cache =~ m/\s+/)) {
      croak "Cache value invalid " .
            "(contains whitespace)";
    } else {
      $self->{Cache} = $cache;
    }
    return ($self);
  } else {
    return ($self->{Cache});
  }
}

# bit of boilerplate for completely handling the #chroot and guaranteeing
# certain properties of the #args tags in *_command_line returned strings.
# Also breaks off the command name for separate handling.
sub command_helper {
  ref (my $self = shift) or croak "command_helper is an instance method";
  my $command_line_helper = shift;

  my ($aggregatable, $cl, $success) = $self->$command_line_helper;
  my @command_line = split /\s+/, $cl;
  my $command = shift @command_line;
  $cl = join (" ", @command_line);
  my $chroot_arg;

  if (defined ($self->{ChRoot})) {
    # substitute value of $ChRoot into implementation's chroot_arg_command_line
    $self->can ('chroot_arg_command_line') or
      croak "Concrete " . __PACKAGE__ . " module doesn't implement method " .
            "chroot_arg_command_line";
    $chroot_arg = $self->chroot_arg_command_line;

    if ($chroot_arg =~ m/#chroot/) {
      # put everywhere #chroot tag is
      $chroot_arg =~ s/#chroot/$self->{ChRoot}/g;
    } else {
      # put on end
      $chroot_arg = $chroot_arg . " " . $self->{ChRoot};
    }

    # substitute value of $chroot_arg into implementations
    if ($cl =~ m/#chroot/) {
      # put everywhere #chroot tag is
      $cl =~ s/#chroot/$chroot_arg/g;
    } elsif ($cl =~ m/#args/) {
      # put in front of first #args tag
      $cl =~ s/#args/$chroot_arg #args/;
    } else {
      # put on end
      $cl = $cl . " " . $chroot_arg;
    }
  } else {
    # just clear $cl of any #chroot tags
    $cl =~ s/#chroot//g;
  }

  if (defined ($self->{Cache})) {
    # substitute value of $Cache into implementation's cache_arg_command_line
    $self->can ('cache_arg_command_line') or
      croak "Concrete " . __PACKAGE__ . " module doesn't implement method " .
            "cache_arg_command_line";
    $cache_arg = $self->cache_arg_command_line;

    if ($cache_arg =~ m/#cache/) {
      # put everywhere #cache tag is
      $cache_arg =~ s/#chroot/$self->{Cache}/g;
    } else {
      # put on end
      $cache_arg = $cache_arg . " " . $self->{Cache};
    }

    # substitute value of $cache_arg into implementations
    if ($cl =~ m/#cache/) {
      # put everywhere #cache tag is
      $cl =~ s/#cache/$cache_arg/g;
    } elsif ($cl =~ m/#args/) {
      # put in front of first #args tag
      $cl =~ s/#args/$cace_arg #args/;
    } else {
      # put on end
      $cl = $cl . " " . $cache_arg;
    }
  } else {
    # just clear $cl of any #cache tags
    $cl =~ s/#cache//g;
  }

  # guarantee that there's a #args tag somewhere
  if (! ($cl =~ m/#args/)) {
    $cl = $cl . " #args";
  }

  return ($aggregatable, $command, $cl, $success);
}

# template for query_requires and query_required_by command operations
sub do_complex_command {
  my $self = shift;
  my $command_name = shift;
  ref ($self) or croak $command_name . " is an instance method";
  $self->can ($command_name . '_command_line') or
    croak "Concrete " . __PACKAGE__ . " module implements neither method " .
	  $command_name . "install nor " . $command_name . "_command_line";

  my @lov = @_;	# list of victims
  my ($aggregatable, $command, $cl) =
    $self->command_helper ($command_name . '_command_line');
  my @dependencies;
  my @captured_output;

  if ($aggregatable) {
    @captured_output = undef;
    my $all_args = join " ", @lov;
    $cl =~ s/#args/$all_args/g;

    my $pid = open(SYSTEM, "-|");
    defined ($pid) or die "can't fork: $!";
    if ($pid) {
      for my $output (<SYSTEM>) {
	if (! $output =~ m/[ \t]+/) {
	  # horrible kludge alert!
	  # assumes any whitespace is an indication of failure
	  # invalid arguments silently ignored
	  chomp $output;
	  push @dependencies, $output;
	}
      }
      close (SYSTEM);
    } else {
      exec ($command, split /\s+/, $cl) or die "can't exec program: $!";
    }
  } else {
    foreach my $package (@lov) {
      @captured_output = undef;
      my $pid = open (SYSTEM, "-|");
      defined ($pid) or die "cannot fork: $!";
      if ($pid) {
	@captured_output = <SYSTEM>;
	chomp @captured_output;
	close (SYSTEM);
      } else {
	my $line = $cl;
	$line =~ s/#args/$package/g;
	exec ($command, split /\s+/, $line) or die "can't exec program: $!";
      }

      push @dependencies, (($? == 0) ? @captured_output : undef);
    }
  }

  return (@dependencies);
}

# Query the underlying dependency manager to report the list of which of the
# package files in the dependency database are required/relied by any of the
# package files in the argument list.
sub query_required_by {
  ref (my $self = shift) or croak "query_required_by is an instance method";
  return ($self->do_complex_command ('query_required_by', @_));
}

# Query the underlying dependency manager to report the list of which of the
# currently installed packages are required/relied on by any of the currently
# installed packages in the argument list.
sub query_requires {
  ref (my $self = shift) or croak "query_requires is an instance method";
  return ($self->do_complex_command ('query_requires', @_));
}

1;
__END__

=head1 NAME

DepMan - Perl extension for Dependency Manager abstraction

=head1 SYNOPSIS

  Constructors

  use DepMan;
  $dm = DepMan->new;

  Concrete package managers will always be available directly as:

  use DepMan::<conc>;
  $dm = <conc>->new;

  use DepMan;
  $dm = DepMan-><conc>;

  use DepMan;
  $dm = DepMan::<conc>->new;

  Currently, the only valid value for <conc> is UpdateRPMs.


  Methods

  $new_dm = $dm->clone;

  $dm->chroot ("/mnt/other_root");
 
  $dm->chroot ("/");    # wrong, will cause chroot argument substitute anyway
  $dm->chroot ("");	# wrong, same reason, but won't even work
  $dm->chroot (undef);  # right, no chroot argument will be used

  my $dm_chroot = $dm->chroot;

  $dm->cache ("/var/cache/update-rpms");
 
  $dm->cache ("");	# wrong, see above
  $dm->cache (undef);	# right, no cache argument will be used

  my $dm_cache = $dm->cache;  

  my @dependencies = $dm->query_requires [<package> ...];

  my @dependencies = $dm->query_required_by [<package> ...];

=head1 ABSTRACT

  DepMan is essentially an abstract class, even though Perl doesn't have
  them. It's expected there will be additional modules under DepMan:: to
  handle concrete dependency managers while DepMan itself acts as the
  front-door API.

=head1 DESCRIPTION

  There are two basic methods on DepMan objects. They are both queries which
  return lists suitable for passing to PackMan->install() or
  PackMan->remove().

  DepMan->query_requires() takes the names of packages, presumably already
  installed, and returns the list of packages, also already installed, which
  require the packages in the arguments. Semanticly, replace "query" with the
  word "what". DepMan->query_requires ('glibc') is the same as asking,
  "DepMan, what requires glibc?". If you actually try this, don't be surprised
  when you get the phone book as output.

  DepMan->query_required_by() takes the names of package files, presumably not
  yet installed, and returns the list of package files, also not yet
  installed, which will be required to be installed before the package files
  in the arguments can be installed. Similar to requires,
  DepMan->query_required_by ('glibc') is the same as asking, "DepMan, what is
  required by glibc?"

  The return values are guaranteed to have the names of all valid arguments.
  Any invalid arguments are silently omitted.

  For suggestions for expansions upon or alterations to this API, don't
  hesitate to e-mail the author. Use "Subject: DepMan: ...".

=head2 EXPORT

  None by default.

=head1 SEE ALSO

  PackMan

=head1 AUTHOR

Matt Garrett, E<lt>magarret@OSL.IU.eduE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2003 The Trustees of Indiana University.
                    All rights reserved.

  This file is part of the OSCAR software package.  For license
  information, see the COPYING file in the top level directory of the
  OSCAR source distribution.

=cut

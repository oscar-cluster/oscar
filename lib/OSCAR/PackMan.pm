package PackMan;

#   Copyright (c) 2003 The Trustees of Indiana University.
#                      All rights reserved.
#
#  This file is part of the OSCAR software package.  For license
#  information, see the COPYING file in the top level directory of the
#  OSCAR source distribution.
#
#  $Id: PackMan.pm,v 1.2 2004/02/17 17:08:29 tuelusr Exp $

use 5.008;
use strict;
use warnings;

use Carp;
use File::Spec;

our $VERSION;
$VERSION = '0.01';
# initial release
$VERSION = '1.1';
# copyright and license cleanup
$VERSION = '1.2';
# more cleanup (mostly docs)

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

# concrete package manager order of preference, for breaking ties on systems
# where multiple package manager modules might claim usability.
# see below
my @preference;

# populated by BEGIN block with keys usable in @preference and values of
# where each PackMan module is located
my %concrete;

my $installed_dir;

# Preloaded methods go here.
BEGIN {
  $installed_dir = "OSCAR";	# ugly hack

# change to qw(RPM Deb) when Deb gets written
# If, by hook or crook, you are on a system where both RPM and Deb (and
# whatever other package managers) will claim usability for a given
# filesystem, rank them in @preference. Recognition as the default package
# manager is on a first-come, first-served basis out of @preference. If no
# default package manager can be determined, all available package managers
# will be consulted in an indeterminant order in a final attempt to find one
# that's usable.
  @preference = qw(RPM Deb);

  my $packman_dir = File::Spec->catdir ($installed_dir,
					split ("::", __PACKAGE__));
  my $full_dir;

  foreach my $inc (@INC) {
    $full_dir = File::Spec->catdir ($inc, $packman_dir);
    if (-d $full_dir) {
      last;
    } else {
      undef ($full_dir);
    }
  }

  defined ($full_dir) or
    croak "No directory of concrete " . __PACKAGE__ .
	  " implementations could be found!";

  opendir (PACKMANDIR, $full_dir) or
    croak "Couldn't access concrete " . __PACKAGE__ . " implementations: $!";

  foreach my $pm (readdir (PACKMANDIR)) {
    # only process .pm files
    if ($pm =~ m/\.pm$/) {
      require File::Spec->catfile ($packman_dir, $pm);
      $pm =~ s/\.pm$//;
      my $module = $packman_dir;
      # Calling isa requires that the installed directory be stripped.
      $module =~ s:^$installed_dir/::;
      $module = join ("::", File::Spec->splitdir ($module)) . "::" . $pm;
      # if it's actually a PackMan module, remember it
      if ("$module"->isa (__PACKAGE__)) {
	$concrete{$pm} = $module;
      }
    }
  }
  closedir (PACKMANDIR);

  scalar %concrete or
    croak "No concrete " . __PACKAGE__ . " implementations could be found!";

  @preference = grep { defined $concrete{$_} } @preference;
}

# AUTOLOAD named constructors for the concrete modules
# Makes PackMan->RPM (<root dir>) do the same as PackMan::RPM->new (<root dir>)
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
  # require'd in the BEGIN block to determine if it's actually a PackMan
  # object.
  ref (shift) and
    croak __PACKAGE__ . " constructor is a class method.";

  foreach my $pm (@preference) {
    if ("$concrete{$pm}"->usable (@_)) {
      # first come, first served
      return ("$concrete{$pm}"->new (@_));
    }
  }
  # Wasn't found among the preferences, second chance, all of %concrete
  # Can this be made more efficient by filtering out all values belonging to
  # modules in @preferences? Perhaps.
  foreach my $pm (values %concrete) {
    if ("$pm"->usable (@_)) {
      return ("$pm"->new (@_));
    }
  }
  # Here, we're solidly S.O.L.
  croak "No usable concrete " . __PACKAGE__ . " module was found.";
}

# "instance constructor", creates a copy of an existing object with instance
# variable values.
sub clone {
  ref (my $self = shift) or croak "clone is an instance method";
  my $new  = { ChRoot => $self->{ChRoot} };
  bless ($new, ref ($self));
  return ($new);
}

# destructor, essentialy to quell some annoying warning messages.
sub DESTROY {
  ref (my $self = shift) or croak "DESTROY is an instance method";
  delete $self->{ChRoot};
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

  # guarantee that there's a #args tag somewhere
  if (! ($cl =~ m/#args/)) {
    $cl = $cl . " #args";
  }

  return ($aggregatable, $command, $cl, $success);
}

# template for install, upgrade, and remove command operations
sub do_simple_command {
  my $self = shift;
  my $command_name = shift;
  ref ($self) or croak $command_name . " is an instance method";
  $self->can ($command_name . '_command_line') or
    croak "Concrete " . __PACKAGE__ . " module implements neither method " .
	  $command_name . "install nor " . $command_name . "_command_line";

  my @lov = @_;	# list of victims
  my ($aggregatable, $command, $cl) =
    $self->command_helper ($command_name . '_command_line');
  my $retval = 0;

  if ($aggregatable) {
    my $all_args = join " ", @lov;
    $cl =~ s/#args/$all_args/g;
    my $pid = fork();
    defined ($pid) or die "can't fork: $!";
    if ($pid) {
      waitpid($pid, 0);
      $retval = $?;
    } else {
      exec ($command, split /\s+/, $cl) or die "can't exec program: $!";
    }
  } else {
    foreach my $package (@lov) {
      my $pid = fork();
      defined ($pid) or die "cannot fork: $!";
      if ($pid) {
        waitpid($pid, 0);
	if ($retval == 0) {
	  $retval = $?;
	}
      } else {
	my $line = $cl;
	$line =~ s/#args/$package/g;
	exec ($command, split /\s+/, $line) or die "can't exec program: $!";
      }
    }
  }

  return ($retval?undef:1);
}

# Command the underlying package manager to install each of the package files
# in the argument list. Returns a failure value if any of the operations
# fails. In non-aggregated mode, all packages which can be installed are
# guaranteed to be installed. In aggregated mode, such guarantee depends on
# the operation of the underlying package manager.
sub install {
  ref (my $self = shift) or croak "install is an instance method";
  return ($self->do_simple_command ('install', @_));
}

# Command the underlying package manager to update/upgrade each of the
# packages in the argument list. Returns a failure value if any of the
# operations fails. In non-aggregated mode, all packages which can be updated
# are guaranteed to be updated. In aggregated mode, such guarantee depends on
# the operation of the underlying package manager.
sub update {
  ref (my $self = shift) or croak "update is an instance method";
  return ($self->do_simple_command ('update', @_));
}

# Command the underlying package manager to remove each of the packages in the
# argument list. Returns a failure value if any of the operations fails. In
# non-aggregated mode, all packages which can be removed are guaranteed to be
# removed. In aggregated mode, such guarantee depends on the operation of the
# underlying package manager.
sub remove {
  ref (my $self = shift) or croak "remove is an instance method";
  return ($self->do_simple_command ('remove', @_));
}

# Query the underlying package manager to report the list of which of the
# packages in the argument list are presently installed and which are
# uninstalled.
sub query_installed {
  ref (my $self = shift) or croak "query_installed is an instance method";
  $self->can ('query_installed_command_line') or
    croak "Concrete " . __PACKAGE__ . " module implements neither method " .
	  "query_installed nor query_installed_command_line";

  my @lop = @_;
  my ($aggregatable, $command, $cl) =
    $self->command_helper ('query_installed_command_line');
  my @installed;
  my @not_installed;
  my @captured_output;

  if ($aggregatable) {
    @captured_output = undef;
    my $all_args = join " ", @lop;
    $cl =~ s/#args/$all_args/g;

    my $pid = open(SYSTEM, "-|");
    defined ($pid) or die "can't fork: $!";
    if ($pid) {
      for my $output (<SYSTEM>) {
	if ($output =~ m/^\w+\s+(\w*)\W/) {
	  # horrible kludge alert!
	  # assumes second whitespace delimited field is our argument name
	  push @not_installed, $1;
	} else {
          chomp $output;
	  push @installed, $output;
	}
      }
      close (SYSTEM);
    } else {
      exec ($command, split /\s+/, $cl) or die "can't exec program: $!";
    }
  } else {
    foreach my $package (@lop) {
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

      if ($? == 0) {
	push @installed, @captured_output;
      } else {
	push @not_installed, $package;
      }
    }
  }

  return (\@installed, \@not_installed);
}

# Query the underlying package manager to report the versions of each of the
# packages listed in the arguments. Order of report/return value corresponds
# to the order of the argument list. undef value means corresponding package
# was not installed.
sub query_version {
  ref (my $self = shift) or croak "query_version is an instance method";
  $self->can ('query_version_command_line') or
    croak "Concrete " . __PACKAGE__ . " module implements neither method " .
	  "query_version nor query_version_command_line";

  my @lop = @_;
  my ($aggregatable, $command, $cl) =
    $self->command_helper ('query_version_command_line');
  my @versions;
  my @captured_output;

  if ($aggregatable) {
    @captured_output = undef;
    my $all_args = join " ", @lop;
    $cl =~ s/#args/$all_args/g;

    my $pid = open(SYSTEM, "-|");
    defined ($pid) or die "can't fork: $!";
    if ($pid) {
      for my $output (<SYSTEM>) {
	if ($output =~ m/[ \t]+/) {
	  # horrible kludge alert!
	  # assumes any whitespace is an indication of failure
	  push @versions, undef;
	} else {
	  chomp $output;
	  push @versions, $output;
	}
      }
      close (SYSTEM);
    } else {
      exec ($command, split /\s+/, $cl) or die "can't exec program: $!";
    }
  } else {
    foreach my $package (@lop) {
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
	#exec ($command, split /\s+/, $line) or die "can't exec program: $!";
	exec ("/bin/sh", "-c", "$command $line") or die "can't exec program: $!";
      }

      push @versions, (($? == 0) ? @captured_output : undef);
    }
  }

  return (@versions);
}

1;
__END__

=head1 NAME

PackMan - Perl extension for Package Manager abstraction

=head1 SYNOPSIS

  Constructors

  use PackMan;
  $pm = PackMan->new;

  Concrete package managers will always be available directly as:

  use PackMan::<conc>;
  $pm = <conc>->new;

  use PackMan;
  $pm = PackMan-><conc>;

  use PackMan;
  $pm = PackMan::<conc>->new;

  Currently, the only valid value for <conc> is RPM.


  Methods

  $new_pm = $pm->clone;

  $pm->chroot ("/mnt/other_root");

  $pm->chroot ("/");	# wrong, will cause chroot argument substitute anyway
  $pm->chroot (undef);	# right, no chroot argument will be used

  my $pm_chroot = $pm->chroot;

  if ($pm->install [<file> ...]) {
    # everything installed fine
  } else {
    # one or more failed to install
  }

  if ($pm->update [<file> ...]) {
    # everything updated fine
  } else {
    # one or more failed to update
  }

  if ($pm->remove [<package> ...]) {
    # everything was removed fine
  } else {
    # one or more failed to get removed
  }

  my ($installed, $not_installed) = $pm->query_installed [<package> ...];
  # $installed and $not_installed are array refs

  my @versions = $pm->query_versions [<package> ...];
  # undef (as a member within the list) means no version of that package was
  # installed

=head1 ABSTRACT

  PackMan is essentially an abstract class, even though Perl doesn't have
  them. It's expected there will be additional modules under PackMan:: to
  handle concrete package managers while PackMan itself acts as the front-door
  API.

=head1 DESCRIPTION

  All constructors take an optional argument of the root directory upon
  which to operate (if different from '/');

  Methods
  The current root can be changed at any time with the chroot() method.

  $pm->chroot ("/mnt/other_root");

  When setting root, another method call may be chained off of it for quick,
  one-off commands:

  PackMan->new->chroot ("/mnt/other_root")->install qw(list of files);

  If you create a PackMan object with an alternative root and want to remember
  that chrooted PackMan:

  $pm = PackMan->new ("/mnt/my_root");
  $chrooted_pm = $pm->clone;

  You can now change $pm back to "/":

  $pm->chroot ("/");	# or $pm->chroot (undef);

  And $chrooted_pm remains pointing at the other directory:

  $chrooted_pm->chroot	# returns "/mnt/my_root"

  All arguments to the chroot method must be absolute paths (begin with "/"),
  and contain no spaces.

  There are five basic methods on PackMan objects. Three are procedures that
  perform an action and return a boolean success condition and two are
  queries.

  The procedures are install, update, and remove. install and update, take a
  list of files as arguments. remove takes a list of packages as its argument.

  Both queries also take a list of packages as their arguments.

  install, update, and remove will install, update, and remove packages from
  the system, as expected. query_installed returns two lists, the first one is
  the list of all packages, from the argument list, that are installed, the
  second, the ones that aren't. query_versions returns a list of the currently
  installed versions all all packages from the argument list, listing the
  version of packages that aren't actually installed as undef.

  For suggestions for expansions upon or alterations to this API, don't
  hesitate to e-mail the author. Use "Subject: PackMan: ...".

=head2 EXPORT

  None by default.

=head1 SEE ALSO

  DepMan

=head1 AUTHOR

Matt Garrett, E<lt>magarret@OSL.IU.eduE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2003 The Trustees of Indiana University.
                    All rights reserved.

  This file is part of the OSCAR software package.  For license
  information, see the COPYING file in the top level directory of the
  OSCAR source distribution.

=cut

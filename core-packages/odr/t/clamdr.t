#   $Header: /home/user5/oscar-cvsroot/oscar/core-packages/odr/t/Attic/clamdr.t,v 1.3 2001/08/30 14:57:06 sdague Exp $

#   Copyright (c) 2001 International Business Machines

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#   Greg Geiselhart <geiselha@us.ibm.com>

use Test;
use FindBin qw($Bin);

my $path = $ENV{PATH};
$ENV{PATH} .= ":$Bin/../bin";

$ENV{CLAMDRHOME} = $ENV{PWD} . "/data";

print STDERR $ENV{CLAMDRHOME}, "\n";

BEGIN {
    plan tests => 1;
}

END {
    $ENV{PATH} = $path;
}

sub execute {
    my ($cmd, @params) = @_;
    my @output;
    open(PIPE, "$cmd @params |") or die "could not execute $cmd: $!\n";
    local $_;
    while (<PIPE>) {
	chomp;
	push @output, $_;
    }
    close PIPE;
    return @output;
}
my @out = execute("readDR.pl service NAME=PBS");
ok $out[0], '/HOST=node3.csm.ornl.gov/';

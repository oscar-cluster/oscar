package OSCAR::FileUtils;

# Copyright (C) 2007    Oak Ridge National Laboratory
#                       Geoffroy Vallee <valleegr@ornl.gov>
#                       All rights reserved.
#
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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  US

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            add_line_to_file_without_duplication
            get_directory_content
            );

################################################################################
# Add a line into a file only if the line is not already present. Note that if #
# the file does not exist, we create it.                                       #
#                                                                              #
# Input: line, the line to add into the file.                                  #
#        file, file in which we want to add a line.                            #
# return: 0 if success, -1 else.                                               #
################################################################################
sub add_line_to_file_without_duplication ($$) {
    my ($line, $file_path) = @_;

    open (DAT, ">>$file_path") 
        or (print "ERROR: Impossible to open the file: $file_path." 
            && return -1);
    if (find_line_in_file($line, $file_path) == -1) {
        print (DAT "$line\n");
    }
    close (DAT);
    return 0;
}

################################################################################
# Check if a given line is already in the file.                                #
#                                                                              #
# Input: - line, the line to look for,                                         #
#        - file_path, the file to look into.                                   #
# Return: -1 if the line is not in the file,                                   #
#         the line number if the line is already in the file.                  #
################################################################################
sub find_line_in_file ($$) {
    my ($line, $file_path) = @_;
    open (FILE, $file_path)
        or die "Impossible to open the file: $file_path.";
    my $pos=0;
    foreach my $l (<FILE>) {
        chomp($l);
        if ($l eq $line) {
            return $pos;
        } 
        $pos += 1;
    }
    close (FILE);
    return -1;
}

################################################################################
# Descr: Read the content of a given directory.                                #
#                                                                              #
# Input: Path of the directory he need to scan.                                #
# Return: list of files and directories, ignoring those starting with a dot.   #
#                                                                              #
# NOTE: Not fully qualify path in returned file list so caller can             #
#       easily get at filenames and directory names.                           #
#                                                                              #
# TODO: code duplication with functions in FileUtils                           #
################################################################################
sub get_directory_content ($)
{
    my $dir = shift;

    opendir(DIR, "$dir") or return undef;

    # RegEx: ignore all files starting with a dot, 
    #        e.g., ".", "..", ".foobar"
    my @files = grep { !/^\./ } readdir(DIR);

    closedir(DIR);

    return(@files);
}

package OSCAR::FileUtils;

# Copyright (C) 2007-2009 Oak Ridge National Laboratory
#                         Geoffroy Vallee <valleegr at ornl dot gov>
#                         All rights reserved.
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

#
# $Id$
#

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::Defs;
use OSCAR::Logger;
use File::Basename;
use File::Path;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            add_line_to_file_without_duplication
            download_file
            file_type
            get_line_in_file
            generate_empty_xml_file
            get_directory_content
            get_dirs_in_path
            get_files_in_path
            line_in_file
            parse_xmlfile
            replace_line_in_file
            );

my $verbose = $ENV{OSCAR_VERBOSE};

sub get_line_in_file ($$) {
    my ($file, $pos) = @_;

    my $i = 0;
    open (FILE, $file) or (carp "ERROR: Impossible to open $file",
                           return undef);
    my $line;
    while ($line = <FILE>) {
        if ($i == $pos) {
            return $line;
        }
        $i++;
    }
    close (FILE);

    return undef;
}

sub file_type ($) {
    my $file = shift;

    if (! -f $file) {
        carp "ERROR: the file does not exist ($file)";
        return undef;
    }
    return OSCAR::Defs::TARBALL() if $file =~ m/\.tar\.gz$/;

    my $type = `file $file`;
    return OSCAR::Defs::SRPM() if $type =~ m/RPM v3 src/;

    return undef;
}

sub download_file ($$$$) {
    my ($source, $dest, $method, $overwrite) = @_;
    my $cmd;

    if ($method eq "wget") {
        $cmd = "cd $dest; wget ";
        $cmd .= "-nc " if ($overwrite eq OSCAR::Defs::NO_OVERWRITE());
        $cmd .= "$source";
        my $rc = system ($cmd);
        # It seems that the wget return code for errors is 1. Note that other 
        # values > 0 are returned in some specific case which are not 
        # necessarily errors.
        if ($rc == 1) {
            carp "ERROR: Impossible to download $source ($cmd, rc: $rc)";
            return -1;
        }
    } else {
        carp "ERROR: Unknown method to get sources ($method)";
        return -1;
    }
    return 0;
}

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

    print "---> Adding $line to $file_path\n" if $verbose;
    my $dirname = File::Basename::dirname ($file_path);
    if ( ! -d $dirname) {
        File::Path::mkpath ($dirname) 
            or (carp ("ERROR: Impossible to create $dirname"), return -1);
    }
    require OSCAR::Utils;
    if (!OSCAR::Utils::is_a_valid_string ($line)) {
        carp "ERROR: Invalid string";
        return -1;
    }
    open (DAT, ">>$file_path") 
        or (carp "ERROR: Impossible to open the file: $file_path.",
            return -1);
    if (line_in_file($line, $file_path) == -1) {
        print DAT "$line";
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
sub line_in_file ($$) {
    my ($line, $file_path) = @_;
    open (FILE, $file_path)
        or die "Impossible to open the file: $file_path.";
    my $pos=0;
    chomp ($line);
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

sub replace_line_in_file ($$$) {
    my ($file, $line_number, $new_line) = @_;

    chomp ($new_line);
    open (FILE, "$file")
        or (carp "ERROR: Impossible to open $file", return -1);
    # First we create the content of the new file into an array
    my @content;
    my $pos = 0;
    my $line;
    while ($line = <FILE>) {
        if ($pos != $line_number) {
            push (@content, "$line");
        } else {
            push (@content, "$new_line\n");
        }
        $pos++;
    }
    close (FILE);
    open (FILE, ">$file")
        or (carp "ERROR: Impossible to open $file", return -1);
    # Then we write the file
    foreach $line (@content) {
        print FILE $line;
    }
    close (FILE);

    return 0;
}

################################################################################
# Descr: Read the content of a given directory.                                #
#                                                                              #
# Input: Path of the directory he need to scan.                                #
# Return: list of files and directories, ignoring those starting with a dot.   #
#                                                                              #
# NOTE: Not fully qualify path in returned file list so caller can             #
#       easily get at filenames and directory names.                           #
################################################################################
sub get_directory_content ($) {
    my $dir = shift;

    opendir(DIR, "$dir") or return undef;

    # RegEx: ignore all files starting with a dot, 
    #        e.g., ".", "..", ".foobar"
    my @files = grep { !/^\./ } readdir(DIR);

    closedir(DIR);

    return(@files);
}

################################################################################
# Gives the list of files within a given directory.                            #
#                                                                              #
# Input: Path of the directory we need to scan.                                #
# Return: list of files.                                                       #
#                                                                              #
# NOTE: Not fully qualify path in returned file list so caller can             #
#       easily get at filenames and directory names.                           #
################################################################################
sub get_files_in_path ($) {
    my $dir = shift;

    if (!defined ($dir) || ! -d $dir) {
        carp "ERROR: unvalid directory ($dir)\n";
        return undef;
    }
    my @dir_content = get_directory_content ("$dir");
    my @dirs;
    foreach my $entry (@dir_content) {
        my $path = "$dir/$entry";
        if ( ! -d "$path") {
            push (@dirs, $entry);
        }
    }
    return (@dirs);
}

################################################################################
# Get the list of directories within a given directory.                        #
#                                                                              #
# Input: dir, directory we want to scan.                                       #
# Return: list of directories (absolute path) or undef if error.               #
################################################################################
sub get_dirs_in_path ($) {
    my $dir = shift;

    if (!defined ($dir) || ! -d $dir) {
        carp "ERROR: unvalid directory ($dir)\n";
        return undef;
    }
    my @dir_content = get_directory_content ("$dir");
    my @dirs;
    foreach my $entry (@dir_content) {
        my $path = "$dir/$entry";
        if ( -d "$path") {
            push (@dirs, $entry);
        }
    }
    return (@dirs);
}

################################################################################
# Parse the config.xml file for a specific OPKG.                               #
#                                                                              #
# Parameters: package directory,                                               #
#             package_name,                                                    #
#             message, an extra string that is printed during debugging.       #
# Return:     representation of the config.xml file (XMLSimple) if success,    #
#             undef else.                                                      #
################################################################################
sub parse_xmlfile ($) {
    my ($xmlfile_path) = @_;

    my $xml_ref = undef;
    if ( ! -f $xmlfile_path ) {
        oscar_log_subsection ("ERROR: the file ($xmlfile_path) does not ".
                              " exists\n");
        return undef;
    } else {
        oscar_log_subsection ("Processing $xmlfile_path...");
        require XML::Simple;
        my $xs = new XML::Simple();
        $xml_ref = eval { $xs->XMLin( $xmlfile_path ); };
        if ($@) {
            carp "ERROR: $xmlfile_path is invalid\n";
            $xml_ref = undef;
            oscar_log_subsection ("Trying to xmllint the $xmlfile_path to show ".
                                  "problems:\n");
            system "xmllint $xmlfile_path";
        }
    }

    return $xml_ref;
}

################################################################################
# Generate an empty XML file (only the header is created within the file so    #
# it is possible to parse the file even empty).                                #
#                                                                              #
# Input: the absolute path of the file to be created.                          #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub generate_empty_xml_file ($$) {
    my ($file, $debug) = @_;

    if (!OSCAR::Utils::is_a_valid_string ($file)) {
        carp "ERROR: Invalid file name";
        return -1;
    }

    if (-f $file) {
        print "[INFO] The file ($file) already exists\n" if $debug;
        return 0;
    }

    print "[INFO] Creating the file $file\n" if $debug;
    open (FILE, ">$file") or (carp "can't open $file $!", return -1);
    print FILE "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
    print FILE "<opt/>";
    close (FILE);
    return 0;
}

1;


__END__

=head1 DESCRIPTION

A set of usefull functions for the manipulation of files. This package is designed to avoid code duplication.

=head1 Exported Functions

=over 4

=item add_line_to_file_without_duplication

Add a line into a file and make sure the line appears only one.
add_line_to_file_without_duplication($line, $file);

=item download_file

=item file_type

=item generate_empty_xml_file

=item get_directory_content

=item get_dirs_in_path

=item get_files_in_path

=item get_line_in_file

=item line_in_file

Check if a given line is already in the file: 
my $pos = line_in_file ($line, $file_path). 
Return -1 if the line is not in the file or return the line position.

=item parse_xmlfile

=item replace_line_in_file

replace_line_in_file ($file, $line_number, $new_line). Returns 0 if success, -1
else.

=back

=cut

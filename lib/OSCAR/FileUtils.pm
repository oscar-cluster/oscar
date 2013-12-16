package OSCAR::FileUtils;

# Copyright (C) 2007-2010 Oak Ridge National Laboratory
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
use Switch;
use OSCAR::Defs;
use OSCAR::Logger;
use File::Basename;
use File::Path;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            add_line_to_file_without_duplication
            add_to_annoted_block
            backup_file_if_not_exist
            download_file
            extract_file
            file_type
            find_block_from_file
            get_line_in_file
            generate_empty_xml_file
            get_directory_content
            get_dirs_in_path
            get_files_in_path
            line_in_file
            parse_xmlfile
            remove_from_annoted_block
            replace_block_in_file
            );

our $verbose = $ENV{OSCAR_VERBOSE};

################################################################################
# Crate a backup of a file with .oscarbak extention in the same directory if   #
# file.bak is not already there. (avoid overwriting the real back upon multiple#
# runs                                                                         #
#                                                                              #
# Parameter: file to backup                                                    #
#                                                                              #
# return:    1 If success (backup created or already exists).                  #
#            0 else.(Same behavior as File::Copy:copy)                         #
################################################################################
sub backup_file_if_not_exist($) {
    my $file = shift;
    if ( -e $file ) {
        if ( -e "$file.oscarbak" ) {
            OSCAR::Logger::oscar_log_subsection("[INFO] $file not backed up. (backup already exists)");
            return 1;
        } else {
            my $cmd = "/bin/cp -f $file $file.oscarbak";
            if (system ($cmd)) {
                carp "ERROR: ($!) Impossible to execute $cmd";
                OSCAR::Logger::oscar_log_subsection("ERROR: Failed to backup $file. [$cmd => $!]");
                return 0;
            } else {
                OSCAR::Logger::oscar_log_subsection("[INFO] $file backed up as $file.oscarbak.");
                return 1;
            }
        }
    } else {
        carp ("ERROR: File not found: $file");
    }
}

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
    return OSCAR::Defs::TARBALL() if $file =~ m/\.tar\.gz$/ or $file =~ m/\.tgz$/ or $file =~ m/\.tar\.bz2$/ or $file =~ m/\.tar\.xz$/;

    my $type = `file $file`;
    return OSCAR::Defs::SRPM() if $type =~ m/RPM v[1-9][0-9]*\.?[0-9]* src$/;

    return undef;
}

sub download_file ($$$$) {
    my ($source, $dest, $method, $overwrite) = @_;
    my $cmd;

    OSCAR::Logger::oscar_log_subsection ("Downloading $source to $dest");

    if ( ! -d $dest) {
        File::Path::mkpath ($dest) 
            or (carp "ERROR: Impossible to create $dest", return -1);
    }

    if ($method eq "wget") {
        $cmd = "cd $dest; wget ";
        $cmd .= "-nc " if ($overwrite eq OSCAR::Defs::NO_OVERWRITE());
        $cmd .= "$source";
        $cmd .= " 1>/dev/null 2>/dev/null" if (!$verbose);
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
# Extract an archive using adequate command                                    #
################################################################################
sub extract_file ($$) {
    my ($file,$destination) = @_;
    my $verbose_switch="";
    my $compression_switch="";
    my $cmd="";
    switch (file_type($file)) {
        case OSCAR::Defs::TARBALL() {
            $verbose_switch="v" if ($verbose > 0);
            switch ($file) {
                case /\.gz|\.tgz/ { $compression_switch = "z"; }
                case /\.bz2|\.tbz/ { $compression_switch = "j"; }
                case /\.xz/ { $compression_switch = "J"; }
                else { $compression_switch = ""; }
            }
            $cmd="tar x".$verbose_switch.$compression_switch."Cf ".$destination." ".$file;
        } else {
                carp "ERROR: Unhandled archive type: for $file";
                return -1;
        }
    }
    oscar_log_subsection "Extracting $file using: $cmd";
    my $rc = system ($cmd);
    if ($rc) {
        carp "ERROR: ($rc) Failed to execute: $cmd\n";
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

    OSCAR::Logger::oscar_log_subsection "Adding $line to $file_path";
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

    if (-f $file_path) {
        open (DAT, ">>$file_path") 
            or (carp "ERROR: Impossible to open the file: $file_path.",
                return -1);
    } else {
        open (DAT, ">$file_path")
            or (carp "ERROR: Impossible to open the file: $file_path.",
                return -1);
    }
    if (line_in_file($line, $file_path) == -1) {
        print DAT "$line" 
            or (carp "ERROR: Impossible to write in $file_path", return -1);
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

    if (!defined $new_line) {
        return 0;
    }
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

sub add_line_to_file_at ($$$);

sub add_line_to_file_at ($$$) {
    my ($file, $line, $pos) = @_;

    my $current_line = get_line_in_file ($file, $pos);
    if (!defined $current_line) {
        open (DAT, ">>$file");
        print DAT "$line";
        close (DAT);
    } else {
        if (add_line_to_file_at ($file, $current_line, $pos+1)) {
            carp "ERROR: Impossible to add $current_line at $pos+1 in $file";
            return -1;
        }
        if (replace_line_in_file ($file, $pos, $line)) {
            carp "ERROR: Inpossible to replace line $pos in $file";
            return -1;
        }
    }

    return 0;   
}

sub remove_line_from_file_at ($$) {
    my ($file, $pos) = @_;
    my @lines;

    # We get the content of the file and update it
    open (DAT, $file) 
        or (carp "ERROR: Impossible to open $file", return -1);
    @lines = <DAT>;
    close (DAT);
    if (scalar (@lines) < $pos) {
        # The line is not exist, we successfully exist
        return 0;
    }
    delete $lines[$pos];

    # We overwrite the file.
    open (DAT, ">$file") or (carp "ERROR: Impossible to open $file", return -1);
    for (my $i = 0; $i < scalar (@lines); $i++) {
        if (defined $lines[$i]) {
            print DAT $lines[$i];
        }
    }
    close (DAT);

    return 0;
}

sub replace_block_in_file ($$$) {
    my ($file, $block_name, $data) = @_;

    if (!defined $data || ref ($data) ne "ARRAY") {
        carp "ERROR: Invalid block data";
        return -1;
    }

    if (!defined $block_name) {
        carp "ERROR: Undefined block name";
        return -1;
    }

    if (!defined $file || ! -f $file) {
        carp "ERROR: Invalid file";
        return -1;
    }

    my $new_block_length = 0;
    # The data array may have undefined elements so to get the size we need to 
    # go through the array.
    foreach my $elt (@$data) {
        if (OSCAR::Utils::is_a_valid_string ($elt)) {
            $new_block_length++;
        }
    } 
    my $block_pos_end = -1;
    my $block_pos_begin = line_in_file ("# OSCAR block: $block_name", $file);

    if ($block_pos_begin != -1) {
        $block_pos_end = line_in_file ("# OSCAR block end: $block_name", $file);
        if ($block_pos_end == -1) {
            carp ("ERROR: Begining of block found but not the end");
            return undef;
        }

        my $block_size = $block_pos_end - $block_pos_begin -1;
        if ($new_block_length > ($block_size)) {
            my $i = 0;
            my $written_elts = 0;
            my $diff_size = $new_block_length - $block_size;
            while ($written_elts < $block_size) {
                if (OSCAR::Utils::is_a_valid_string ($data->[$i])) {
                    my $l = OSCAR::Utils::trim ($data->[$i]);
                    replace_line_in_file ($file,
                                          ($block_pos_begin + 1 + $written_elts),
                                          $l);
                    $written_elts++;
                }
                $i++;
            }
            my $j = 0;
            while ($written_elts < $new_block_length) {
                if (OSCAR::Utils::is_a_valid_string ($data->[$i+$j])) {
                    my $l = OSCAR::Utils::trim ($data->[$i+$j]);
                    add_line_to_file_at ($file, 
                                         $l,
                                         ($block_pos_begin + 1 + $written_elts));
                    $written_elts++;
                }
                $j++;
            }
        } elsif ($new_block_length == $block_size) {
            my $written_elts = 0;
            my $i = 0;
            while ($written_elts < $block_size) {
                if (OSCAR::Utils::is_a_valid_string ($data->[$i])) {
                    my $l = OSCAR::Utils::trim ($data->[$i]);
                    replace_line_in_file ($file,
                                          ($block_pos_begin + 1 + $written_elts),
                                          $l);
                    $written_elts++;
                }
                $i++;
            }
        } else {
            my $i = 0;
            my $written_elts = 0;
            while ($written_elts < $new_block_length) {
                if (OSCAR::Utils::is_a_valid_string ($data->[$i])) {
                    my $l = OSCAR::Utils::trim ($data->[$i]);
                    if ($l ne "") {
                        replace_line_in_file ($file,
                                              ($block_pos_begin + 1 + $written_elts),
                                              $l);
                        $written_elts++;
                    }
                }
                $i++;
            }
            my $pos = $block_pos_begin + 1 + $written_elts;
            while ($written_elts < $block_size) {
                remove_line_from_file_at ($file, $pos);
                $written_elts++;
            }
        }
    } else {
        open (DAT, ">>$file")
            or (carp "ERROR: Impossible to open the file: $file.", return -1);
        print DAT "# OSCAR block: $block_name\n";
        for (my $i = 0; $i < scalar (@$data); $i++) {
            print DAT $data->[$i]."\n" 
                if (OSCAR::Utils::is_a_valid_string ($data->[$i]));
        }
        print DAT "# OSCAR block end: $block_name\n";
        close (DAT);
    }

    return 0;
}

sub find_block_from_file ($$$) {
    my ($file, $block_name, $res_ref) = @_;
    my $block_pos_end = -1;
    my $block_pos_begin = line_in_file ("# OSCAR block: $block_name", $file);

    if ($block_pos_begin != -1) {
        $block_pos_end = line_in_file ("# OSCAR block end: $block_name", $file);
        if ($block_pos_end == -1) {
            carp ("ERROR: Begining of block found but not the end");
            return -1;
        }

        my $line;
        # We have now the begining and the end of the block
        for (my $i = $block_pos_begin+1; $i < $block_pos_end; $i++) {
            $line = get_line_in_file ($file, $i);
            if (OSCAR::Utils::is_a_valid_string ($line)) {
                push (@$res_ref, $line);
            } 
        }
    }

    return 0;
}

sub add_to_annoted_block ($$$$) {
    my ($file, $block_name, $line, $dup) = @_;
    
    my @data = ();

    if (find_block_from_file ($file, $block_name, \@data)) {
        carp "ERROR: Impossible to get block $block_name from $file";
        return -1;
    }

    require OSCAR::Utils;
    if ($dup == 0) {
        my $i = 0;
        # We check if the line is already there
        while (OSCAR::Utils::trim ($data[$i]) ne OSCAR::Utils::trim ($line)
               && $i < scalar (@data)) {
            $i++;
        }
        if (OSCAR::Utils::trim ($data[$i]) eq OSCAR::Utils::trim ($line)) {
            # The line is already there so we exit successfully
            return 0;
        }
    }
    push (@data, "$line");

    if (replace_block_in_file ($file, $block_name, \@data)) {
        carp "ERROR: Impossible to replace block $block_name in $file";
        return -1;
    }

    return 0;
}

sub remove_from_annoted_block ($$$) {
    my ($file, $block_name, $line) = @_;

    my @data = ();
    if (find_block_from_file ($file, $block_name, \@data)) {
        # The block does not exist, we exit successfully.
        return 0;
    }

    my $i = 0;
    my $stop_loop = 0;
    while ($stop_loop == 0) {
        if (OSCAR::Utils::trim($data[$i]) eq OSCAR::Utils::trim($line)) {
            $stop_loop = 1;
        } elsif ($i == scalar (@data)) {
            $stop_loop = 2;
        } else {
            $i++;
        }
    }

    if ($stop_loop == 1) {
        # We found the line in the block
        delete $data[$i];
        if (replace_block_in_file ($file, $block_name, \@data)) {
            carp "ERROR: Impossible to replace block $block_name in $file";
            return -1;
        }
    } 

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

=item backup_file_if_not_exist

returns 1 if backup file created or already exists, 0 else.

=item download_file

download_file ($source, $dest, $method, $overwrite)
overwrite can have the two following values: OSCAR::Defs::NO_OVERWRITE() or OSCAR::Defs::OVERWRITE()

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

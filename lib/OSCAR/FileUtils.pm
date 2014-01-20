package OSCAR::FileUtils;

# Copyright (C) 2007-2010 Oak Ridge National Laboratory
#                         Geoffroy Vallee <valleegr at ornl dot gov>
#                         All rights reserved.
# Copyright (C) 1013-1014 Commissariat a lEnergie Atomique 
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
use OSCAR::LoggerDefs;
use OSCAR::Utils;
use OSCAR::Env;
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

=encoding utf8

=head1 NAME

OSCAR::FileUtils - A set of usefull functions for the manipulation of files.

=head1 SYNOPSIS

use OSCAR::FileUtils;

=head1 DESCRIPTION

A set of usefull functions for the manipulation of files.E<10>
This package is designed to avoid code duplication.

=head2 Functions

=over 4

=cut
################################################################################
=item backup_file_if_not_exist()

Create a backup of a file with .oscarbak extention in the same directory if
file.bak is not already there. (avoid overwriting the real back upon multiple
runs

 Input:  file to backup
Return:  1: If success (backup created or already exists).
         0: else.(Same behavior as File::Copy:copy)

Exported: YES
=cut
################################################################################
sub backup_file_if_not_exist($) {
    my $file = shift;
    if (!OSCAR::Utils::is_a_valid_string($file)) {
        oscar_log(5, ERROR, "Invalid or undefined filename. Can't create a backup of it.");
    }
    if ( -e $file ) {
        if ( -e "$file.oscarbak" ) {
            oscar_log(6, INFO, "$file not backed up. (backup already exists)");
            return 1;
        } else {
            my $cmd = "/bin/cp -f $file $file.oscarbak";
            if (system ($cmd)) {
                oscar_log(7, ERROR, "($!) Impossible to execute $cmd");
                oscar_log(5, ERROR, "Failed to backup $file.");
                return 0;
            } else {
                oscar_log(6, INFO, "$file backed up as $file.oscarbak");
                return 1;
            }
        }
    } else {
        oscar_log (5, ERROR, "Can't backup $file: File not found.");
    }
}

################################################################################
=item get_line_in_file()

Get the content of a line given it's number

 Input:  file
         line number
Return:  line content if success
         undef otherwise

Exported: YES
=cut
################################################################################
sub get_line_in_file ($$) {
    my ($file, $pos) = @_;

    my $i = 0;

    if (! defined $pos) {
        oscar_log(5, ERROR, "Undefined position. Don't know while line to extract from file");
        return undef;
    }
    if (!OSCAR::Utils::is_a_valid_string($file)) {
        oscar_log(5, ERROR, "Invalid or undefined filename. Can't get line #$pos from it.");
        return undef;
    }
    open (FILE, $file) or (oscar_log(5, ERROR, "Impossible to open $file"),
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

################################################################################
=item file_type()

check if file is a tarball or a source rpm.

 Input:  file
Return:  TARBALL|SRPM if success. (See L<OSCAR::Defs>)
         undef otherwise.

Exported: YES
=cut
################################################################################
sub file_type ($) {
    my $file = shift;

    if (! -f $file) {
        oscar_log(5, ERROR, "File not found ($file)");
        return undef;
    }
    return OSCAR::Defs::TARBALL() if $file =~ m/\.tar\.gz$/ or $file =~ m/\.tgz$/ or $file =~ m/\.tar\.bz2$/ or $file =~ m/\.tar\.xz$/;

    my $type = `file $file`;
    return OSCAR::Defs::SRPM() if $type =~ m/RPM v[1-9][0-9]*\.?[0-9]* src$/;

    return undef;
}

################################################################################
=item download_file()

Download a file from given url into destination.

 Input:     $source: Source URL
              $dest: Destination directory
            $method: "wget" (no other method supported yet)
         $overwrite: OVERWRITE|NO_OVERWRITE  (See L<OSCAR::Defs>)
Return:   0: Success.
         -1: otherwise.

Exported: YES
=cut
################################################################################
sub download_file ($$$$) {
    my ($source, $dest, $method, $overwrite) = @_;
    my $cmd;

    oscar_log(5, ACTION, "Downloading $source to $dest");

    if ( ! -d $dest) {
        File::Path::mkpath ($dest) 
            or (oscar_log(5, ERROR, "Impossible to create $dest"), return -1);
    }

    if ($method eq "wget") {
        $cmd = "cd $dest; wget ";
        $cmd .= "-nc " if ($overwrite eq OSCAR::Defs::NO_OVERWRITE());
        $cmd .= "$source";
        $cmd .= " 1>/dev/null 2>/dev/null" if ($OSCAR::Env::oscar_verbose < 6);

        oscar_log(7, ACTION, "About to run: $cmd");
        my $rc = system ($cmd);
        # It seems that the wget return code for errors is 1. Note that other 
        # values > 0 are returned in some specific case which are not 
        # necessarily errors.
        if ($rc == 1) {
            oscar_log(5, ERROR, "Failed to download $source.");
            oscar_log(6, ERROR, "     : ($cmd, rc: $rc)");
            return -1;
        }
    } else {
        oscar_log(6, ERROR, "Unknown method to get sources ($method)");
        return -1;
    }
    return 0;
}

################################################################################
=item extract_file()

Extract an archive using adequate command

 Input:        $file: file to extract
        $destination: Destination to extract to.
Return:   0: Success.
         -1: otherwise.

Exported: YES
=cut
################################################################################
sub extract_file ($$) {
    my ($file,$destination) = @_;
    my $verbose_switch="";
    my $compression_switch="";
    my $cmd="";

    oscar_log(5, ACTION, "Extracting $file");

    switch (file_type($file)) {
        case OSCAR::Defs::TARBALL() {
            $verbose_switch="v" if ($OSCAR::Env::oscar_verbose >= 6);
            switch ($file) {
                case /\.gz|\.tgz/ { $compression_switch = "z"; }
                case /\.bz2|\.tbz/ { $compression_switch = "j"; }
                case /\.xz/ { $compression_switch = "J"; }
                else { $compression_switch = ""; }
            }
            $cmd="tar x".$verbose_switch.$compression_switch."Cf ".$destination." ".$file;
        } else {
                oscar_log(6, ERROR, "Unhandled archive type: for $file");
                return -1;
        }
    }
    oscar_log(7, ACTION, "About to run: $cmd");
    my $rc = system ($cmd);
    if ($rc) {
        oscar_log(5, ERROR, "Failed to extract $file");
        oscar_log(7, ERROR, "\\__ Return code: $rc");
        return -1;
    }
    return 0;
}

################################################################################
=item add_line_to_file_without_duplication()

Add a line into a file only if the line is not already present.
Note that if the file does not exist, we create it.

 Input:      $line: Line to be added.
        $file_path: File in which we want to add a line.
Return:   0: Success.
         -1: otherwise.

Exported: YES
=cut
################################################################################
sub add_line_to_file_without_duplication ($$) {
    my ($line, $file_path) = @_;

    if (!OSCAR::Utils::is_a_valid_string($file_path)) {
        oscar_log(5, ERROR, "Invalid or undefined filename. Can't Add line to file.");
        return undef;
    }
    if (!OSCAR::Utils::is_a_valid_string($line)) {
        oscar_log(5, ERROR, "Invalid or undefined string; $file_path unmodified.");
        return undef;
    }

    my $msg_line = $line;
    chomp($msg_line);

    oscar_log(5, INFO, "About to add \"$msg_line\" to $file_path");

    my $dirname = File::Basename::dirname ($file_path);
    if ( ! -d $dirname) {
        oscar_log(6, ACTION, "Directory $dirname does not exists: creating it.");
        File::Path::mkpath ($dirname) 
            or (oscar_log(5, ERROR, "Failed to create $dirname"), return -1);
    }

    if (-f $file_path) {
        open (DAT, ">>$file_path") 
            or (oscar_log(5, ERROR, "Impossible to open the file: $file_path for appending."),
                return -1);
    } else {
        open (DAT, ">$file_path")
            or (oscar_log(5, ERROR, "Impossible to open the file: $file_path for writing"),
                return -1);
    }
    if (line_in_file($line, $file_path) == -1) {
        oscar_log(6, ACTION, "Adding \"$msg_line\" to $file_path");
        print DAT "$line" 
            or (oscar_log(5, ERROR, "Impossible to write in $file_path\n"), return -1);
    } else {
        oscar_log(6, INFO, "Line already present in file. File unmodified.");
    }
    close (DAT);

    return 0;
}

################################################################################
=item line_in_file()

Check if a given line is already in the file.

 Input:      $line: the line to look for.
        $file_path: the file to look into.
Return:  -1:  Line is not in the file (or if file can't be accessed)
         The line number otherwise

Exported: YES
=cut
################################################################################
sub line_in_file ($$) {
    my ($line, $file_path) = @_;
    open (FILE, $file_path)
        or (oscar_log(5, ERROR, "Impossible to open the file: $file_path."), return -1);
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

################################################################################
=item replace_line_in_file()

Replace a line in a file at a given position.

 Input:        $file: The file we're working on
        $line_number: The line number to be replaced
           $new_line: The new line content.
Return:  -1: Failure
          0: Success

Exported: YES
=cut
################################################################################
sub replace_line_in_file ($$$) {
    my ($file, $line_number, $new_line) = @_;


    if (!OSCAR::Utils::is_a_valid_string($file)) {
        oscar_log(5, ERROR, "Invalid or undefined filename. Can't Replace a line in file.");
        return -1;
    }
    if (! defined $line_number) {
        oscar_log(5, ERROR, "Undefined line number. Can't Replace a line in file.");
        return -1;
    }

    # nothing to replace, this is fine.(return 0)
    if (!defined $new_line) {
        return 0;
    }

    oscar_log(5, INFO, "About to replace line into $file");

    chomp ($new_line);
    open (FILE, "$file")
        or (oscar_log(5, ERROR, "Impossible to open $file."), return -1);
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

    oscar_log(6, ACTION, "Replacing line #$line_number with \"$line\" into $file");
    open (FILE, ">$file")
        or (oscar_log(5, ERROR, "Impossible to open $file."), return -1);
    # Then we write the file
    foreach $line (@content) {
        print FILE $line;
    }
    close (FILE);

    return 0;
}

################################################################################
=item get_directory_content()

Read the content of a given directory.

 Input: $dir: Path of the directory we need to scan.
Return:  undef on failure
         array of files and directories, ignoring those starting with a dot.

Exported: YES
=cut
################################################################################
sub get_directory_content ($) {
    my $dir = shift;

    if (!OSCAR::Utils::is_a_valid_string($dir)) {
        oscar_log(5, ERROR, "Invalid or undefined directory name. Can't get its content.");
        return undef;
    }
    opendir(DIR, "$dir")
        or (oscar_log(5, ERROR, "Failed to access to $dir. Can't get its content."), return undef);

    # RegEx: ignore all files starting with a dot, 
    #        e.g., ".", "..", ".foobar"
    my @files = grep { !/^\./ } readdir(DIR);

    closedir(DIR);

    return(@files);
}

################################################################################
=item get_files_in_path()

Gives the list of files (excluding subdirs) within a given directory.
NOTE: Not fully qualify path in returned file list so caller can
      easily get at filenames and directory names.

 Input: $dir: Path of the directory we need to scan.
Return:  undef on failure.
         array of files.

Exported: YES
=cut
################################################################################
sub get_files_in_path ($) {
    my $dir = shift;

    if (!defined ($dir) || ! -d $dir) {
        oscar_log(6, ERROR, "Invalid directory ($dir)");
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
=item get_dirs_in_path()

Get the list of directories within a given directory.

 Input: $dir: Path of the directory we need to scan.
Return:  undef on failure.
         array of subdirs (absolute path).

Exported: YES
=cut
################################################################################
sub get_dirs_in_path ($) {
    my $dir = shift;

    if (!defined ($dir) || ! -d $dir) {
        oscar_log(6, ERROR, "Invalid directory ($dir)");
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
=item parse_xmlfile()

Parse the config.xml file for a specific OPKG.

 Input: xmlfile_path: Path of the config.xml file
Return:  undef on failure.
         representation of the config.xml file (XMLSimple) if success

Exported: YES
=cut
################################################################################
sub parse_xmlfile ($) {
    my ($xmlfile_path) = @_;

    my $xml_ref = undef;
    if (!OSCAR::Utils::is_a_valid_string ($xmlfile_path)) {
        oscar_log(6, ERROR, "Invalid config.xml file name.");
        return undef;
    }
    if ( ! -f $xmlfile_path ) {
        oscar_log (5, ERROR, "the file ($xmlfile_path) does not exists.");
        return undef;
    } else {
        oscar_log (5, INFO, "Parsing $xmlfile_path...");
        require XML::Simple;
        my $xs = new XML::Simple();
        $xml_ref = eval { $xs->XMLin( $xmlfile_path ); };
        if ($@) {
            oscar_log(5, ERROR, "$xmlfile_path is invalid.");
            $xml_ref = undef;
            oscar_log (6, ACTION, "Trying to xmllint the $xmlfile_path to show ".
                                  "problems:");
            my $cmd = "xmllint $xmlfile_path";
            oscar_log(7, ACTION, "About to run: $cmd");
            system $cmd if ($OSCAR::Env::oscar_verbose >= 6);
        }
    }

    return $xml_ref;
}

################################################################################
=item generate_empty_xml_file()

Generate an empty XML file (only the header is created within the file so
it is possible to parse the file even empty).

 Input: file: The absolute path of the file to be created.
Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub generate_empty_xml_file ($$) {
    my ($file, $debug) = @_;

    if (!OSCAR::Utils::is_a_valid_string ($file)) {
        oscar_log(5, ERROR, "Invalid file name. (Can't create new config.xml)");
        return -1;
    }

    if (-f $file) {
        oscar_log(6, INFO, "The file ($file) already exists (not creating empty one)");
        return 0;
    }

    oscar_log(5, ACTION, "Creating the file $file");
    open (FILE, ">$file") or (oscar_log(5, ERROR, "can't open $file for writing: $!."), return -1);
    print FILE "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
    print FILE "<opt/>";
    close (FILE);
    return 0;
}

################################################################################
=item add_line_to_file_at()

Insert a line in a file at a given position.

NOTE: If line doe not exists: we append to the file.

 Input: file: the file in which we want to insert a line.
        line: The content of the line we want to insert.
         pos: the line number in file where we want to insert a line.
Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub add_line_to_file_at ($$$);

sub add_line_to_file_at ($$$) {
    my ($file, $line, $pos) = @_;

    my $current_line = get_line_in_file ($file, $pos);
    if (!defined $current_line) {
        open (DAT, ">>$file");
        print DAT "$line";
        close (DAT);
    } else {
        # OL: FIXME: Can be greatly optimized.
        if (add_line_to_file_at ($file, $current_line, $pos+1)) {
            oscar_log(5, ERROR, "Failed to add $current_line at $pos+1 in $file");
            return -1;
        }
        if (replace_line_in_file ($file, $pos, $line)) {
            oscar_log(5, ERROR, "Inpossible to replace line $pos in $file");
            return -1;
        }
    }

    return 0;   
}

################################################################################
=item remove_line_from_file_at()

Remove line# from a file.

NOTE: If line doe not exists: this is ok.

 Input: file: the file in which we want to remove a line.
         pos: the line number (starting at 0) in file where we want to
              insert a line.

Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub remove_line_from_file_at ($$) {
    my ($file, $pos) = @_;
    my @lines;

    # We get the content of the file and update it
    open (DAT, $file) 
        or (oscar_log(5, ERROR, "Failed to open $file for reading."), return -1);
    @lines = <DAT>;
    close (DAT);
    if (scalar (@lines) < $pos) {
        # The line does not exist, we successfully exit
        oscar_log(6, INFO, "Line $pos does not exists. (not removed; not a problem)");
        return 0;
    }
    delete $lines[$pos];

    # We overwrite the file.
    open (DAT, ">$file") or (oscar_log(5, ERROR, "Impossible to open $file for writing."), return -1);
    for (my $i = 0; $i < scalar (@lines); $i++) {
        if (defined $lines[$i]) {
            print DAT $lines[$i];
        }
    }
    close (DAT);

    return 0;
}

################################################################################
=item replace_block_in_file()

Replace lines within a block.

Delimiters for beginning and end of the block are:
 # OSCAR block: <block name>
 # OSCAR block end: <block name>

NOTE: If block is not found, we append it.

 Input:       file: The file in which we want to replace/append a block of data.
        block_name: Specific part of the block delimiter
              data: Array of lines we want to replace/insert.
Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub replace_block_in_file ($$$) {
    my ($file, $block_name, $data) = @_;

    if (!defined $data || ref ($data) ne "ARRAY") {
        oscar_log(6, ERROR, "Invalid block data.");
        oscar_log(5, ERROR, "Can't update block in file.");
        return -1;
    }

    if (!defined $block_name) {
        oscar_log(6, ERROR, "Undefined block name.");
        oscar_log(5, ERROR, "Can't update block in file.");
        return -1;
    }

    if (!defined $file) {
        oscar_log(6, ERROR, "Undefined filename.");
        oscar_log(5, ERROR, "Can't update block in file.");
        return -1;
    }
    if (! -f $file) {
        oscar_log(5, ERROR, "File not found: $file.");
        oscar_log(5, ERROR, "Can't update block in file.");
        return -1;
    }

    oscar_log(5, ACTION, "Updating block \"OSCAR block: $block_name\" in file $file");
    oscar_log(9, INFO, "With the following content:\n");
    if ($OSCAR::Env::oscar_verbose >= 9) {
        print "OSCAR block: $block_name\n";
        print map { "$_\n" } @$data;
        print "OSCAR block end: $block_name\n";
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
            oscar_log(6, ERROR, "Begining of block found in file $file, but not the end.");
            oscar_log(5, ERROR, "Can't update block in file. (delimiters pb)");
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
            or (oscar_log(5, ERROR, "Can't update block: Failed to open file: $file for appending."), return -1);
        print DAT "# OSCAR block: $block_name\n";
        for (my $i = 0; $i < scalar (@$data); $i++) {
            print DAT $data->[$i]."\n" 
                if (OSCAR::Utils::is_a_valid_string ($data->[$i]));
        }
        print DAT "# OSCAR block end: $block_name\n";
        close (DAT);
    }

    oscar_log(5, INFO, "Successfully updated block \"OSCAR block: $block_name\" in file $file");
    return 0;
}

################################################################################
=item find_block_from_file()

Read content of a block.

Delimiters for beginning and end of the block are:
 # OSCAR block: <block name>
 # OSCAR block end: <block name>

 Input:       file: The file in which we want to replace/append a block of data.
        block_name: Specific part of the block delimiter
           ref_res: Reference to array that will be loaded with lines from block.
Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub find_block_from_file ($$$) {
    my ($file, $block_name, $res_ref) = @_;
    my $block_pos_end = -1;
    my $block_pos_begin = line_in_file ("# OSCAR block: $block_name", $file);

    if ($block_pos_begin != -1) {
        $block_pos_end = line_in_file ("# OSCAR block end: $block_name", $file);
        if ($block_pos_end == -1) {
            oscar_log (6, ERROR, "Begining of block found in file $file, but not the end.");
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

    oscar_log(5, INFO, "Successfully read block\"# OSCAR block: $block_name\" from file $file");
    return 0;
}

################################################################################
=item add_to_annoted_block()

Add a line to a block in a file.

Delimiters for beginning and end of the block are:
 # OSCAR block: <block name>
 # OSCAR block end: <block name>

 Input:       file: The file in which we want to replace/append a block of data.
        block_name: Specific part of the block delimiter
              line: Line to be appended to block
               dup: 0 means: avoid duplicate (do nothing if line present)
Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub add_to_annoted_block ($$$$) {
    my ($file, $block_name, $line, $dup) = @_;
    
    my @data = ();

    oscar_log(6, INFO, "Updating block \"$block_name\" in file $file");
    oscar_log(9, INFO, "with line: $line");

    if (find_block_from_file ($file, $block_name, \@data)) {
        oscar_log(5, ERROR, "Impossible to get block $block_name from $file");
        return -1;
    }

    if ($dup == 0) {
        my $i = 0;
        # We check if the line is already there
        while (OSCAR::Utils::trim ($data[$i]) ne OSCAR::Utils::trim ($line)
               && $i < scalar (@data)) {
            $i++;
        }
        if (OSCAR::Utils::trim ($data[$i]) eq OSCAR::Utils::trim ($line)) {
            # The line is already there so we exit successfully
            oscar_log(6, INFO, "Line already part of block \"$block_name\". Doing nothing.");
            return 0;
        }
    }
    push (@data, "$line");

    if (replace_block_in_file ($file, $block_name, \@data)) {
        oscar_log(5, ERROR, "Impossible to update block $block_name in $file");
        return -1;
    }

    oscar_log(6, INFO, "successfully updated block \"$block_name\" in file $file");
    return 0;
}

################################################################################
=item remove_from_annoted_block()

Remove a line from a block in a file.

Delimiters for beginning and end of the block are:
 # OSCAR block: <block name>
 # OSCAR block end: <block name>

 Input:       file: The file in which we want to replace/append a block of data.
        block_name: Specific part of the block delimiter
              line: Line number to be removed from block
Return:  0: Success
        -1: Failure

Exported: YES
=cut
################################################################################
sub remove_from_annoted_block ($$$) {
    my ($file, $block_name, $line) = @_;

    my @data = ();

    oscar_log(6, INFO, "Removing line $line from block \"$block_name\" in file $file");

    if (find_block_from_file ($file, $block_name, \@data)) {
        # The block does not exist, we exit successfully.
        oscar_log(6, INFO, "Block \"$block_name\" not found. Job done.");
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
            oscar_log(5, ERROR, "Impossible to update block \"$block_name\" in $file");
            return -1;
        }
    } 

    oscar_log(6, INFO, "successfully removed line $line from block \"$block_name\" in file $file");
    return 0;
}

1;

__END__

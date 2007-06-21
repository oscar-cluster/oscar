package InstallerUtils;

#########################################################################
                                                                                
=head1 NAME
                                                                                
InstallerUtils - Some basic utility subroutines for use by the Installer
                                                                                
=head1 SYNOPSIS
                                                                                
  my $newstring = compactSpaces($oldstring);

  my $newarrayref = deepcopy(@origarray);
  my $newhashref = deepcopy(%orighash);

  my $installDir = getScriptDir();

  $activeOdaCommand = 'oscar_version';
  $activeTestCode = '$odasuccess && ($odaresult[0] >= 2.3)';
  my $odatestsuccess = runActiveOdaTest();
  my $errorstr = getActiveErrorString() if (!$odatestsuccess);

  my $pixmap = getPixmap('oscar.png');
                                                                                
=head1 DESCRIPTION

This class contains a bunch of utility subroutines used by the OSCAR
Installer.  See the comments of each subroutine for more information.

Note that to use some of the subroutines (C<runActiveOdaTest()> for
example), you must first set the three global variables
C<$activeOdaCommand>, C<$activeTestCode>, and C<$activeErrorCode>.  These
correspond to the <command>, <test>, and <error> tags in the GUI.xml file.
They act as prerequisites for a Task.  All of the commands and corresponding
tests must return true for the Task to be able to run.  So, you set the
C<$activeOdaCommand> and C<$activeTestCode> variables and then call
C<runActiveOdaTest()> for each oda prereq.  If the prereq fails, then the
C<$activeErrorCode> is executed and the resulting string is output to the
"Details" pane of an error dialog box.  If the C<$activeErrorCode> is empty,
it defaults to the output of C<getDefaultErrorString()>.
                                                                                
=head1 METHODS
                                                                                
=over
                                                                                
=cut
                                                                                
#########################################################################

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Database;
use OSCAR::OCA::OS_Detect;
use Exporter;
use Carp;
use Qt;

our $VERSION = 1.0;
our @ISA = qw(Exporter);
our @EXPORT = qw(compactSpaces 
                 deepcopy
                 getScriptDir
                 runActiveOdaTest
                 getActiveErrorString
                 $activeOdaCommand 
                 $activeTestCode
                 $activeErrorCode
                );

# These three global variables must be set prior to calling runActiveOdaTest().
# They correspond to the <command>, <test>, and <error> text in GUI.xml.
our $activeOdaCommand;
our $activeTestCode;
our $activeErrorCode;

# These package variables hold the output of the current <command> and <test>
# as specified by $activeOdaCommand and $activeTestCode.  Note that these
# variables are set after a call to runActiveOdaTest().
my $odaCommandSuccess;
my @odaCommandResult;
my @odaCommandError;
my $testCodeSuccess;

my $installerDir = undef;  # Local storage of dir found by FindBin
my $perlQtVersion;         # Local storage for version of installed Perl-Qt

sub compactSpaces
{
#########################################################################

=item C<compactSpaces($origstring, $compactspaces, $changecommas)>

Remove leading/trailing spaces from a string.

This takes in a string and returns the same string with any leading/trailing
spaces removed.  You can also pass in an optional second argument (=1) to
compact any multiple intervening spaces down to one space.  You can also
pass in an optional third arument (=1) to change all commas to spaces before
removing/compacting spaces.

=cut

### @param  $origstring The original string from which to remove spaces.
### @param  $compactspaces If this optional argument is set to 1,
###         then multiple spaces are compacted down to one space.
### @param  $changecommas If this optional argument is set to 1, then all 
###         commas are changed to spaces prior to compacting/removing spaces.
### @return A new string with leading/trailing spaces removed, and possibly
###         commas changed to spaces and multiple spaces compacted down to
###         a single space.

#########################################################################

  my($string,$compact,$commas) = @_;
                                                                                
  $string =~ s/,/ /g if ($commas);    # Change commas to spaces
  $string =~ s/^ *//;                 # Strip off leading spaces
  $string =~ s/ *$//;                 # Strip off trailing spaces
  $string =~ s/ +/ /g if ($compact);  # Compact multiple spaces
                                                                                
  return $string; 
}

sub deepcopy
{
#########################################################################

=item C<deepcopy($hashOrArray)>

Do a "deep copy" of an array or a hash.

When you assign one array to another or one hash to another, Perl does a
"shallow copy", meaning that only elements at the top level of the
hash/array are copied.  Any sub-references are not.  This subroutine
performs a "deep copy" by recursing down through the reference tree and
copying everything.  

=cut

### @param  $hashOrArray An array or hash to be copied.
### @return A reference to a "deep copy" of the passed-in array/hash.
### @note   This subroutine was taken from Unix Review Column 30, Feb. 2000.

#########################################################################

  my $this = shift;
  if (not ref $this)
    { $this; }
  elsif (ref $this eq "ARRAY")
    { [map deepcopy($_), @$this]; }
  elsif (ref $this eq "HASH")
    { +{map { $_ => deepcopy($this->{$_}) } keys %$this}; }
  else
    { Carp::carp("What type is $_?"); }
}

sub getScriptDir
{
#########################################################################

=item C<getScriptDir()>

Return the directory of the main executed script.

This subroutine returns the full path of the Perl script which was envoked.
Since Perl reports the current working directory as the directory from which
the executed script was started (which can be different from the directory
where the script is located), it is difficult to use Perl modules from a
directory relative to the program script directory.  

To get around this problem, Perl provides the FindBin module which tries to
determine the location of the executed Perl script.  This subroutine returns
that directory so we can call all of the Tasks/Tools modules relative to the
Installer directory.

=cut

### @return A string of the Installer's main script directory.

#########################################################################

  if (!defined($installerDir))
    {
      delete $INC{'FindBin.pm'};
      require FindBin;
      import FindBin qw($Bin);
      $installerDir = $FindBin::Bin;
    }

  return $installerDir;
}

sub runActiveOdaTest
{
#########################################################################

=item C<runActiveOdaTest()>

Run the current oda command and associated test code and save the returned
values in some package-scope variables.  The following variables are set
by this subroutine:

  $odaCommandSuccess - 1 if database_execute_command succeeded, else 0
  @odaCommandResult  - an array containing the resulting strings output by
                       the oda command
  @odaCommandError   - an array containing any error strings generated by
                       database_execute_command
  $testCodeSuccess   - run the test code and save the return result in this
                       variable

These varilables are package-scoped since they really shouldn't be needed
outside this package.  However, the C<$testCodeSuccess> is returned by this
subroutine to let the calling procedure know if the oda command AND
corresponding test succeeded or failed.

=cut

### @return The result of the test code, which is definitely 0 if the oda
###         command failed.

#########################################################################

  $odaCommandSuccess = 1;  # Assume success in case no $activeOdaCommand
  @odaCommandResult = ();
  @odaCommandError = ();
  $testCodeSuccess = 0;

  $odaCommandSuccess = OSCAR::Database::database_execute_command(
    $activeOdaCommand,\@odaCommandResult,\@odaCommandError) if
      ($activeOdaCommand);

  # Make copies of variables so that the <test> code can use them as 
  # specified in the InstallerAPI.txt document.
  my $command = $activeOdaCommand;
  my $odasuccess = $odaCommandSuccess;
  my @odaresult = deepcopy(@odaCommandResult);
  my @odaerror  = deepcopy(@odaCommandError);
  $testCodeSuccess = (eval ($activeTestCode));

  return $testCodeSuccess;
}

sub getDefaultErrorString
{
#########################################################################

=item C<getDefaultErrorString()>

Return a default diagnostic error string for oda command/test failure.

When a Task's oda command and corresponding test code fails to return
success, we need to show the output of the oda command (including error
codes) in a detailed window so the user can figure out what happened.  This
subroutine returns a default diagnostic error string with all information
possible, including the original oda command, its return result
(success/failure), the results of the oda command (stored in an array), any
error strings generated by the oda command (which may contain useful oda
error strings and/or less useful MySQL error codes), and the original
test code which returned failure.  Note that if the original test code was
not specified (empty) then it defaults to returning the oda database return
result (i.e. $odasuccess).  See the API document for the format of the
GUI.xml file and for some examples.

=cut

### @return A detailed diagnostic error string for why the current oda
###         command and/or corresponding test failed.
### @see    getActiveErrorString()

#########################################################################

  my $errorstr;
  my $count = 0;

  $errorstr  = "oda command: $activeOdaCommand\n";
  $errorstr .= "returned value: $odaCommandSuccess\n";
  $errorstr .= "result array:\n";
  foreach my $result (@odaCommandResult)
    {
      $errorstr .= "    result[$count++]: $result\n";
    }
  $count = 0;
  $errorstr .= "error strings:\n" if scalar(@odaCommandError);
  foreach my $error (@odaCommandError)
    {
      $errorstr .= "    error[" . $count++ . "]: $error\n";
    }
  $errorstr .= "test command: $activeTestCode\n";
  $errorstr .= "returned value: $testCodeSuccess\n";
  $errorstr .= '--------------------------------------------------';

  return $errorstr;
}

sub getActiveErrorString
{
#########################################################################

=item C<getActiveErrorString()>

Return a diagnostic error string for oda command/test failure.

For each oda command and corresponding test, the return result of the test
must be 1 (true).  If not, then an error dialog box is presented to the user
along with an error string indicating the cause of the failure.  The Task
developer has the option of specifying code which returns an error string
for each oda command/test.  If no such error string is specified, then a
default error string is returned by C<getDefaultErrorString()>.  

This subroutine returns the error string generated by the <error> code in
the GUI.xml file, or C<getDefaultErrorString()> if no <error> tag is
specified for a given oda prerequisite.  So, to use this subroutine, you
must first set the global variable C<$activeErrorCode> to the <error> code
and then call C<getActiveErrorString()>.

Note that if a developer writes a custom error string function, then 
C<getDefaultErrorString()> does NOT get called.  Instead, the developer must
call this function explicitly and concatenate the return string with any
additional error text he wants to output to the user.  For example, the
developer might write something like this:

    <error>return "Problem with the ODA database:\n" . getDefaultErrorString();
    </error>

Note that it is assumed that the C<runActiveOdaTest> subroutine has been
called before this subroutine because the error string corresponds to the
last executed oda command and corresponding test code.

=cut

### @return An error string when an oda command/test fails, either generated 
###         by the code in the <error> tag, or by getDefaultErrorString().
### @see    getDefaultErrorString()

#########################################################################

  my $errorstr;

  if (compactSpaces($activeErrorCode))
    {
      # Make copies of variables so that the <error> code can use them as 
      # specified in the InstallerAPI.txt document.
      my $command     = $activeOdaCommand;
      my $odasuccess  = $odaCommandSuccess;
      my @odaresult   = deepcopy(@odaCommandResult);
      my @odaerror    = deepcopy(@odaCommandError);
      my $test        = $activeTestCode;
      my $testsuccess = $testCodeSuccess;
      $errorstr       = (eval ($activeErrorCode));
    }
  else
    {
      $errorstr = getDefaultErrorString();
    }

  return $errorstr;
}


sub getPixmap
{
#########################################################################

=item C<getPixmap($imageName)>

Return a Qt::Pixmap for a given image name.

Use this subroutine when you need to load an image from the
InstallerImages.pm file.  Use the original filename of the image (i.e.
including the '.png' extension).  A QPixmap will be returned.

This subroutine is needed to handle different ways QPixmaps are loaded in
with Perl-Qt-3.006 and Perl-Qt-3.008 (and above).  (The older version of
Perl-Qt needed a MimeSourceFactory.)

=cut

### @param $imageName The original filename of the image to be loaded.  Note
###                   that this really isn't a filename since the image
###                   actually resides in the InstallerImages.pm file.
### @return The Qt::Pixmap loaded in.

#########################################################################

    my $imageName = shift;
    my $image;

    # Get the perl-Qt version.  Can't use Qt::VERSION since it's not reliable.
    if (!defined($perlQtVersion)) {
        my $os = OSCAR::OCA::OS_Detect::open();
        if ($os->{pkg} eq "rpm") {
            open(CMD,"rpm -q --queryformat %{VERSION} perl-Qt |");
            $perlQtVersion = <CMD>;
            close CMD;
        } elsif ($os->{pkg} eq "deb") {
            my $cmd = "dpkg-query -W -f=\'\${Version}\' libqt-perl";
            $perlQtVersion = `$cmd`;
        } else {
            die ("ERROR: Unknown binary format ($os->{pkg})");
        }
    }

  if ($perlQtVersion >= 3.008)
    {
      $image = Qt::Pixmap::fromMimeSource($imageName);
    }
  else
    {
      $image = Qt::Pixmap();
      my $m = Qt::MimeSourceFactory::defaultFactory()->data($imageName);
      Qt::ImageDrag::decode($m,$image) if ($m);
    }

  return $image;
}

1;

__END__

=back
                                                                                
=head1 SEE ALSO
                                                                                
http://www.perldoc.com/perl5.8.0/lib/FindBin.html

http://www.stonehenge.com/merlyn/UnixReview/col30.html
                                                                                
=head1 COPYRIGHT
                                                                                
Copyright E<copy> 2004 The Board of Trustees of the University of Illinois.
All rights reserved.
                                                                                
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
                                                                                
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
                                                                                
You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
                                                                                
=head1 AUTHOR
                                                                                
Terrence G. Fleury (tfleury@ncsa.uiuc.edu)
                                                                                
First Created on April 2, 2004
                                                                                
Last Modified on April 9, 2004
                                                                                
=cut
                                                                                
#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
# 06/20/07  Restart the GUI work. Note that now OSCAR supports several  #
#           binary package formats (i.e. RPM and Debs).                 #
#########################################################################


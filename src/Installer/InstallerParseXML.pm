package InstallerParseXML;

#########################################################################

=head1 NAME

InstallerParseXML - Parse the XML configuration files for the Installer.

=head1 SYNOPSIS

  use InstallerParseXML;
  readInstallerXMLFile();
  my $classname = $installerTasksAndTools->{$tasktooldir}->{classname};
  my $fullname  = $installerTasksAndTools->{$tasktooldir}->{fullname};

=head1 DESCRIPTION

Read in various XML configuration files for the Installer and cache the
information in some global (exported) variables.  The only exported function
is readInstallerXMLFile().  The main configuration file is Installer.xml
which resides in the Installer directory.  This file lists all of the
available Tasks/Tools.  The Tasks/Tools reside in directories directly
underneath the Installer directory.  These Tasks/Tools directories contain a
GUI.xml file which specifies things like the classname of the tool, the
fullname (or 'pretty print' name) of the tool, and any oda commands/tests
which act as prerequisites for the Task to be able to run.  See the
InstallerAPI.txt document for details.

After you call readInstallerXMLFile(), the values of the various XML files
reside in the global hash reference $installerTasksAndTools.  The keys of
this hash are the directory names of the Tasks/Tools.  The sub-keys for each
Task/Tool look like this:

  $installerTasksAndTools->{$tasktooldir}->
    {type}      = Either 'task' or 'tool'
    {stepnum}   = The step number of the Task.  Not valid for Tools.  The
                  step numbers must be unique or an error message is output.
    {classname} = The name of the Perl module file containing the PerlQt
                  NEW function.  This is used to create a new instance of
                  the Task/Tool.  This defaults to the Task/Tool directory
                  name if classname is not given in the GUI.xml file.
    {fullname} =  The 'pretty print' name to be displayed in the pulldown
                  menu.  This defaults to the {classname} field if the 
                  fullname is not given in the GUI.xml file.
    {command}  =  These three are arrays for the oda prerequisite commands
    {test}        listed in the GUI.xml file.  The arrays are ordered such
    {error}       that {command}[2], {test}[2], and {error}[2] all refer
                  to a single <oda>...</oda> entry in the GUI.xml file.  If
                  the <test> field is empty for a particular oda prereq, it
                  gets set to a default of 'return $odasuccess', where
                  $odasuccess is the return result of
                  database_execute_command(...).

Two other global arrays are also set by readInstallerXMLFile():
@installerTasksSorted and @installerToolsSorted.  These contain the
directory names of all of the Tasks/Tools.  The Tasks are sorted numerically
by their step number.  The Tools are sorted alphabetically by their
fullname.  These two arrays can be used to build the pulldown menus of Tasks
and Tools in the main window.

=head1 METHODS

=over

=cut

#########################################################################

use strict;
use utf8;

use XML::Simple;
use Carp;
use InstallerUtils;

use Exporter;
our(@ISA,@EXPORT,$VERSION);
$VERSION = 1.0;
@ISA = ("Exporter");
@EXPORT = qw( readInstallerXMLFile
              $installerTasksAndTools
              @installerTasksSorted
              @installerToolsSorted
            );

our $installerTasksAndTools;
our @installerTasksSorted;
our @installerToolsSorted;

sub readInstallerXMLFile
{
#########################################################################

=item C<readInstallerXMLFile()>

Read in the main Installer.XML file and any necessary GUI.xml files.

This subroutine should be called when the Installer launches to read in the
Installer.XML file and any GUI.xml files in Tasks/Tools directories.  The
Installer.XML file lists out all of the Tasks and Tools, and the step number
for each Task.  See the InstallAPI.txt document for more information on the
format of the configuration file.

For each Task/Tool in the Installer.XML file, we call readGUIXMLFile() to
read in the GUI.xml files.  Again, see the API document for information on
the format of these files.  

The information in the Installer.xml file is stored in the global hash
reference $installerTasksAndTools.  This hash reference uses the Task/Tool
directory name as its key, and contains the following sub-keys:

  $installerTasksAndTools->{$tasktooldir}->
    {type}    = Either 'task' or 'tool'
    {stepnum} = The step number of the Task.  Not valid for Tools.  The
                step numbers must be unique or an error message is output.

Also, the global variables @installerTasksSorted and @installerToolsSorted
are created by this subroutine.  These arrays are sorted alphabetically by
the step number in the case of Tasks, and by the 'pretty print' name in the
case of Tools.

=cut

### @see readGUIXMLFile()

#########################################################################

  # Clear out the exported (global) variables
  undef $installerTasksAndTools;
  @installerTasksSorted = ();
  @installerToolsSorted = ();

  my $values;  # Return result of XMLin
  my $installerDir = getScriptDir();

  if (-e "$installerDir/Installer.xml")
    {
      $values = eval
        { XMLin("$installerDir/Installer.xml", 
                suppressempty => '', forcearray => '1', keyattr => []); };
      undef $values if ($@);   # If XMLin caused an error
    }

  return if (!$values);   # No further processing if error of some sort

  # First, parse out the 'tasks'.
  # Note: If there are two tasks with the same num, it's an error!
  my %tasks;   # Temp storage for sorting by step number
  foreach my $task (@{ $values->{tasks}[0]{task} })
    {
      if (defined($tasks{$task->{stepnum}[0]}))
        { # ERROR!!!
          Carp::carp($tasks{$task->{stepnum}[0]} . " and " .
                     $task->{dirname}[0] . " both have a step number of " .
                     $task->{stepnum}[0]);
          undef $installerTasksAndTools;
          return;  # Return upon error with global variables cleared out
        }
      else
        { # Store the task in temp hash with key=stepnum and value=dirname
          $tasks{$task->{stepnum}[0]} = $task->{dirname}[0];
          $installerTasksAndTools->{$task->{dirname}[0]}->{type} = "task";
          $installerTasksAndTools->{$task->{dirname}[0]}->{stepnum} = 
            $task->{stepnum}[0];
        }
    }

  # Then, parse out the 'tools'.
  foreach my $tool (@{ $values->{tools}[0]{tool} })
    {
      $installerTasksAndTools->{$tool->{dirname}[0]}->{type} = "tool";
    } 

  # Read in the GUI.xml files for all Tasks/Tools
  foreach my $dir (keys %{ $installerTasksAndTools } )
    {
      readGUIXMLFile($dir);
    }

  # Change the %tasks hash into a sorted array of tasks, sorted by stepnum.
  # Ignore any Task that doesn't have a fullname (i.e. a GUI.xml file).
  foreach my $taskstep (sort keys %tasks)
    {
      my $taskdir = $tasks{$taskstep};
      push @installerTasksSorted, $taskdir if
        (compactSpaces($installerTasksAndTools->{$taskdir}->{fullname}));
    }

  # Finally, setup the @installerToolsSorted array, sorted by fullname
  my %tools;  # Temp storage for sorting
  foreach my $tasktool (keys %{ $installerTasksAndTools } )
    { # Build up the temp tools hash with keys=fullname, values=dirname
      # Ignore any Tool that doesn't have a fullname (i.e. a GUI.xml file).
      $tools{$installerTasksAndTools->{$tasktool}->{fullname}} = $tasktool if
        (($installerTasksAndTools->{$tasktool}->{type} eq 'tool') &&
         (compactSpaces($installerTasksAndTools->{$tasktool}->{fullname})));
    }
  # Then, create @installerToolsSorted array of dirnames, sorted by fullname
  foreach my $tool (sort keys %tools)
    {
      push @installerToolsSorted, $tools{$tool};
    }
}

sub readGUIXMLFile
{
#########################################################################

=item C<readGUIXMLFile($tasktooldir)>

Read in the GUI.xml file for a given Task/Tool.

This subroutine reads in the configuration information in the GUI.xml file
for a particular Task/Tool.  The parameter passed in is the name of the
directory containing the Task/Tool.  See the InstallerAPI.txt document for
information on the format of this file.

The information in the GUI.xml file is stored in the global hash reference
$installerTasksAndTools.  This hash reference uses the Task/Tool directory
name as its key, and contains the following sub-keys:

  $installerTasksAndTools->{$tasktooldir}->
    {classname} = The name of the Perl module file containing the PerlQt
                  NEW function.  This is used to create a new instance of
                  the Task/Tool.  This defaults to the Task/Tool directory
                  name if classname is not given in the GUI.xml file.
    {fullname} =  The 'pretty print' name to be displayed in the pulldown
                  menu.  This defaults to the {classname} field if the 
                  fullname is not given in the GUI.xml file.
    {command}  =  These three are arrays for the oda prerequisite commands
    {test}        listed in the GUI.xml file.  The arrays are ordered such
    {error}       that {command}[2], {test}[2], and {error}[2] all refer
                  to a single <oda>...</oda> entry in the GUI.xml file.  If
                  the <test> field is empty for a particular oda prereq, it
                  gets set to a default of 'return $odasuccess', where
                  $odasuccess is the return result of
                  database_execute_command(...).

Note that if a Task/Tool doesn't have a valid GUI.xml file, then none of the
information for that Task/Tool (classname, fullname, etc.) will be set.
Thus, that Task/Tool will not appear in the sorted @installerTasksSorted / 
@installerToolsSorted lists, and thus they will not appear in the pulldown
menus of Tasks/Tools.

=cut

### @param $tasktooldir The directory name of a Task or Tool.
### @see   readInstallerXMLFile()

#########################################################################

  my $dir = shift;
  my $values;   # Hash ref for XMLin return result
  my $installerDir = getScriptDir();

  if ((-d "$installerDir/$dir") && (-e "$installerDir/$dir/GUI.xml"))
    {
      $values = eval
        { XMLin("$installerDir/$dir/GUI.xml", 
                suppressempty => '', forcearray => '1', keyattr => []); };
      undef $values if ($@);  # If XMLin caused an error.
    }

  if ($values)
    {
      # Note: classname defaults to Task/Tool dir if not present in XML file
      $installerTasksAndTools->{$dir}->{classname} = 
        (($values->{classname}[0]) ?
         $values->{classname}[0] :
         $dir);
      # Note: fullname defaults to classname if not present in XML file
      $installerTasksAndTools->{$dir}->{fullname} = 
        (($values->{fullname}[0]) ?
          $values->{fullname}[0] : 
          $installerTasksAndTools->{dir}->{classname});

      # For each oda prereq, create arrays for {command}, {test}, and {error}
      foreach my $oda (@{ $values->{oda} })
        { 
          push @{$installerTasksAndTools->{$dir}->{command}},$oda->{command}[0];
          push @{$installerTasksAndTools->{$dir}->{test}},
            ((compactSpaces($oda->{test}[0])) ? 
              $oda->{test}[0] : 'return $odasuccess;');
          push @{$installerTasksAndTools->{$dir}->{error}},$oda->{error}[0];
        }
    }
}

1;

__END__

=back

=head1 SEE ALSO

http://cpan.uwinnipeg.ca/htdocs/XML-Simple/XML/Simple.html

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

First Created on February 2, 2004

Last Modified on April 12, 2004

=cut

#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
#########################################################################


package InstallerMainWindow;

#########################################################################

=head1 NAME

InstallerMainWindow - Creates a new QMainWindow for a Qt application.

=head1 SYNOPSIS

  package main;

  use Qt;
  use InstallerMainWindow;

  my $appl = Qt::Application(\@ARGV);
  my $main = InstallerMainWindow;
  $appl->setMainWidget($main);
  $main->show;
  exit $appl->exec;

=head1 DESCRIPTION

This class is a subclass of Qt::MainWindow and creates a new main window for
the OSCAR Installer.  The central widget of this main window contains a
Qt::Workspace which contains all of the tasks and tools for the OSCAR
Installer.  

=head1 METHODS

=over

=cut

#########################################################################

use strict;
use utf8;

use Qt;
use Qt::isa qw(Qt::MainWindow);
use InstallerWorkspace;
use InstallerImages;
use InstallerParseXML;
use InstallerUtils;
use InstallerErrorDialog;
use Qt::slots
    fileNew => [],
    fileOpen => [],
    fileSave => [],
    fileSaveAs => [],
    filePrint => [],
    fileExit => [],
    helpIndex => [],
    helpContents => [],
    helpAbout => [],
    windowMenuAboutToShow => [],
    windowMenuActivated => ['int'],
    tasksMenuActivated => ['int'],
    toolsMenuActivated => ['int'],
    taskToolClosed => ['char*'];
use Qt::attributes qw(
    installerWorkspace
    centralWidget
    gridLayout
    fileMenu
    tasksMenu
    toolsMenu
    windowMenu
    helpMenu
    fileNewAction
    fileOpenAction
    fileSaveAction
    fileSaveAsAction
    filePrintAction
    fileExitAction
    windowCascadeAction
    windowTileAction
    helpContentsAction
    helpIndexAction
    helpAboutAction
);


# This hash contains all of the currently instantiated Tasks and Tools and
# is used to build the windowList.  The keys of the hash are the directory
# names of the Tasks/Tools.
my %currTaskToolWidgets;

sub NEW
{
#########################################################################

=item C<NEW($parent, $name, $flags)>

The constructor for the InstallerMainWindow class.  

This returns a pointer to a new InstallerMainWindow widget.  It sets up all
of the pulldown menus (for File, Edit, etc.), connects some SIGNALS and
SLOTS, and adds a new InstallerWorkspace to the central widget.  The
InstallerWorkspace is the parent of all other windows (Tasks, Tools, etc.)
However, since the "Windows" menu is generated dynamically by the windows
within the workspace (and thus the workspace requires access to that
pulldown menu), the InstallerWorkspace has to be added here.

If the $parent parameter is empty, then this is a top-level window (which is
what you probably want).  If the $name parameter is empty, the object is
given the default name "InstallerMainWindow".

B<Note>: As with any PerlQt constructor, the NEW constructor is called
implicitly when you reference the class.  You do not need to call something
like C<classname->>C<NEW(args...)>.

=cut

### @param $parent Pointer to the parent of this widget.  If empty (or null)
###                then this widget is a top-level window.
### @param $name   Name of the widget.  Will be set to "InstallerMainWindow"
###                if empty (or null).
### @param $flags  Flags for construction of QMainWindow.
### @return A Pointer to a new InstallerMainWindow widget.

#########################################################################

  shift->SUPER::NEW(@_[0..2]);

  setName("InstallerMainWindow") if (name() eq "unnamed");
  setCaption(trUtf8("OSCAR Wizard Installer") );

  # Set up the grid layout for the central widget and InstallerWorkspace
  centralWidget = Qt::Widget(this,"InstallerCentralWidget");
  setCentralWidget(centralWidget);
  gridLayout = Qt::GridLayout(centralWidget,1,1,1);
  installerWorkspace = InstallerWorkspace(centralWidget,"InstallerWorkspace");
  gridLayout->addWidget(installerWorkspace,0,0);

  # Create the status bar
  statusBar();

  # Create pulldown menus.  First: File menu
  fileMenu = Qt::PopupMenu(this);
  menuBar()->insertItem("",fileMenu,1);
  menuBar()->findItem(1)->setText(trUtf8("&File"));

  fileNewAction = Qt::Action(this,"fileNewAction");
  fileNewAction->setIconSet(
    Qt::IconSet(InstallerUtils::getPixmap("filenew.png")));
  fileNewAction->setText(trUtf8("New"));
  fileNewAction->setMenuText(trUtf8("&New"));
  fileNewAction->setAccel(Qt::KeySequence(trUtf8("Ctrl+N")));
  fileNewAction->addTo(fileMenu);

  fileOpenAction = Qt::Action(this,"fileOpenAction");
  fileOpenAction->setIconSet(
    Qt::IconSet(InstallerUtils::getPixmap("fileopen.png")));
  fileOpenAction->setText(trUtf8("Open"));
  fileOpenAction->setMenuText(trUtf8("&Open..."));
  fileOpenAction->setAccel(Qt::KeySequence(trUtf8("Ctrl+O")));
  fileOpenAction->addTo(fileMenu);

  fileSaveAction = Qt::Action(this,"fileSaveAction");
  fileSaveAction->setIconSet(
    Qt::IconSet(InstallerUtils::getPixmap("filesave.png")));
  fileSaveAction->setText(trUtf8("Save"));
  fileSaveAction->setMenuText(trUtf8("&Save"));
  fileSaveAction->setAccel(Qt::KeySequence(trUtf8("Ctrl+S")));
  fileSaveAction->addTo(fileMenu);

  fileSaveAsAction = Qt::Action(this,"fileSaveAsAction");
  fileSaveAsAction->setText(trUtf8("Save As"));
  fileSaveAsAction->setMenuText(trUtf8("Save &As..."));
  fileSaveAsAction->addTo(fileMenu);

  fileMenu->insertSeparator();

  filePrintAction = Qt::Action(this,"filePrintAction");
  filePrintAction->setIconSet(
    Qt::IconSet(InstallerUtils::getPixmap("print.png")));
  filePrintAction->setText(trUtf8("Print"));
  filePrintAction->setMenuText(trUtf8("&Print..."));
  filePrintAction->setAccel(Qt::KeySequence(trUtf8("Ctrl+P")));
  filePrintAction->addTo(fileMenu);

  fileMenu->insertSeparator();

  fileExitAction = Qt::Action(this,"fileExitAction");
  fileExitAction->setIconSet(
    Qt::IconSet(InstallerUtils::getPixmap("close.png")));
  fileExitAction->setText(trUtf8("Exit"));
  fileExitAction->setMenuText(trUtf8("E&xit"));
  fileExitAction->setAccel(Qt::KeySequence(trUtf8("Ctrl+Q")));
  fileExitAction->addTo(fileMenu);

  # Read in all of the XML file configuration information for Tasks/Tools
  readInstallerXMLFile();

  # Second: Tasks menu 
  tasksMenu = Qt::PopupMenu(this);
  menuBar()->insertItem("",tasksMenu,2);
  menuBar()->findItem(2)->setText(trUtf8("&Tasks"));
  populateTasksMenu();

  # Third: Tools menu
  toolsMenu = Qt::PopupMenu(this);
  menuBar()->insertItem("",toolsMenu,3);
  menuBar()->findItem(3)->setText(trUtf8("T&ools"));
  populateToolsMenu();

  # Fourth: Window menu - updated when Tools/Tasks are created/destroyed
  windowMenu = Qt::PopupMenu(this,"windowMenu");
  menuBar()->insertItem("",windowMenu,4);
  menuBar()->findItem(4)->setText(trUtf8("&Window"));
  
  windowCascadeAction = Qt::Action(this,"windowCascadeAction");
  windowCascadeAction->setText(trUtf8("Cascade"));
  windowCascadeAction->setMenuText(trUtf8("&Cascade"));
  windowCascadeAction->addTo(windowMenu);

  windowTileAction = Qt::Action(this,"windowTileAction");
  windowTileAction->setText(trUtf8("Tile"));
  windowTileAction->setMenuText(trUtf8("&Tile"));
  windowTileAction->addTo(windowMenu);

  windowMenu->insertSeparator();

  # Fifth: Help menu - Not sure about how much help there will be...
  helpMenu = Qt::PopupMenu(this);
  menuBar()->insertItem("",helpMenu,5);
  menuBar()->findItem( 5 )->setText( trUtf8("&Help") );

  helpContentsAction = Qt::Action(this,"helpContentsAction");
  helpContentsAction->setText(trUtf8("Contents"));
  helpContentsAction->setMenuText(trUtf8("&Contents..."));
  helpContentsAction->addTo(helpMenu);

  helpIndexAction = Qt::Action(this,"helpIndexAction");
  helpIndexAction->setText(trUtf8("Index"));
  helpIndexAction->setMenuText(trUtf8("&Index..."));
  helpIndexAction->addTo(helpMenu);

  helpMenu->insertSeparator();

  helpAboutAction = Qt::Action(this,"helpAboutAction");
  helpAboutAction->setText(trUtf8("About"));
  helpAboutAction->setMenuText(trUtf8("&About"));
  helpAboutAction->addTo(helpMenu);

  my $resize = Qt::Size(800,600);
  $resize = $resize->expandedTo(minimumSizeHint());
  resize($resize);
  clearWState(&Qt::WState_Polished);

  # Then, connect the signals for the pulldown menus to appropriate slots
  Qt::Object::connect(fileNewAction,      SIGNAL "activated()", 
                      this,               SLOT "fileNew()");
  Qt::Object::connect(fileOpenAction,     SIGNAL "activated()", 
                      this,               SLOT "fileOpen()");
  Qt::Object::connect(fileSaveAction,     SIGNAL "activated()", 
                      this,               SLOT "fileSave()");
  Qt::Object::connect(fileSaveAsAction,   SIGNAL "activated()", 
                      this,               SLOT "fileSaveAs()");
  Qt::Object::connect(filePrintAction,    SIGNAL "activated()", 
                      this,               SLOT "filePrint()");
  Qt::Object::connect(fileExitAction,     SIGNAL "activated()", 
                      this,               SLOT "fileExit()");
  Qt::Object::connect(windowCascadeAction,SIGNAL "activated()", 
                      installerWorkspace, SLOT "cascade()");
  Qt::Object::connect(windowTileAction,   SIGNAL "activated()", 
                      installerWorkspace, SLOT "tile()");
  Qt::Object::connect(helpIndexAction,    SIGNAL "activated()",
                      this,               SLOT "helpIndex()");
  Qt::Object::connect(helpContentsAction, SIGNAL "activated()",
                      this,               SLOT "helpContents()");
  Qt::Object::connect(helpAboutAction,    SIGNAL "activated()", 
                      this,               SLOT "helpAbout()");
  Qt::Object::connect(windowMenu,         SIGNAL "aboutToShow()",
                      this,               SLOT "windowMenuAboutToShow()");
}

sub populateTasksMenu
{
#########################################################################

=item C<populateTasksMenu()>

Fills in the Tasks pulldown menu.

This is called when the "Tasks" pulldown menu is created at program startup.
Note that you need to call readInstallerXMLFile() (which populates the
$installerTasksAndTools hash) before calling this subroutine.

=cut

#########################################################################

  my $arraynum = 0;
  foreach my $task (@installerTasksSorted)
    {
      my $menustr = "";  # Build up 'pretty print' name: "<step> - <fullname>"
      # Put an ampersand (&) in front of the first 9 Task numbers
      $menustr .= "&" if ($installerTasksAndTools->{$task}->{stepnum} < 10);
      $menustr .= $installerTasksAndTools->{$task}->{stepnum};
      $menustr .= ' - ';
      $menustr .= $installerTasksAndTools->{$task}->{fullname};
      my $id = tasksMenu->insertItem($menustr, this, 
                                     SLOT "tasksMenuActivated(int)");
      tasksMenu->setItemParameter($id,$arraynum++);
    }
}

sub populateToolsMenu
{
#########################################################################

=item C<populateToolsMenu()>

Fills in the Tools pulldown menu.

This is called when the "Tools" pulldown menu is created at program startup.
Note that you need to call readInstallerXMLFile() (which populates the
$installerTasksAndTools hash) before calling this subroutine.

=cut

#########################################################################

  my $arraynum = 0;
  my @letters;
  foreach my $tool (@installerToolsSorted)
    {
      # The following is a little trick to try to put an ampersand (&) in
      # the 'pretty print' name of the Tool, thus underlining a letter for
      # quick selection via the <Alt> key.  It finds unique letters for each
      # Tool by keeping track of which letters have already been used.
      my $searchstr = join '|', @letters;
      my $menustr = $installerTasksAndTools->{$tool}->{fullname};
      $menustr =~ /[^($searchstr)]/i;
      if (length($&) > 0)
        {
          $menustr = $` . '&' . $& . $';
          push @letters, $&;
        }
      my $id = toolsMenu->insertItem($menustr, this,
                                     SLOT "toolsMenuActivated(int)");
      toolsMenu->setItemParameter($id,$arraynum++);
    }
}

sub fileNew
{
  print "fileNew(): Not implemented yet.\n";
}

sub fileOpen
{
  print "fileOpen(): Not implemented yet.\n";
}

sub fileSave
{
  print "fileSave(): Not implemented yet.\n";
}

sub fileSaveAs
{
  print "fileSaveAs(): Not implemented yet.\n";
}

sub filePrint
{
  print "filePrint(): Not implemented yet.\n";
}

sub fileExit
{
  Qt::Application::exit();
}

sub helpIndex
{
  print "helpIndex(): Not implemented yet.\n";
}

sub helpContents
{
  print "helpContents(): Not implemented yet.\n";
}

sub helpAbout
{
  print "helpAbout(): Not implemented yet.\n";
}

sub windowMenuAboutToShow
{
#########################################################################

=item C<windowMenuAboutToShow()>

A SLOT which is called just before the Window menu is shown.

This SLOT gets called when the user clicks on the "Window" menu just before
the pulldown gets displayed.  This way, we can populate the Window menu with
a list of all open Tasks/Tools windows.  We also give the user the ability
to Cascade or Tile the windows in the workspace.  (These functions are built
into Qt so we don't have to do any extra work.)

=cut

#########################################################################

  windowMenu->clear();
  windowCascadeAction->addTo(windowMenu);
  windowTileAction->addTo(windowMenu);
  windowMenu->insertSeparator();

  my @windowList = sort (values %currTaskToolWidgets);
  my $numWindows = scalar(@windowList);
  windowCascadeAction->setEnabled($numWindows);
  windowTileAction->setEnabled($numWindows);

  for (my $i = 0; $i < $numWindows; $i++)
    {
      my $id = windowMenu->insertItem($windowList[$i]->caption(),
                                      this, SLOT "windowMenuActivated(int)");
      windowMenu->setItemParameter($id,$i);
      windowMenu->setItemChecked($id,
        installerWorkspace->activeWindow() == $windowList[$i]);
    }
}

sub windowMenuActivated
{
#########################################################################

=item C<windowMenuActivated($windowNum)>

A SLOT which is called when a Window item is selected.

This SLOT gets called when the user selects one of the window items in the
"Window" list.  It brings that window to the front of all other windows and
gives it the focus.

=cut

### @param $windowNum The line item number selected from the Window Menu.

#########################################################################

  my $windowNum = shift;

  my @windowList = sort (values %currTaskToolWidgets);
  my $wid = $windowList[$windowNum];
  if ($wid)
    {
      $wid->showNormal if ($wid->isMinimized);
      $wid->raise;
      $wid->setFocus;
    }
}

sub tasksMenuActivated
{
#########################################################################

=item C<tasksMenuActivated($taskNum)>

A SLOT which is called when a Task item is selected.

This SLOT gets called when the user selects one of the Tasks (aka installer
Steps) from the "Tasks" list.  It checks to see if that task is already
running.  If so, it brings it to the front.  If not, it closes out all other
tasks and launches the selected task.

=cut

### @param $taskNum The line item number selected from the Tasks Menu.

#########################################################################

  my $taskline = shift;
  my $taskname = $installerTasksSorted[$taskline];

  return if (!$installerTasksAndTools->{$taskname}->{classname});

  # Run all of the oda prereqs and show an error dialog if any fail

  my $success = processOdaCommandsAndTests($taskname);

  if ($success)
    {
      openTaskToolWindow($taskname,'task');
    }
  else
    {
      showErrorDialog($taskname);
    }
}

sub toolsMenuActivated
{
#########################################################################

=item C<toolsMenuActivated($taskNum)>

A SLOT which is called when a Tool item is selected.

This SLOT gets called when the user selects one of the Tools from the
"Tools" list.  It checks to see if that tool is already running.  If so, it
brings it to the front.  

=cut

### @param $toolNum The line item number selected from the Tasks Menu.

#########################################################################

  my $toolline = shift;
  my $toolname = $installerToolsSorted[$toolline];

  return if (!$installerTasksAndTools->{$toolname}->{classname});

  openTaskToolWindow($toolname,'tool');
}

sub openTaskToolWindow
{
#########################################################################

=item C<openTaskToolWindow($tasktool,$type)>

Lauches a specific Task or Tool, or brings it to the front if already
running.

This subroutine takes in the directory name of a Task/Tool which is to be
launched, and the type of the Task/Tool (i.e. 'task' or 'tool').  It checks
to see if that Task/Tool is already running, and if so, it brings it to the
front and gives it the focus.  If not, it launches the Task/Tool.  Since
only one Task can be active at a a time, it first closes any other Task
currently running.

=cut

### @param $tasktool The directory name of the Task/Tool to be shown.  
### @param $type Either 'task' or 'tool'.  This is needed because only
###              one task can be active at a time, but any number of
###              tools can be active at a time.

#########################################################################

  my ($tasktool,$type) = @_;

  if ($currTaskToolWidgets{$tasktool})
    { # If the Task/Tool is already running, bring it to the front.
      $currTaskToolWidgets{$tasktool}->showNormal if
        ($currTaskToolWidgets{$tasktool}->isMinimized);
      $currTaskToolWidgets{$tasktool}->raise;
      $currTaskToolWidgets{$tasktool}->setFocus;
    }
  else
    {
      if ($type eq 'task')
        { # Find out if we already have one Task running.  If so, kill it.
          foreach my $temptask (keys %currTaskToolWidgets)
            {
              if ($installerTasksAndTools->{$temptask}->{type} eq 'task')
                {
                  $currTaskToolWidgets{$temptask}->close(1);
                  delete $currTaskToolWidgets{$temptask};
                  last;
                }
            }
        }

      # Now create the new Task/Tool widget
      $currTaskToolWidgets{$tasktool} = launchTaskTool($tasktool,
        $installerTasksAndTools->{$tasktool}->{classname});

      if ($type eq 'task')
        { # If the Task is the first/last, hide the Back/Next button
          if ($tasktool eq $installerTasksSorted[0])
            { # First Task -> hide its Back button
              emit installerWorkspace->signalButtonShown($tasktool,'Back',0);
            }
          elsif ($tasktool eq $installerTasksSorted[$#installerTasksSorted])
            { # Last Task -> hide its Next button
              emit installerWorkspace->signalButtonShown($tasktool,'Next',0);
            }
        }

      # Set up the SIGNAL/SLOT connections for the Task/Tool
      connectTaskTool($tasktool);
    }
}

sub connectTaskTool
{
#########################################################################

=item C<connectTaskTool($tasktool)>

Set up SIGNAL/SLOT connections for a Task/Tool.

This subroutine takes in the directory name of a Task/Tool and sets up a
bunch of connections necessary for communication between the Workspace and
the Task/Tool.  These connections will get disconnected when the Task/Tool
closes.

=cut

### @param $tasktool The directory name of the Task/Tool to be shown.  
### @see disconnectTaskTool()

#########################################################################
  my $tasktool = shift;

  # Catch the widget's "taskToolClosing" signal.
  Qt::Object::connect($currTaskToolWidgets{$tasktool},
                      SIGNAL "taskToolClosing(char*)",
                      this,
                      SLOT   "taskToolClosed(char*)");
}

sub disconnectTaskTool
{
#########################################################################

=item C<disconnectTaskTool($tasktool)>

Disconnect SIGNAL/SLOT connections for a Task/Tool.

This subroutine takes in the directory name of a Task/Tool and undoes the
connections made when the Task/Tool was launched.

=cut

### @param $tasktool The directory name of the Task/Tool to be shown.  
### @see connectTaskTool()

#########################################################################
  my $tasktool = shift;

  Qt::Object::disconnect($currTaskToolWidgets{$tasktool},
                         SIGNAL "taskToolClosing(char*)",
                         this,
                         SLOT   "taskToolClosed(char*)");
}


sub launchTaskTool
{
#########################################################################

=item C<launchTaskTool($dirname,$classname)>

Create a new window instance of a given Task/Tool.

This is called by openTaskToolWindow to start a new instance of a given
Task/Tool.  The Task/Tool is specified by its directory name AND by its
class name.  This subroutine then does some tricky require/import stuff to
dynamically launch a new instance of the $classname QWidget.

=cut

### @param  $dirname The name of the (sub)directory of the Task/Tool to 
###         be launched.  
### @param  $classname The name of the Task/Tool's class, which is the
###         same as the main Perl module for the Task/Tool, minus the
###         .pm extension.
### @return The newly created Task/Tool widget.

#########################################################################

  my($dirname,$classname) = @_;

  # Get the base directory of the Installer.pl script
  my $installerDir = getScriptDir();
  
  return if ((!(-d "$installerDir/$dirname")) || 
             (!(-e "$installerDir/$dirname/$classname.pm")));

  # Prepend the Task/Tool directory to Perl's @INC array.  We can't do
  # 'use' for the following statements since 'use' is done at compile time
  # and the dirname and classname aren't known until run time.
  unshift(@INC,"$installerDir/$dirname");
  require $classname. '.pm';
  import $classname;
  no strict 'refs'; # Needed so that the next statement doesn't complain

  my $widget = &$classname(installerWorkspace);
  $widget->show;
  shift(@INC);      # Remove the Task/Tool directory we prepended earlier
  
  return $widget;   # Return the newly created widget
}

sub processOdaCommandsAndTests
{
#########################################################################

=item C<processOdaCommandsAndTests($tasktool)>

THIS STILL NEEDS TO BE COMMENTED AND CODED FURTHER...

=cut

#########################################################################

  my $task = shift;
  my $success = 1;   # Assume success

  # Clear out the result arrays from any previous executions
  @{$installerTasksAndTools->{$task}->{testSuccess}} = ();
  @{$installerTasksAndTools->{$task}->{errorString}} = ();

  my $cmdcnt = scalar(@{$installerTasksAndTools->{$task}->{command}});
  for (my $i = 0; $i < $cmdcnt; $i++)
    {
      # Set the appropriate global variables in InstallerUtils corresponding
      # to the <command>, <test>, and <error> tags.
      $InstallerUtils::activeOdaCommand = 
        $installerTasksAndTools->{$task}->{command}[$i];
      $InstallerUtils::activeTestCode =
        $installerTasksAndTools->{$task}->{test}[$i];

      my $odasuccess = InstallerUtils::runActiveOdaTest();
      $installerTasksAndTools->{$task}->{testSuccess}[$i] =
        $InstallerUtils::testCodeSuccess;
      if (!$odasuccess)
        {
          $success = 0;
          $InstallerUtils::activeErrorCode =
            $installerTasksAndTools->{$task}->{error}[$i];
          $installerTasksAndTools->{$task}->{errorString}[$i] =
            InstallerUtils::getActiveErrorString();
        }
    }

  return $success;
}

sub taskToolClosed
{
#########################################################################

=item C<taskToolClosed($tasktool)>

A SLOT which is called when a Task/Tool closes.

When a Task/Tool exits (closes), it should send the SIGNAL
'taskToolClosing($tasktool)' so that the MainWindow can update the list of
currently running Tasks/Tools.  This subroutine also calls
disconnectTaskTool($tasktool) to remove the connections set up when the
Task/Tool was created.

=cut

### @param $tasktool The directory name of the Task/Tool which has closed.

#########################################################################

  my $tasktool = shift;

  disconnectTaskTool($tasktool);

  delete $currTaskToolWidgets{$tasktool};
}

sub showErrorDialog
{
#########################################################################

=item C<showErrorDialog($task)>

=cut

### @param $task The directory name of the Task which had prerequisite
###              errors.

#########################################################################

  my $task = shift;

  my $dialog = InstallerErrorDialog(this);
  $dialog->setErrorMainText($installerTasksAndTools->{$task}->{stepnum},
                            $installerTasksAndTools->{$task}->{fullname});

  my $errortext = "";
  my $cmdcnt = scalar(@{$installerTasksAndTools->{$task}->{command}});
  for (my $i = 0; $i < $cmdcnt; $i++)
    {
      $errortext .= $installerTasksAndTools->{$task}->{errorString}[$i] if
        (!($installerTasksAndTools->{$task}->{testSuccess}[$i]));
    }
  $dialog->setErrorDetailsText($errortext);

  $dialog->exec();
}


1;

__END__

=back

=head1 SEE ALSO

http://www.trolltech.com/

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

Last Modified on April 19, 2004

=cut

#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
#########################################################################

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
use lib $ENV{OSCAR_HOME}."/src/Installer";
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
    taskToolClosed => ['char*'],
    taskBackButton => ['char*'],
    taskNextButton => ['char*'],
    openHelperWindow => ['QWidget*','char*','QStringList*'];
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
# names of the Tasks/Tools.  The values are the actual Task/Tool widgets.
my %currTaskToolWidgets;

# This hash contains the currently instantiated Helpers and is used to 
# build the windowList.  The keys of the hash formed by joining the name of
# the helper's directory with all of the parameters for that instance of
# the helper, separated by the character '\000'.  The values are the actual
# Helper widgets.
my %currHelperWidgets;

# This hash contains a list of the Tasks/Tools which have been launched
# at least once.  We need this because require/import needs to be called
# just once per class.  Used by launchTaskTool().
my %alreadyImported;

# Since Perl-Qt seems to have trouble deleting objects when subwindows
# close, I have to create my own list of open windows.  This gets refreshed
# in windowMenuAboutToShow().
my @windowList;

sub NEW
{
    print "Creating a new MainWindow object\n";
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
  print "Setting up the grid layout\n";
  print "Setting the central widget...\n";
  centralWidget = Qt::Widget(this,"InstallerCentralWidget");
  setCentralWidget(centralWidget);
  gridLayout = Qt::GridLayout(centralWidget,1,1,1);
  print "Setting the Installer Workspace widget...\n";
  installerWorkspace = InstallerWorkspace(centralWidget,"InstallerWorkspace");
  gridLayout->addWidget(installerWorkspace,0,0);

  # Create the status bar
  print "Creating the status bar\n";
  statusBar();

  # Create pulldown menus.  First: File menu
  print "Creating the pulldown menus\n";
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
  print "Reading the XML configuration file...\n";
  readInstallerXMLFile();

  # Second: Tasks menu 
  print "Creating tasks menu...\n";
  tasksMenu = Qt::PopupMenu(this);
  menuBar()->insertItem("",tasksMenu,2);
  menuBar()->findItem(2)->setText(trUtf8("&Tasks"));
  populateTasksMenu();

  # Third: Tools menu
  print "Creating tools menu...\n";
  toolsMenu = Qt::PopupMenu(this);
  menuBar()->insertItem("",toolsMenu,3);
  menuBar()->findItem(3)->setText(trUtf8("T&ools"));
  populateToolsMenu();

  # Fourth: Window menu - updated when Tools/Tasks are created/destroyed
  print "Creating the window menu...\n";
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
  print "Creating the help menu...\n";
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
  print "Connecting the signals...\n";
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
  Qt::Object::connect(installerWorkspace, 
                      SIGNAL "launchHelper(QWidget*,char*,QStringList*)",
                      SLOT   "openHelperWindow(QWidget*,char*,QStringList*)");
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

A SLOT which is called just before the Window pulldown menu is shown.

This SLOT gets called when the user clicks on the "Window" menu just before
the pulldown gets displayed.  This way, we can populate the Window menu with
a list of all open Tasks/Tools/Helper windows.  We also give the user the
ability to Cascade or Tile the windows in the workspace.  (These functions
are built into Qt so we don't have to do any extra work.)

=cut

#########################################################################

  windowMenu->clear();
  windowCascadeAction->addTo(windowMenu);
  windowTileAction->addTo(windowMenu);
  windowMenu->insertSeparator();

  # Get the list of all active tasks/tools/helpers windows, and sort them
  # alphabetically based on their window captions.
  my @tempList = (values %currTaskToolWidgets);
  push @tempList, (values %currHelperWidgets);
  @windowList = sort { $a->caption() cmp $b->caption() } @tempList;

  my $numWindows = scalar(@windowList);
  windowCascadeAction->setEnabled($numWindows);
  windowTileAction->setEnabled($numWindows);

  for (my $i = 0; $i < $numWindows; $i++)
    {
      my $id = windowMenu->insertItem($windowList[$i]->caption(),
                                      this, SLOT "windowMenuActivated(int)");
      windowMenu->setItemParameter($id,$i);
      windowMenu->setItemChecked($id,
        installerWorkspace->activeWindow()->name() eq $windowList[$i]->name());
    }
}

sub windowMenuActivated
{
    print "1\n";
#########################################################################

=item C<windowMenuActivated($windowNum)>

A SLOT which is called when a Window item is selected.

This SLOT gets called when the user selects one of the window items in the
"Window" list.  It brings that window to the front of all other windows and
gives it the focus.

=cut

### @param $windowNum The line item number selected from the Window Menu.

#########################################################################

  print "toto\n";
  my $windowNum = shift;
  print "Window num = $windowNum\n";

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
  (processOdaCommandsAndTests($taskname)) ?
    (openTaskToolWindow($taskname)) :
    (showErrorDialog($taskname));
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

  openTaskToolWindow($toolname);
}

sub openTaskToolWindow
{
#########################################################################

=item C<openTaskToolWindow($tasktool)>

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

#########################################################################

  my ($tasktool) = @_;
  my $isTask = ($installerTasksAndTools->{$tasktool}->{type} eq 'task');

  if ($currTaskToolWidgets{$tasktool})
    { # If the Task/Tool is already running, bring it to the front.
      $currTaskToolWidgets{$tasktool}->showNormal if
        ($currTaskToolWidgets{$tasktool}->isMinimized);
      $currTaskToolWidgets{$tasktool}->raise;
      $currTaskToolWidgets{$tasktool}->setFocus;
    }
  else
    {
      if ($isTask)
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
      $currTaskToolWidgets{$tasktool} = launchTaskTool($tasktool);

      if ($isTask)
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

sub openHelperWindow
{
#########################################################################

=item C<openHelperWindow($parent,$helper,$params)>

Launches a specific Helper with a set of parameters, or brings a Helper to
the front if one with the given set of parameters already exists.

This subroutine is a SLOT which is called when another Task, Tool, or Helper
signals the InstallerWorkspace to launch a new Helper.  When the SIGNAL is
emitted, the $parent is the Task, Tool, or Helper that wants to launch the
new helper.  We don't want the InstallerWorkspace to be the parent since the
new helper should go away when the parent Task/Tool/Helper goes away.  The
$helper parameter corresponds to the name of the directory for the helper.
The $params parameter is a reference to a list of strings which are the
parameters to pass to the new helper upon creation.

This subroutine will check to see if a helper with the same parameters is
already running.  If so, that window is brought to the front.  If not, this
subroutine checks to see if there is a limit upon the maximum number of this
kind of helper that can run at one time.  If so, we count up the number of
windows of this kind of helper and allow another helper to run only if we
aren't at the max limit yet.  

One important issue.  The Helper windows are stored separately from the
Tasks/Tools windows.  This is because Tasks/Tools allow a maximum of 1
window, so we can index the hash of Task/Tool windows based on the directory
name for the Task/Tool.  However, multiple Helpers with the same directory
name could be running at once, and so we need to distinguish these multiple
instances by the differences in the parameters passed to the Helper.  So,
the Helper windows are stored in a hash indexed by a string consisting of
the name of the helper directory AND the parameters, separated by the
character "\000", e.g. 'join "\000", $helper, @{ $params }'.

=cut

### @param $parent The Task/Tool/Helper Qt object that is requesting the
###                launch of a new Helper.
### @param $helper The directory name of the Helper to be shown.  
### @param $params A reference to a list of strings which are parameters
###                to be passed to the new Helper upon object creation.

#########################################################################
  my ($parent,$helper,$params) = @_;

  # Form the 'key' for the %currHelperWidgets by joining the directory name
  # of the helper with all of the parameters, separated by the character \000.
  my $key = join "\000", $helper, @{ $params };

  if ($currHelperWidgets{$key})
    { # A helper with the given parameters is running, bring to the front.
      $currHelperWidgets{$key}->showNormal if
        ($currHelperWidgets{$key}->isMinimized);
      $currHelperWidgets{$key}->raise;
      $currHelperWidgets{$key}->setFocus;
    }
  else
    { 
      # If there is a maxnum specified for the current helper name, then
      # count the number of helpers currently launched with that name and do
      # nothing if we are already at the maxnum limit.
      my $dirname;
      if ($installerTasksAndTools->{$helper}->{maxnum} > 0)
        {
          my $count = 0;
          foreach my $help (keys %currHelperWidgets)
            {
              ($dirname) = split /\000/, $help;
              $count++ if ($dirname eq $helper);
            }

          return if ($count == $installerTasksAndTools->{$helper}->{maxnum});
        }

      # If we made it this far, then we should launch a new Helper with
      # the given parameters.
      $currHelperWidgets{$key} = launchHelper($parent,$helper,$params);

      # Set up the SIGNAL/SLOT connections for the Helper
      connectHelper($key);
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
                      SLOT   "taskToolClosed(char*)");
  if ($installerTasksAndTools->{$tasktool}->{type} eq 'task')
    {
      Qt::Object::connect($currTaskToolWidgets{$tasktool},
                          SIGNAL "backButtonWasClicked(char*)",
                          SLOT   "taskBackButton(char*)");
      Qt::Object::connect($currTaskToolWidgets{$tasktool},
                          SIGNAL "nextButtonWasClicked(char*)",
                          SLOT   "taskNextButton(char*)");
    }
}

sub connectHelper
{
#########################################################################

=item C<connectHelper($key)>

Set up SIGNAL/SLOT connections for a Helper.

This subroutine sets up the SLOT/SIGNAL connections for a particular Helper
with a given set of parameters.  The passed-in parameter is the 'key' of the
$currHelperWidgets hash, i.e. 'join "\000", $helperDir, @{ $refParamList }'.
The connection should be broken by calling disconnectHelper with the same
'key'.

=cut

### @param $key The hash key for the $currHelperWidgets hash, which is
###             formed by joining the Helper directory name and all of the
###             Helper's parameters, separated by "\000".
### @see disconnectHelper()

#########################################################################
  my $key = shift;

  Qt::Object::connect($currHelperWidgets{$key},
                      SIGNAL "taskToolClosing(char*)",
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
                         SLOT   "taskToolClosed(char*)");
  if ($installerTasksAndTools->{$tasktool}->{type} eq 'task')
    {
      Qt::Object::disconnect($currTaskToolWidgets{$tasktool},
                             SIGNAL "backButtonWasClicked(char*)",
                             SLOT   "taskBackButton(char*)");
      Qt::Object::disconnect($currTaskToolWidgets{$tasktool},
                             SIGNAL "nextButtonWasClicked(char*)",
                             SLOT   "taskNextButton(char*)");
    }
}

sub disconnectHelper
{
#########################################################################

=item C<disconnectHelper($key)>

Disconnect SIGNAL/SLOT connections for a Helper.

This subroutine takes in the 'key' for the $currHelperWidgets hash (which is
formed by joining the Helper directory name and all of the string parameters
used when the Helper was created, all separated by "\000"), and removes any
connections created when the Helper was launched.

=cut

### @param $key The hash key for the $currHelperWidgets hash, which is
###             formed by joining the Helper directory name and all of the
###             Helper's parameters, separated by "\000".
### @see connectHelper()

#########################################################################
  my $key = shift;

  Qt::Object::disconnect($currHelperWidgets{$key},
                        SIGNAL "taskToolClosing(char*)",
                        SLOT   "taskToolClosed(char*)");
}

sub launchTaskTool
{
#########################################################################

=item C<launchTaskTool($dirname)>

Create a new window instance of a given Task/Tool.

This is called by openTaskToolWindow to start a new instance of a given
Task/Tool.  The Task/Tool is specified by its directory name.  This
subroutine then does some tricky require/import stuff to dynamically launch
a new instance of the $classname QWidget.

=cut

### @param  $dirname The name of the (sub)directory of the Task/Tool to 
###         be launched.  
### @return The newly created Task/Tool widget.

#########################################################################

  my $dirname = shift;

  # The name of the Helper's class, which is the same as the main Perl
  # module for the Helper, minus the .pm extension.
  my $classname = $installerTasksAndTools->{$dirname}->{classname};

  # Get the base directory of the Installer.pl script
  my $installerDir = getScriptDir();
  
  return if ((!(-d "$installerDir/$dirname")) || 
             (!(-e "$installerDir/$dirname/$classname.pm")));

  # Prepend the Task/Tool directory to Perl's @INC array.  We can't do
  # 'use' for the following statements since 'use' is done at compile time
  # and the dirname and classname aren't known until run time.
  if (!$alreadyImported{$classname})
    { # Only need to do require/import once per class
      unshift(@INC,"$installerDir/$dirname");
      require $classname. '.pm';
      import $classname;
      $alreadyImported{$classname} = 1;
    }
  no strict 'refs'; # Needed so that the next statement doesn't complain
  my $widget = &$classname(installerWorkspace);
  $widget->show;
  
  return $widget;   # Return the newly created widget
}

sub launchHelper
{
#########################################################################

=item C<launchHelper($parent,$dirname,$params)>

Create a new instance of a particular Helper using the passed-in parameters.

This subroutine is called by openHelperWindow to start a new instance of a
given Helper using a given set of parameters.  Similar to launchTaskTool(),
this subroutine imports the Helper's directory and creates a new Helper
object, passing it the appropriate parameters.

=cut

### @param $parent  The Task/Tool/Helper Qt object that is requesting the
###                 launch of a new Helper.
### @param $dirname The directory name of the Helper to be shown.  
### @param $params  A reference to a list of strings which are parameters
###                 to be passed to the new Helper upon object creation.

#########################################################################

  my($parent,$dirname,$params) = @_;

  # The name of the Helper's class, which is the same as the main Perl
  # module for the Helper, minus the .pm extension.
  my $classname = $installerTasksAndTools->{$dirname}->{classname};

  # Get the base directory of the Installer.pl script
  my $installerDir = getScriptDir();
  
  return if ((!(-d "$installerDir/$dirname")) || 
             (!(-e "$installerDir/$dirname/$classname.pm")));

  # Prepend the Helper directory to Perl's @INC array.  We can't do 'use'
  # for the following statements since 'use' is done at compile time and 
  # the dirname and classname aren't known until run time.
  if (!$alreadyImported{$classname})
    { # Only need to do require/import once per class
      unshift(@INC,"$installerDir/$dirname");
      require $classname. '.pm';
      import $classname;
      $alreadyImported{$classname} = 1;
    }
  no strict 'refs'; # Needed so that the next statement doesn't complain
  my $widget = &$classname($parent,$params);
  $widget->show;
  
  return $widget;   # Return the newly created widget
}

sub processOdaCommandsAndTests
{
#########################################################################

=item C<processOdaCommandsAndTests($tasktool)>

Run all prerequisite oda commands/tests for a Task.

This subroutine is called by tasksMenuActivated() to run all <oda>...</oda>
statements in the GUI.xml file.  These act as prerequisites for a Task being
allowed to run.  The commands/tests are stored in the
$installerTasksAndTools hash as follows:

  @{$installerTasksAndTools->{$taskdir}->{command}} - array of <command> tags
  @{$installerTasksAndTools->{$taskdir}->{test}}    - array of <test> tags
  @{$installerTasksAndTools->{$taskdir}->{error}}   - array of <error> tags

Since there can be multiple <oda> tags in a GUI.xml file, they are stored as
arrays, where C<...->{command}[1]> corresponds to C<...->{test}[1]> and
C<...->{error}[1]>.  The results of the oda commands/tests and (if needed)
error strings are also stored in the $installerTasksAndTools hash as
follows:
  
  @{$installerTasksAndTools->{$taskdir}->{testSuccess}} - array of test results
  @{$installerTasksAndTools->{$taskdir}->{errorString}} - array of error texts

=cut

### @param $task The directory name of the Task to be tested.  

#########################################################################

  my $task = shift;
  my $success = 1;   # Assume success for all oda commands/tests

  # Clear out the result arrays from any previous executions
  @{$installerTasksAndTools->{$task}->{testSuccess}} = ();
  @{$installerTasksAndTools->{$task}->{errorString}} = ();

  my $cmdcnt = 0;
  $cmdcnt = scalar(@{$installerTasksAndTools->{$task}->{command}}) if 
    (defined ($installerTasksAndTools->{$task}->{command}));
  for (my $i = 0; $i < $cmdcnt; $i++)
    {
      # Set the appropriate global variables in InstallerUtils corresponding
      # to the <command> and <test> tags.
      $InstallerUtils::activeOdaCommand = 
        $installerTasksAndTools->{$task}->{command}[$i];
      $InstallerUtils::activeTestCode =
        $installerTasksAndTools->{$task}->{test}[$i];

      # Run the oda command and associated test for current <command>/<test>
      $installerTasksAndTools->{$task}->{testSuccess}[$i] =
        InstallerUtils::runActiveOdaTest();
      if (!$installerTasksAndTools->{$task}->{testSuccess}[$i])
        { # Upon test failure, set the global variable in InstallerUtils
          # corresponding to the <error> tag and get the resulting error
          # string to be displayed in the error details section of the
          # error dialog box.
          $success = 0; # This means at least one oda command/test failed
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

A SLOT which is called when a Task/Tool/Helper closes.

When a Task/Tool/Helper exits (closes), it should send the SIGNAL
'taskToolClosing($tasktool)' so that the MainWindow can update the list of
currently running Tasks/Tools/Helpers.  Note that for Tasks/Tools, the
$tasktool parameter is simply the directory name of the Task/Tool.  For
Helpers, the $tasktool parameter is a string formed by 'join'ing the
Helper's directory name and all of its parameters, using the character
"\000" as the joiner.

This subroutine also removes the connections set up when the
Task/Tool/Helper was created.

=cut

### @param $tasktool For Tasks/Tools the directory name of the Task/Tool
###                  which has closed, or for Helpers, the string formed by
###                  'join "\000", $helperDir, @{ $refParamList }'.

#########################################################################

  my $tasktool = shift;

  # First, check if it was a Helper (with parameters) that closed
  if ($currHelperWidgets{$tasktool})
    {
      disconnectHelper($tasktool);
      delete $currHelperWidgets{$tasktool};
    }
  else # Now check if it was a Task/Tool that closed
    {
      disconnectTaskTool($tasktool);
      delete $currTaskToolWidgets{$tasktool};
    }
}

sub taskBackButton
{
#########################################################################

=item C<taskBackButton($tasktool)>

A SLOT which is called when a Task signals that its Back button was pressed.

When a Task's Back button pressed, the Task emits a signal to let the
MainWindow know to try to go to the previous Task (step).  It simply calls
taskBackNextButtonPressed with -1 and lets that subroutine handle the messy
details.

=cut

### @param $task The directory name of the Task which said that its Back
###              button was pressed.
### @see taskBackNextButtonPressed()

#########################################################################

  taskBackNextButtonPressed(shift,-1);
}

sub taskNextButton
{
#########################################################################

=item C<taskNextButton($tasktool)>

A SLOT which is called when a Task signals that its Next button was pressed.

When a Task's Next button pressed, the Task emits a signal to let the
MainWindow know to try to go to the next Task (step).  It simply calls
taskBackNextButtonPressed with +1 and lets that subroutine handle the messy
details.

=cut

### @param $task The directory name of the Task which said that its Next
###              button was pressed.
### @see taskBackNextButtonPressed()

#########################################################################

  taskBackNextButtonPressed(shift,1);
}

sub taskBackNextButtonPressed
{
#########################################################################

=item C<taskBackNextButtonPressed($task,$backnext)>

Called when a Task has its Back/Next button pressed.

When a Task's Back/Next button is pressed, we should try to go to the
previous/next step in the installation process.  We first check to verify
that the previous/next step actually exists (i.e. prevent out of array range
errors) and then call tasksMenuActivated with the new Task array position to
do the messy work.

=cut

### @param $task The directory name of the Task which said that its 
###              Back/Next button was pressed.
### @param $backnext -1 for Back / +1 for Next

#########################################################################

  my($task,$backnext) = @_;
 
  my $arraypos = -1;  # Assume lookup failure
  # Find location of the $task in the sorted array of Tasks
  for (my $i = 0; $i <= $#installerTasksSorted; $i++)
    {
      if ($installerTasksSorted[$i] eq $task)
        {
          $arraypos = $i;
          last;
        }
    }

  # If we didn't find the Task for some weird reason, do nothing.  Also, if
  # the previous/next step would be out of bounds of the array (again for
  # some weird reason since the Back/Next buttons should be hidden on the
  # first/last Tasks respectively), do nothing.
  my $newarraypos = $arraypos + $backnext;
  return if (($arraypos == -1) ||
             ($newarraypos < 0) ||
             ($newarraypos > $#installerTasksSorted));

  # If we got this far, then then try to launch the new Task
  tasksMenuActivated($newarraypos);
}

sub showErrorDialog
{
#########################################################################

=item C<showErrorDialog($task)>

Show an error dialog box when prerequisite oda commands/tests fail for a
Task.

When we try to launch a Task, we must first run all of the oda
commands/tests in the GUI.xml file and return success for all of them.
These act as prerequisites for the Task to be able to run.  If any of these
commands/tests fails, we pop up an error dialog box showing that we couldn't
launch the Tasks and a "Details" button allowing the user to see which tests
failed.

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
      $errortext .= $installerTasksAndTools->{$task}->{errorString}[$i] . "\n"
        if (!($installerTasksAndTools->{$task}->{testSuccess}[$i]));
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

Last Modified on June 20, 2007 by Geoffroy Vallee (valleegr@ornl,gov).

=cut

#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
# 06/20/07  Restart the effort on the Qt GUI. Add debugging info. By    #
#           Geoffroy Vallee <valleegr@ornl.gov>                         #
#########################################################################

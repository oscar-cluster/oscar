/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename slots use Qt Designer which will
** update this file, preserving your code. Create an init() slot in place of
** a constructor, and a destroy() slot in place of a destructor.
*****************************************************************************/

void Selector::init()
{
#########################################################################
#  Subroutine: init                                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This code gets called after the widget is created but before it gets #
#  displayed.  This is so we can populate the packageTable, as well     #
#  as any other setup work.                                             #
#########################################################################

  # Update info boxes when row selection changes.
  Qt::Object::connect(packageTable, SIGNAL 'selectionChanged()',
                                    SLOT 'rowSelectionChanged()');

  # If there is a parent of this MainWindow, then we are probably running
  # it in the InstallerWorkspace.  Need to catch some signals.
  if (parent())
    {
      Qt::Object::connect(parent(),SIGNAL 'signalButtonShown(char*,char*,bool)',                                   SLOT   'setButtonShown(char*,char*,bool)');
      Qt::Object::connect(parent(),SIGNAL 'odaWasUpdated(char*)',
                                   SLOT   'reReadOda(char*)');
    }
  else
    { # For Tasks, hide the Back/Next buttons if not running inside
      # the InstallerWorkspace window.
      backButton->hide();
      nextButton->hide();
    }

  # When this window closes, destroy it, too
  setWFlags(getWFlags() | Qt::WDestructiveClose());

  packageTable->populateTable();
}

void Selector::closeButton_clicked()
{
#########################################################################
#  Subroutine: exitButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the exitButton is clicked, quit the application.                #
#########################################################################

  this->close(1);
}

void Selector::backButton_clicked()
{
#########################################################################
#  Subroutine: backButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  emit backButtonWasClicked(className());
}


void Selector::nextButton_clicked()
{
#########################################################################
#  Subroutine: nextButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  emit nextButtonWasClicked(className());
}

void Selector::updateTextBox()
{
#########################################################################
#  Subroutine: updateTextBox                                            #
#  Parameters: (1) Which box to update (provides/requires/conflicts)    #
#              (2) Which package to provide info for                    #
#  Returns   : Nothing                                                  #
#  This subroutine is called by rowSelectedChanged to update the one    #
#  of the three informational boxes providesTextBox, requiresTextBox,   #
#  or conflictsTextBox.  Give it one of "provides", "requires", or      #
#  "conflicts", and the name of the package to provide info for.        #
#########################################################################

  my $box = shift;
  my $package = shift;

  my $output = "";

  foreach my $row ( @{ $SelectorUtils::allPackages->{$package}{$box} } )
    {
      $output .= $row->{type} . ": " . $row->{name} . "\n";
    }
  # Use a sneaky 'eval' technique to choose the correct TextBox component
  my $cmd = $box . 'TextBox->setText($output)';
  eval $cmd;
}

void Selector::rowSelectionChanged()
{
#########################################################################
#  Subroutine: rowSelectedChanged                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This slot get called when a new row is selected in the packageTable. #
#  We update the four text boxes at the bottom of the window:           #
#  information (description), provides, requires, and conflicts.        #
#########################################################################

  # Figure out which row of the table is now selected
  my $row = packageTable->selection(0)->anchorRow();

  return if ($row < 0);

  # Find the "short name" of the package in that row
  my $package = packageTable->text($row,0);

  # Update the four infomrational text boxes
  informationTextBox->setText(
    $SelectorUtils::allPackages->{$package}{description});
  updateTextBox("provides",$package);
  updateTextBox("requires",$package);
  updateTextBox("conflicts",$package);

  # Update the packager names / emails
  # We read in the names/emails as a single string, but there might have
  # been more than one packager.  If so , the delimiter is '","'.
  my @names = split /\",\"/, 
    $SelectorUtils::allPackages->{$package}{packager_name};
  my @emails = split /\",\"/, 
    $SelectorUtils::allPackages->{$package}{packager_email};
  my $packagerStr = "";
  for (my $arraypos = 0; $arraypos <= $#names; $arraypos++)
    {
      $packagerStr .= $names[$arraypos];
      $packagerStr .= " <" . $emails[$arraypos] . ">" if
        (length $emails[$arraypos] > 0);
      $packagerStr .= "\n";
    }
  packagerTextBox->setText($packagerStr);
}

void Selector::reReadOda(char*)
{
#########################################################################
#  Subroutine: reReadOda                                                #
#  Parameter : The directory name of the Task/Tool that updated oda.    #
#  Returns   : Nothing                                                  #
#  This subroutine (SLOT) gets called when a Task/Tool tells the        #
#  InstallerWorkspace that the oda database has been updated.           #
#########################################################################

  my $classname = shift;
  
  # Ignore the signal if I generated it.
  return if ($classname eq className());
}

void Selector::setButtonShown( char *, char *, bool )
{
#########################################################################
#  Subroutine: setButtonShown                                           #
#  Parameters: (1) The name of the target task/tool for the signal      #
#              (2) The name of the button to show/hide ("Back"/"Next")  #
#              (3) 1 = Show / 0 = Hide                                  #
#  Returns   : Nothing                                                  #
#  This subroutine is called to show/hide the Back/Next button,         #
#  usually when the parent InstallerWorkspace says to.                  #
#########################################################################

  my ($childname,$buttonname,$shown) = @_;
  
  # Ignore signals meant for other Tasks/Tools
  return if ($childname ne className());

  if ($buttonname =~ /Back/i)
    {
      ($shown) ? backButton->show() : backButton->hide();
    }
  elsif ($buttonname =~ /Next/i)
    {
      ($shown) ? nextButton->show() : nextButton->hide();
    }
}

void Selector::closeEvent( QCloseEvent * )
{
#########################################################################
#  Subroutine: closeEvent                                               #
#  Parameter : A pointer to the QCloseEvent generated.                  #
#  Returns   : Nothing                                                  #
#########################################################################

  # Send a signal to the parent workspace letting it know we are closing.
  emit taskToolClosing(className());
  SUPER->closeEvent(@_);   # Call the parent's closeEvent
}


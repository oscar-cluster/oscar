/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename slots use Qt Designer which will
** update this file, preserving your code. Create an init() slot in place of
** a constructor, and a destroy() slot in place of a destructor.
*****************************************************************************/

void Opder::init()
{
#########################################################################
#  Subroutine: init                                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This code gets called after the widget is created but before it gets #
#  displayed.  This is so we can set up all the connections for SIGNALs #
#  and SLOTs.  Also, since all of the objects seem to need access to    #
#  all the other objects, pass references around.                       #
#  the packageTable, as well as any other setup work.                   #
#########################################################################

  # Create all of the form windows
  downloadInfoForm = OpderDownloadInfo(this,"downloadInfoForm");
  downloadPackageForm = OpderDownloadPackage(this,"downloadPackageForm");
  addRepositoryForm = OpderAddRepository(this,"addRepositoryForm");

  # Connect the SIGNALs and SLOTs
  Qt::Object::connect(packageTable,        SIGNAL 'selectionChanged()',
                      this,                SLOT   'rowSelectionChanged()');
  Qt::Object::connect(packageTable,        SIGNAL 'downloadButtonDisable()',
                      this,                SLOT   'disableDownloadButton()');
  Qt::Object::connect(packageTable,        SIGNAL 'downloadButtonUpdate()',
                      this,                SLOT   'updateDownloadButton()');
  Qt::Object::connect(downloadInfoForm,    SIGNAL 'readPackagesSuccess()',
                      packageTable,        SLOT   'populateTable()');
  Qt::Object::connect(downloadInfoForm,    SIGNAL 'downloadButtonDisable()',
                      this            ,    SLOT   'disableDownloadButton()');
  Qt::Object::connect(downloadInfoForm,    SIGNAL 'downloadButtonUpdate()',
                      this,                SLOT   'updateDownloadButton()');
  Qt::Object::connect(downloadPackageForm, SIGNAL 'downloadButtonUpdate()',
                      this,                SLOT   'updateDownloadButton()');
  Qt::Object::connect(downloadPackageForm, SIGNAL 'refreshButtonSet(int)',
                      this,                SLOT   'setRefreshButton(int)');
  Qt::Object::connect(addRepositoryForm,   SIGNAL 'refreshTableNeeded()',
                      this,                SLOT   'refreshButton_clicked()');

  # Can't download anything until something is selected
  disableDownloadButton();

  # Simulate a button click for the "Refresh Table" button to get OPD info
  Qt::Timer::singleShot(500, this, SLOT 'refreshButton_clicked()');

  # If there is a parent of this MainWindow, then we are probably running
  # it in the InstallerWorkspace.  Need to catch some signals.
  if (parent())
    {
      Qt::Object::connect(parent(),SIGNAL 'signalButtonShown(char*,char*,bool)',
                                   SLOT   'setButtonShown(char*,char*,bool)');
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
  my $flags = getWFlags();
  setWFlags($flags | Qt::WDestructiveClose());
}

void Opder::closeButton_clicked()
{
#########################################################################
#  Subroutine: closeButton_clicked                                      #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the closeButton is clicked, quit the application.               #
#########################################################################

  this->close(1);
}

void Opder::refreshButton_clicked()
{
#########################################################################
#  Subroutine: refreshButton_clicked                                    #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the "Refresh Table" button is clicked, show the "Downloading    #
#  Package Information..." widget.                                      #
#########################################################################

  downloadInfoForm->show();
}

void Opder::downloadButton_clicked()
{
#########################################################################
#  Subroutine: downloadButton_clicked                                   #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the "Download Selected Packages" button is clicked, show the    #
#  "Downloading Package File" widget.                                   #
#########################################################################

  downloadPackageForm->show();
}

void Opder::backButton_clicked()
{
#########################################################################
#  Subroutine: backButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  emit backButtonWasClicked(className());
}

void Opder::nextButton_clicked()
{
#########################################################################
#  Subroutine: nextButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  emit nextButtonWasClicked(className());
}

void Opder::closeMenuItem_activated()
{
#########################################################################
#  Subroutine: closeMenuItem_activated                                  #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine is called when the user selects Close from the File  #
#  pulldown menu.  To make things simple, we simply call the code       #
#  that gets executed when the Close button is pressed.                 #
#########################################################################

  closeButton_clicked();
}

void Opder::addRepositoryMenuItem_activated()
{
#########################################################################
#  Subroutine: addRepositoryMenuItem_activated                          #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################
  
  addRepositoryForm->show();
}

void Opder::updateTextBox()
{
#########################################################################
#  Subroutine: updateTextBox                                            #
#  Parameters: (1) Which box to update (provides/requires/conflicts)    #
#              (2) Which array position in the @readPackages            #
#  Returns   : Nothing                                                  #
#  This subroutine is called by rowSelectedChanged to update the one    #
#  of the three informational boxes providesTextBox, requiresTextBox,   #
#  or conflictsTextBox.  Give it one of "provides", "requires", or      #
#  "conflicts", and the name of the package to provide info for.        #
#########################################################################

  my $box = shift;
  my $arraypos = shift;

  my $output = "";
  my $readPackages = downloadInfoForm->getReadPackages();

  foreach my $row ( @{ @{$readPackages}[$arraypos]->{$box} } )
    {
      $output .= $row->{type} . ": " . $row->{name} . "\n"; 
    }
  # Use a sneaky 'eval' technique to choose the correct TextBox component
  my $cmd = $box . 'TextBox->setText($output)';
  eval $cmd;
}

void Opder::rowSelectionChanged()
{
#########################################################################
#  Subroutine: rowSelectedChanged                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This slot get called when a new row is selected in the packageTable. #
#  We update the five text boxes at the bottom of the window:           #
#  information (description), provides, requires, conflicts, and        #
#  packager.                                                            #
#########################################################################
  
  # Figure out which row of the table is now selected
  my $row = packageTable->selection(0)->anchorRow();

  return if ($row < 0);
  
  # Find the array position of the package in that row
  my $arraypos = packageTable->item($row,0)->text();
  my $readPackages = downloadInfoForm->getReadPackages();

  # Update the informational text boxes
  informationTextBox->setText(@{$readPackages}[$arraypos]->{description});
  updateTextBox("provides",$arraypos);
  updateTextBox("requires",$arraypos);
  updateTextBox("conflicts",$arraypos);

  # Update the packager names / emails
  # We read in the names/emails as a single string, but there might have
  # been more than one packager.  If so , the delimiter is '","'.
  my @names = split /\",\"/, @{$readPackages}[$arraypos]->{packager_name};
  my @emails = split /\",\"/, @{$readPackages}[$arraypos]->{packager_email};
  my $packagerStr = "";
  $arraypos = 0;
  for ($arraypos = 0; $arraypos <= $#names; $arraypos++)
    {
      $packagerStr .= $names[$arraypos];
      $packagerStr .= " <" . $emails[$arraypos] . ">" if 
        (length $emails[$arraypos] > 0);
      $packagerStr .= "\n";
    }
  packagerTextBox->setText($packagerStr);
}

void Opder::disableDownloadButton()
{
#########################################################################
#  Subroutine: disableDownloadButton                                    #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine disabled the "Download Selected Packages" button.    #
#########################################################################

  downloadButton->setEnabled(0);
}

void Opder::updateDownloadButton()
{
#########################################################################
#  Subroutine: updateDownloadButton                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine is called to update the status of the "Download      #
#  Selected Package" button.  It checks to see how many check boxes     #
#  are checked in the package table.  If 0, then disable the button.    #
#  Otherwise, enable the button.                                        #
#########################################################################

  my $numchecked = 0;
  for (my $rownum = 0; $rownum < packageTable->numRows(); $rownum++)
    {
      $numchecked++ if packageTable->item($rownum,1)->isChecked();
    }
  downloadButton->setEnabled($numchecked > 0);
}

void Opder::setRefreshButton(int)
{
#########################################################################
#  Subroutine: setRefreshButton                                         #
#  Parameters: 1 = Enable / 0 = Disable                                 #
#  Returns   : Nothing                                                  #
#  This subroutine is called to enable/disable the "Refresh Table"      #
#  button.                                                              #
#########################################################################

  refreshButton->setEnabled(shift);
}

void Opder::setButtonShown( char *, char *, bool )
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

void Opder::closeEvent( QCloseEvent * )
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

void Opder::reReadOda(char*)
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


/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/

void NodeGroupLister::init()
{
  # If there is a parent of this MainWindow, then we are probably running
  # it in the InstallerWorkspace.  Need to connect some signals/slots.
  if (parent())
    {
      Qt::Object::connect(parent(),
                          SIGNAL 'odaWasUpdated(char*)',
                          SLOT   'reReadOda(char*)');
    }
                                                                            
  # When this window closes, destroy it, too
  setWFlags(getWFlags() | Qt::WDestructiveClose());
}

void NodeGroupLister::closeButton_clicked()
{
#########################################################################
#  Subroutine: closeButton_clicked                                      #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the closeButton is clicked, quit the application.               #
#########################################################################
                                                                                
  this->close(1);
}


void NodeGroupLister::newButton_clicked()
{

}


void NodeGroupLister::renameButton_clicked()
{
  # First, get the currently selected Node Group
  my $nodeGroup = nodeGroupListBox->currentText();
  print "Item selected is $nodeGroup\n";
  return if (length(InstallerUtils::compactSpaces($nodeGroup)) < 1);
  return;
  
  # Then, pop up an input dialog box for new group name
  my $ok;
  my $result = Qt::InputDialog::getText(
    "Rename Node Group",
    "Enter a new name for the Node Group\n<B>" .$nodeGroup. '<\B>:',
    Qt::LineEdit::Normal(),
    "",
    \$ok,
    this);
 
  $result = InstallerUtils::compactSpaces($result);
  $result =~ s/\s/\_/g;   # Change spaces to underscores
  if ($ok && (length($result) > 0))
    {
      print "Trying to rename Node Group '$nodeGroup' to '$result'...";
    }
}


void NodeGroupLister::deleteButton_clicked()
{
  # First, get the currently selected Node Group
  my $nodeGroup = nodeGroupListBox->currentText();
  print "Item selected is $nodeGroup\n";
  return if (length(InstallerUtils::compactSpaces($nodeGroup)) < 1);
  return;
  
  # Then, pop up a confirmation message box
  my $result = Qt::MessageBox::warning(this,
    "Delete Node Group?",
    "Are you sure you want to delete the Node Group\n".
    '<B>' . $nodeGroup . '</B>?',
    Qt::MessageBox::Yes(),
    Qt::MessageBox::No());
 
  # Delete the node group if user clicked 'Yes'
  if ($result == Qt::MessageBox::Yes())
    {
      print "Trying to delete Node Group '$nodeGroup'...";
    }
}


void NodeGroupLister::modifyButton_clicked()
{

}


void NodeGroupLister::nodeGroupListBox_highlighted( QListBoxItem * )
{
  my $hilitedItem = shift;

  my $nodeGroupText = nodeGroupListBox->currentText();
  print "New item highlighted: '$nodeGroupText'\n";

  enableButtons(!(nodeGroupIsSpecial($nodeGroupText)));

  refreshTextBoxes();
}


void NodeGroupLister::enableButtons( int )
{
  my $enable = shift;

  renameButton->setEnabled($enable);
  deleteButton->setEnabled($enable);
  modifyButton->setEnabled($enable);
}


void NodeGroupLister::reReadOda( char * )
{
#########################################################################
#  Subroutine: reReadOda                                                #
#  Parameter : The directory name of the Task/Tool that updated oda     #
#  Returns   : Nothing                                                  #
#  This subroutine (SLOT) is called the InstallerWorkspace receives     #
#  notice that another Task/Tool updated the oda database.              #
#########################################################################

  my ($childname) = @_;
                                                                            
  # Ignore the signal if we were the one that updated oda
  return if ($childname ne className());
                                                                            
  # Reread the oda database and update the GUI as necessary
  # ...
}

void NodeGroupLister::closeEvent( QCloseEvent * )
{
#########################################################################
#  Subroutine: closeEvent                                               #
#  Parameter : A pointer to the QCloseEvent generated.                  #
#  Returns   : Nothing                                                  #
#########################################################################

  # Send a signal to the parent workspace letting it know we are closing.
  emit taskToolClosing(className());
  SUPER->closeEvent(@_);   # Call the parents closeEvent
}





void NodeGroupLister::showEvent()
{
  refreshNodeGroupListBox();
}

void NodeGroupLister::refreshNodeGroupListBox()
{
  nodeGroupListBox->clear();
  my @nodeGroups = ();
#  my @nodeGroups = OSCAR::Database::database_return_list("node_groups# ");
  foreach my $group (sort @nodeGroups)
    {
      nodeGroupListBox->insertItem($group);
    }
}



void NodeGroupLister::nodeGroupIsSpecial( char * )
{
  my $nodeGroup = shift;
  my $retval = 0;

  # The node groups named 'all', 'oscar_clients', and 'oscar_server' are
  # always special and cannot be modified by the user.
  $retval = 1 if (($nodeGroup eq 'all') or
                  ($nodeGroup eq 'oscar_clients') or
                  ($nodeGroup eq 'oscar_server'));

  # Check to see if the nodeGroup is one of the special groups that contains
  # only the single node with the same name as the node group.
#  $retval = (OSCAR::Database::database_return_list(
#    "read_records node_groups name =$nodeGroup special"))[0] if
#     (!$retval);

  return $retval;
}


void NodeGroupLister::refreshMembershipListBoxes()
{
  
}

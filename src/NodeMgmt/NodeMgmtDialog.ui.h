/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/

void NodeMgmtDialog::init()
{    
#   $nodes = OSCAR::Database::database_execute_command("read_records nodes id!=1");
    @macs = ();
# set up advanced widget group as an extension
    advancedBox->hide();
    Qt::Object::connect(advancedButton,
		      SIGNAL 'toggled(bool)',
		      this,
		      SLOT 'advancedButton_toggled(bool)');
    
# set up pages of collection methods in the widgetstack
    collectionmethod->addWidget(network, 0);
    collectionmethod->addWidget(file, 1);
    collectionmethod->addWidget(manual, 2);
    
# create instance of the settings dialog
  settingsDialog = NodeSettingsDialog(this,"settingsDialog");
  Qt::Object::connect(settingsDialog->nodesettingsOK ,
		      SIGNAL 'clicked()',
		      this,
		      SLOT 'refreshsamplenode()');
  
#create instance of Qt::Process to run mac_collector
  mac_collectorProcess = Qt::Process("$ENV{OSCAR_HOME}/scripts/mac_collector", this, 'mac_collectorProcess');
  Qt::Object::connect(mac_collectorProcess,
		      SIGNAL 'processExited()',
		      this,
		      SLOT 'stopnetcollection()');
  Qt::Object::connect(mac_collectorProcess,
		      SIGNAL 'readyReadStdout()',
		      this,
		      SLOT 'getcollectedmacs()');

# If there is a parent of this window, then we are probably running
# it in the InstallerWorkspace.  Need to connect some signals/slots.
  if (parent()) {
      Qt::Object::connect(parent(),
                          SIGNAL 'signalButtonShown(char*,char*,bool)',
                          SLOT   'setButtonShown(char*,char*,bool)');
      Qt::Object::connect(parent(),
                          SIGNAL 'odaWasUpdated(char*)',
                          SLOT   'reReadOda(char*)');
  } else {
    # For Tasks, hide the Back/Next buttons if not running inside
    # the InstallerWorkspace window.
    backButton->hide();
    nextButton->hide();
  }

  
#create instance of timer for net collection
  macprocessTimer = Qt::Timer(this, "macprocessTimer");
    Qt::Object::connect(macprocessTimer,
			SIGNAL 'timeout()',
			this,
			SLOT 'processnetmacs()');
  
#insert some sample data into the boxen
  my @samplemacs = ( '11:11:11:11:11:11', '22:22:22:22:22:22', '33:33:33:33:33:33' );
  while (my $mac = pop(@samplemacs)) {
      $usedmacs{$mac} = 1;
      othermacs->insertItem($mac);
  }
  @samplemacs = ( '44:44:44:44:44:44', '55:55:55:55:55:55', '66:66:66:66:66:66' );
   while (my $mac = pop(@samplemacs)) {
      $usedmacs{$mac} = 1;
      straymacs->insertItem($mac);
  }
   
   refreshsamplenode();
   if ( $nodes ) { populate_nodetable(); }
   othermacs_dimmer();
   straymacs_dimmer();
   nodeTable->adjustColumn(2);
   nodeTable->adjustColumn(1);
   nodeTable->adjustColumn(3);
   
}

void NodeMgmtDialog::populate_nodetable()
{
    my @results;
    my @fields = qw( nodes.name nics.ip nics.mac );
    my @wheres = qw( nodes.id!=1 nics.node_id=nodes.id );
    oda::read_records( undef, \@fields, \@wheres, \@results, 1, undef);
    for ( my $i = 0; $i < scalar(@results); $i++ ) {
	my $ref = $results[$i];	
#print "DEBUG:: adding " . $$ref{name} . " now\n";
	nodeTable->insertRows($i, 1);
	my $ip = $$ref{ip};
	my $name = $$ref{name};
	my $assmac = $$ref{mac} ? $$ref{mac} : '';
	$usedmacs{$assmac} = 1;
	my $item = Qt::TableItem(nodeTable, 0, $name);
	nodeTable->setItem($i, 1, $item);
	$item = Qt::TableItem(nodeTable, 0, $ip);
	nodeTable->setItem($i, 2, $item);
	$item = Qt::TableItem(nodeTable, 0, $assmac);
	nodeTable->setItem($i, 3, $item);
#print "DEBUG:: added " . $$ref{name} . " just now\n";
    }
}
    
void NodeMgmtDialog::advancedButton_toggled(bool)
{
    my $on = shift;
    if ( $on ) {
	advancedButton->setText("Basic <<");
	advancedBox->show();
    } else {
	advancedButton->setText("Advanced >>");
	advancedBox->hide();
    }
}

void NodeMgmtDialog::nodesettingschange_clicked()
{
# nodesettingschange_clicked opens the node settings dialog
    
  settingsDialog->show();
}

void NodeMgmtDialog::refreshsamplenode()
{
  nodelook->setText("The next node will be created as " . getnextnodename() );
}

void NodeMgmtDialog::defineNnodes()
{
# defineNnodes is used by the Define ( n nodes) button
# it will define the next N nodes, where N is the value in the SpinBox
# it follows up by refreshing the sample text
    
    my $numnodes = definenodesnum->cleanText();
    definenodesnum->setValue(1);
    print "Defining $numnodes nodes\n";
    
    for( my $i = 0; $i < $numnodes; $i++ ) {
	my $nextnode = getnextnodename();
	($nextnode, my $ip) = definenode();
    }
    refreshsamplenode();
}

void NodeMgmtDialog::startnetcollection()
{
    if ( mac_collectorProcess->start() ) {
	stopcollect->setEnabled(1);
	startcollect->setEnabled(0);
	networkcollect->setText("Network (collecting)");
	macprocessTimer->start(500);
    }
}

void NodeMgmtDialog::stopnetcollection()
{
    macprocessTimer->stop();
    mac_collectorProcess->tryTerminate();
#    Qt::Timer::singleShot(1000, mac_collectorProcess, SLOT 'kill()' );
    stopcollect->setEnabled(0);
    startcollect->setEnabled(1);
    networkcollect->setText("Network");
}

void NodeMgmtDialog::processnetmacs()
{
    if (scalar(@macs)) {
	foreach my $mac (@macs) {    
	    unless ( $usedmacs{$mac} == 1 ) {
		$usedmacs{$mac} = 1;
		othermacs->insertItem( $mac );
	    }
	}
	@macs = ();
    }
}

void NodeMgmtDialog::getcollectedmacs()
{
    while (mac_collectorProcess->canReadLineStdout()) {
	while ( my $a = mac_collectorProcess->readLineStdout() ) {
	    push( @macs, $a );
	}
    }
#processnetmacs();
}

void NodeMgmtDialog::importfilebrowse_clicked()
{
    my $file = Qt::FileDialog::getOpenFileName(
	    "$ENV{HOME}",
	    undef,
	    this,
	    "open file dialog",
	    "Choose a file" );
    importmacfile->setText($file);
}

void NodeMgmtDialog::importmacs_clicked()
{
    my @newmacs = OSCAR::MAC::get_from_file( importmacfile->text() );
    while ( my $mac = pop(@newmacs) ) {
	unless ( $usedmacs{$mac} == 1 ) {
	    $usedmacs{$mac} = 1;	
	    othermacs->insertItem($mac);
	}
    }
}

void NodeMgmtDialog::exportmacs_clicked()
{
    my $file = Qt::FileDialog::getSaveFileName(
	    "$ENV{HOME}",
	    undef,
	    this,
	    "save file dialog",
	    "Choose export file" );
#this currently only grabs unassigned MACs!!!    
    my @macs;
    for ( my $i=0; $i < othermacs->count; $i++ ) {
	push @macs, othermacs->text($i);
    }
    OSCAR::MAC::save_to_file($file, @macs);
}

void NodeMgmtDialog::importmanualmac_clicked()
{
    my $mac = manualmac->text();
    if ( $mac = OSCAR::MAC::verify_mac($mac) && $usedmacs{$mac} != 1 ) {
	$usedmacs{$mac} = 1;
	othermacs->insertItem($mac);
	manualmac->clear();
    }
}

void NodeMgmtDialog::straytounass_clicked()
{
    if ( straymacs->currentItem > -1 ) {
	othermacs->insertItem( straymacs->text( straymacs->currentItem() ) );
	straymacs->removeItem( straymacs->currentItem );
    }
    straymacs->clearSelection();
    straymacs_dimmer();
    othermacs_dimmer();
}

void NodeMgmtDialog::allstraytounass_clicked()
{
    for ( my $i = 0; $i < straymacs->count; $i++ ) {
	othermacs->insertItem( straymacs->text( $i ) );
    }
    straymacs->clearSelection();
    straymacs->clear();
    straymacs_dimmer();
    othermacs_dimmer();   
}

void NodeMgmtDialog::unasstostray_clicked()
{
    if ( othermacs->currentItem > -1  ) {
	straymacs->insertItem( othermacs->text( othermacs->currentItem() ) );
	othermacs->removeItem( othermacs->currentItem() );
    }
    othermacs->clearSelection();
    straymacs_dimmer();
    othermacs_dimmer();    
}

void NodeMgmtDialog::allunasstostray_clicked()
{
    for ( my $i = 0; $i < othermacs->count; $i++ ) {
	straymacs->insertItem( othermacs->text( $i ) );
    }
    othermacs->clearSelection();
    othermacs->clear();
    straymacs_dimmer();
    othermacs_dimmer();    
}

void NodeMgmtDialog::clearmacs_clicked()
{
    while ( my $mac = othermacs->text(0) && othermacs->removeItem(0) ) {
	delete $usedmacs{$mac};
    }
    othermacs->clearSelection();
    straymacs_dimmer();
    othermacs_dimmer();    
}

void NodeMgmtDialog::closeDialog_clicked()
{
    stopnetcollection();
    this->close(1);
}

void NodeMgmtDialog::definenode()
{
    my $assmac = shift;
    unless ($assmac) { $assmac = ''; }
    my $name = getnextnodename();
    my $ip = getnextnodeip();
    my $number = settingsDialog->startingnum->text;
    $number++;
    settingsDialog->startingnum->setText( $number );
    settingsDialog->setundopoint();
    
    nodeTable->insertRows($nodes, 1);
    my $item = Qt::TableItem(nodeTable, 0, $name);
    nodeTable->setItem($nodes, 1, $item);
    $item = Qt::TableItem(nodeTable, 0, $ip);
    nodeTable->setItem($nodes, 2, $item);
    $item = Qt::TableItem(nodeTable, 0, $assmac);
    nodeTable->setItem($nodes, 3, $item);
    
    nodeTable->adjustColumn(2);
    nodeTable->adjustColumn(1);
    nodeTable->adjustColumn(3);
    my $interface = NodeSettingsDialog->interface->currentText();
    
    OSCAR::Database::database_execute_command("create_node $name", undef, undef);
    OSCAR::Database::database_execute_command(
	    "create_nic_on_node $interface $name ip~$ip mac~$assmac", undef, undef);
    
    $nodes++;
    return $name, $ip;
}

void NodeMgmtDialog::getnextnodeip()
{
# getnextnodeip will define a single node
# it returns the IP of the next node to be defined
# and increments the IP
    
#this line is waiting for the next_node_ip code
    my $nodeip = settingsDialog->startingip->text;
    my @ip = split(/\./,$nodeip);
    $ip[3]++;
    settingsDialog->startingip->setText(join('.',@ip));
    settingsDialog->setundopoint();
    return $nodeip;
}

void NodeMgmtDialog::getnextnodename()
{
# getnextnodename calculates the name of the next node
# given the current settings of prefix, padding, and number
    
    my $prefix = settingsDialog->nameprefix->text;
    my $padding = settingsDialog->padding->text;
    my $startingnum = settingsDialog->startingnum->text;
    
    my $nextname = $prefix;
    
    if ( length($startingnum) < $padding ) {
	for ( my $i = 0; $i + length($startingnum) < $padding; $i++ ) {
	    $nextname .= '0';
	}
    }
    $nextname .= $startingnum;
    return $nextname;
}

void NodeMgmtDialog::assignmac_clicked()
{
    my $assmac = othermacs->currentText();
    if ( ! $assmac ) {   #no current MAC selected
	return 1;
    }  elsif ( nodeTable->currentSelection == -1 ) { #MAC selected, no node selected
        if ( autodefine->isChecked() && assignblanksfirst->isChecked() ) {
	my $blank = 0;
	print "NYI: Assign MAC, MAC selected, no node selection, assignblanksfirst\n";
	return 1;
        } elsif ( autodefine->isChecked() ) {
	definenode($assmac);
	othermacs->removeItem(othermacs->currentItem());
	othermacs->clearSelection();
	return 0;
        } else { # no auto-define set, so nothing to do
	return 1;
        }
    } else { # MAC selected and node selected
	othermacs->removeItem(othermacs->currentItem());
	othermacs->clearSelection();
	my $row = nodeTable->currentRow;
	my $oldmac = nodeTable->text( $row, 3 );
	my $name = nodeTable->text( $row, 1 );
	my @results;
	OSCAR::Database::database_execute_command("list_nics_on_node $name", 
						  \@results, undef);
	my $interface = $results[0];
	if ( $oldmac ) {
	    othermacs->insertItem($oldmac);
	}
	nodeTable->setText( $row, 3, $assmac );
	OSCAR::Database::database_execute_command("modify_records nics.mac~$assmac nodes.name=$name nics.node_id=nodes.id nics.name=$interface", undef, undef);
    }
}

void NodeMgmtDialog::assignallmacs_clicked() 
{
    if ( othermacs->count > 0 ) { 
	nodeTable->clearSelection;
	othermacs->clearSelection();
    } else { #nothing to do
	return 1;
    }
    my @assmacs;
    for ( my $i = 0; $i < othermacs->count; $i++) {
	push( @assmacs, othermacs->text($i) );
    }
    @assmacs = reverse(@assmacs);
    othermacs->clear();
    
    if ( autodefine->isChecked() && assignblanksfirst->isChecked() ) {
	print "NYI: assignall, assignblanksfirst\n";
    } elsif ( autodefine->isChecked() ) {
        while ( my $assmac = pop(@assmacs) ) {
	    definenode( $assmac );
        }
    } else {
	NODE: for ( my $i = 0; $i < $nodes; $i++ ) {
	    if ( nodeTable->text($i, 3) eq '' ) {
		my $assmac = pop(@assmacs) or last NODE;
		my $name = nodeTable->text( $i, 1 );
		my @results;
		OSCAR::Database::database_execute_command("list_nics_on_node $name",   \@results, undef);
		my $interface = $results[0];
		nodeTable->setText( $i, 3, $assmac );
		OSCAR::Database::database_execute_command("modify_records nics.mac~$assmac nodes.name=$name nics.node_id=nodes.id nics.name=$interface", undef, undef);
	    }
	}
    }
    if ( scalar(@assmacs) ) { 
	@assmacs = reverse(@assmacs);
	foreach (@assmacs) {
	    othermacs->insertItem( $_ ); 
	}
    }
}

void NodeMgmtDialog::unassignmac_clicked()
{
    my $row = nodeTable->currentRow;
     if ( $row == -1 ) { #no node selected
	return 0;
    } else {
	my $unassmac = nodeTable->text( $row, 3 );
	nodeTable->clearSelection();
	unless ( $unassmac eq "" ) {
	    nodeTable->setText( $row, 3, "" );
	    my $name = nodeTable->text( $row, 1 );
	    my @results;
	    OSCAR::Database::database_execute_command("list_nics_on_node $name", \@results, undef);
	    my $interface = $results[0];
	    OSCAR::Database::database_execute_command("modify_records nics.mac~null nodes.name=$name nics.node_id=nodes.id nics.name=$interface", undef, undef);
	    othermacs->insertItem( $unassmac );
	}
    }
}

void NodeMgmtDialog::othermacs_dimmer()
{
    if ( othermacs->currentItem == -1 ) { 
	assignmac->setEnabled(0);
	unasstostray->setEnabled(0);
    } else {
	assignmac->setEnabled(1);
	
	unasstostray->setEnabled(1);
    }
}

void NodeMgmtDialog::straymacs_dimmer()
{
    if ( straymacs->currentItem == -1 ) {
	straytounass->setEnabled(0);
    } else {
	straytounass->setEnabled(1);
    }
}

void NodeMgmtDialog::closeEvent()
{
#########################################################################
#  Subroutine: closeEvent                                               #
#  Parameter : A pointer to the QCloseEvent generated.                  #
#  Returns   : Nothing                                                  #
#########################################################################
    
  # Send a signal to the parent workspace letting it know we are closing.
  emit taskToolClosing("NodeMgmt");
  SUPER->closeEvent(@_);   # Call the parent's closeEvent
}


void NodeMgmtDialog::backButton_clicked()
{
   emit backButtonWasClicked("NodeMgmt");
}


void NodeMgmtDialog::nextButton_clicked()
{
   emit nextButtonWasClicked("NodeMgmt");

}

void NodeMgmtDialog::setButtonShown( char *, char *, bool )
{
#########################################################################
#  Subroutine: setButtonShown                                           #
#  Parameters: (1) The directory name of the target Task for the signal #
#              (2) The name of the button to show/hide ("Back"/"Next")  #
#              (3) 1 = Show / 0 = Hide                                  #
#  Returns   : Nothing                                                  #
#  This subroutine (SLOT) is called to show/hide the Back/Next button,  #
#  usually when the parent InstallerWorkspace says to.                  #
#########################################################################
    my ($childname,$buttonname,$shown) = @_;
      
    # Ignore Hide/Show requests to other Tasks
    return if ($childname ne "NodeMgmt");

    if ($buttonname =~ /Back/i) {
	($shown) ? backButton->show() : backButton->hide();
    } elsif ($buttonname =~ /Next/i) {
        ($shown) ? nextButton->show() : nextButton->hide();
    }
}


void NodeMgmtDialog::reReadOda( char * )
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
    return if ($childname ne "NodeMgmt");

    # Reread the oda database and update the GUI as necessary
    # ...
}


void NodeMgmtDialog::NodeMgmtDialog_toolBarPositionChanged( QToolBar * )
{

}

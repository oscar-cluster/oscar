/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/


void nodesettingsDialog::init()
{
    Qt::Object::connect(nodesettingsCancel,
			SIGNAL 'clicked()',
			this,
			SLOT 'hide()');
    Qt::Object::connect(nodesettingsCancel,
			SIGNAL 'clicked()',
			this,
			SLOT 'restoreundo()');
    
    Qt::Object::connect(nodesettingsOK,
			SIGNAL 'clicked()',
			this,
			SLOT 'hide()');
    Qt::Object::connect(nodesettingsOK,
			SIGNAL 'clicked()',
			this,
			SLOT 'setundopoint()');
#    my $gateway = OSCAR::Database::database_execute_command('  
#    ***GET HOST IP OR PUBLIC GATEWAY*** ');
    
#    my $startingip = ***USE NEXT_NODE_IS LIBRARY***
#    my $netmask = OSCAR::Database::database_execute_command('
#    ***GET HOST NETMASK OR PUBLIC NETMASK*** ');

#    my $startingnum = ***NUM CLIENTS + 1 or last clientnum + 1***
    
#    my @images = ***GET LIST OF AVAILABLE IMAGES***
    
#set undo point
    setundopoint();
}

void nodesettingsDialog::setundopoint()
{
     our ($uprefix, $ustartnum, $ustartip, $upadding, $unetmask, $ugateway, $uinterface, @uinterfaces);
     $uprefix = nameprefix->text;
     $ustartnum = startingnum->text;
     $ustartip = startingip->text;
     $upadding = padding->text;
     $unetmask = netmask->text;
     $ugateway = gateway->text;
     $uinterface = interface->currentItem();
     @uinterfaces = ();
     for ( my $i = 0; $i < interface->count(); $i++ ) {
       push( @uinterfaces, interface->text($i) );
     }
}

void nodesettingsDialog::restoreundo()
{
    our ($uprefix, $ustartnum, $ustartip, $upadding, $unetmask, $ugateway, $uinterface, @uinterfaces);
    nameprefix->setText($uprefix);
    startingnum->setText($ustartnum);
    startingip->setText($ustartip);
    padding->setText($upadding);
    netmask->setText($unetmask);
    gateway->setText($ugateway);
    interface->clear();
    foreach my $int (@uinterfaces) {
	interface->insertItem($int); 
    }
    interface->setCurrentItem($uinterface);   
}


# Form implementation generated from reading ui file 'Opder.ui'
#
# Created: Tue Oct 21 16:40:45 2003
#      by: The PerlQt User Interface Compiler (puic)
#
# Note that we do not use puic anymore to modify this file. This capability has
# been lost, therefore we directly modify this file.
#


use strict;
use utf8;


package Qt::Opder;
use Qt;
use Qt::OpderTable;
use Qt::isa qw(Qt::MainWindow);
use Qt::slots
    init => [],
    aboutButton_clicked => [],
    exitButton_clicked => [],
    refreshButton_clicked => [],
    downloadButton_clicked => [],
    previousButton_clicked => [],
    nextButton_clicked => [],
    exitMenuItem_activated => [],
    addRepositoryMenuItem_activated => [],
    updateTextBox => [],
    rowSelectionChanged => [],
    disableDownloadButton => [],
    updateDownloadButton => [],
    setRefreshButton => ['int'];
use Qt::attributes qw(
    titleLabel
    titleLabel_font
    refreshButton
    refreshButton_font
    downloadButton
    downloadButton_font
    aboutButton
    packageTable
    packageTabWidget
    informationTab
    informationTextBox
    providesTab
    providesTextBox
    conflictsTab
    conflictsTextBox
    requiresTab
    requiresTextBox
    packagerTab
    packagerTextBox
    previousButton
    previousButton_font
    exitButton
    exitButton_font
    nextButton
    nextButton_font
    menubar
    PopupMenu
    addRepositoryMenuItem
    exitMenuItem
);

use OpderDownloadPackage;
use OpderAbout;
use Qt::attributes qw( aboutForm downloadInfoForm downloadPackageForm addRepositoryForm );
use OpderDownloadInfo;
use Qt::OpderImages;
use OpderAddRepository;

sub uic_load_pixmap_Opder
{
    my $pix = Qt::Pixmap();
    my $m = Qt::MimeSourceFactory::defaultFactory()->data(shift);

    if($m)
    {
        Qt::ImageDrag::decode($m, $pix);
    }

    return $pix;
}


sub NEW
{
    shift->SUPER::NEW(@_[0..2]);
    statusBar();

    if( name() eq "unnamed" )
    {
        setName("Opder");
    }
    resize(676,517);
    setCaption(trUtf8("OSCAR Package Downloader"));

    setCentralWidget(Qt::Widget(this, "qt_central_widget"));
    my $OpderLayout = Qt::GridLayout(centralWidget(), 1, 1, 11, 6, '$OpderLayout');

    my $Layout49 = Qt::VBoxLayout(undef, 0, 6, '$Layout49');

    my $Layout48 = Qt::HBoxLayout(undef, 0, 6, '$Layout48');

    my $Layout46 = Qt::VBoxLayout(undef, 0, 6, '$Layout46');

    titleLabel = Qt::Label(centralWidget(), "titleLabel");
    titleLabel_font = Qt::Font(titleLabel->font);
    titleLabel_font->setFamily("Helvetica [Urw]");
    titleLabel_font->setPointSize(24);
    titleLabel_font->setBold(1);
    titleLabel_font->setItalic(1);
    titleLabel->setFont(titleLabel_font);
    titleLabel->setFrameShape(&Qt::Label::NoFrame);
    titleLabel->setFrameShadow(&Qt::Label::Plain);
    titleLabel->setText(trUtf8("OSCAR Package Downloader"));
    titleLabel->setAlignment(int(&Qt::Label::AlignCenter));
    $Layout46->addWidget(titleLabel);

    my $Layout45 = Qt::HBoxLayout(undef, 0, 6, '$Layout45');

    refreshButton = Qt::PushButton(centralWidget(), "refreshButton");
    refreshButton_font = Qt::Font(refreshButton->font);
    refreshButton_font->setFamily("Helvetica [Urw]");
    refreshButton_font->setPointSize(14);
    refreshButton->setFont(refreshButton_font);
    refreshButton->setText(trUtf8("&Refresh Table"));
    refreshButton->setIconSet(Qt::IconSet(uic_load_pixmap_Opder("getinfo.png")));
    Qt::ToolTip::add(refreshButton, trUtf8("Get package information from OSCAR repositories"));
    $Layout45->addWidget(refreshButton);

    downloadButton = Qt::PushButton(centralWidget(), "downloadButton");
    downloadButton_font = Qt::Font(downloadButton->font);
    downloadButton_font->setFamily("Helvetica [Urw]");
    downloadButton_font->setPointSize(14);
    downloadButton->setFont(downloadButton_font);
    downloadButton->setText(trUtf8("&Download Selected Packages"));
    downloadButton->setIconSet(Qt::IconSet(uic_load_pixmap_Opder("download.png")));
    Qt::ToolTip::add(downloadButton, trUtf8("Download selected packages from respositories and install on local disk"));
    $Layout45->addWidget(downloadButton);
    $Layout46->addLayout($Layout45);
    $Layout48->addLayout($Layout46);

    aboutButton = Qt::PushButton(centralWidget(), "aboutButton");
    aboutButton->setSizePolicy(Qt::SizePolicy(0, 0, 0, 0, aboutButton->sizePolicy()->hasHeightForWidth()));
    aboutButton->setText(trUtf8(""));
    aboutButton->setPixmap(uic_load_pixmap_Opder("oscarsmall.png"));
    aboutButton->setFlat(1);
    Qt::ToolTip::add(aboutButton, trUtf8("View information about OSCAR"));
    $Layout48->addWidget(aboutButton);
    $Layout49->addLayout($Layout48);

    packageTable = OpderTable(centralWidget(), "packageTable");
    packageTable->setSizePolicy(Qt::SizePolicy(7, 7, 0, 3, packageTable->sizePolicy()->hasHeightForWidth()));
    $Layout49->addWidget(packageTable);

    packageTabWidget = Qt::TabWidget(centralWidget(), "packageTabWidget");
    packageTabWidget->setSizePolicy(Qt::SizePolicy(7, 7, 0, 2, packageTabWidget->sizePolicy()->hasHeightForWidth()));
    packageTabWidget->setTabShape(&Qt::TabWidget::Triangular);
    Qt::ToolTip::add(packageTabWidget, trUtf8("Display of information about the package selected above"));

    informationTab = Qt::Widget(packageTabWidget, "informationTab");
    my $informationTabLayout = Qt::GridLayout(informationTab, 1, 1, 11, 6, '$informationTabLayout');

    informationTextBox = Qt::TextEdit(informationTab, "informationTextBox");
    informationTextBox->setReadOnly(1);

    $informationTabLayout->addWidget(informationTextBox, 0, 0);
    packageTabWidget->insertTab(informationTab, trUtf8("Information"));

    providesTab = Qt::Widget(packageTabWidget, "providesTab");
    my $providesTabLayout = Qt::GridLayout(providesTab, 1, 1, 11, 6, '$providesTabLayout');

    providesTextBox = Qt::TextEdit(providesTab, "providesTextBox");
    providesTextBox->setReadOnly(1);

    $providesTabLayout->addWidget(providesTextBox, 0, 0);
    packageTabWidget->insertTab(providesTab, trUtf8("Provides"));

    conflictsTab = Qt::Widget(packageTabWidget, "conflictsTab");
    my $conflictsTabLayout = Qt::GridLayout(conflictsTab, 1, 1, 11, 6, '$conflictsTabLayout');

    conflictsTextBox = Qt::TextEdit(conflictsTab, "conflictsTextBox");
    conflictsTextBox->setReadOnly(1);

    $conflictsTabLayout->addWidget(conflictsTextBox, 0, 0);
    packageTabWidget->insertTab(conflictsTab, trUtf8("Conflicts"));

    requiresTab = Qt::Widget(packageTabWidget, "requiresTab");
    my $requiresTabLayout = Qt::GridLayout(requiresTab, 1, 1, 11, 6, '$requiresTabLayout');

    requiresTextBox = Qt::TextEdit(requiresTab, "requiresTextBox");
    requiresTextBox->setReadOnly(1);

    $requiresTabLayout->addWidget(requiresTextBox, 0, 0);
    packageTabWidget->insertTab(requiresTab, trUtf8("Requires"));

    packagerTab = Qt::Widget(packageTabWidget, "packagerTab");
    my $packagerTabLayout = Qt::GridLayout(packagerTab, 1, 1, 11, 6, '$packagerTabLayout');

    packagerTextBox = Qt::TextEdit(packagerTab, "packagerTextBox");
    packagerTextBox->setReadOnly(1);

    $packagerTabLayout->addWidget(packagerTextBox, 0, 0);
    packageTabWidget->insertTab(packagerTab, trUtf8("Packager"));
    $Layout49->addWidget(packageTabWidget);

    my $Layout17 = Qt::HBoxLayout(undef, 0, 6, '$Layout17');

    previousButton = Qt::PushButton(centralWidget(), "previousButton");
    previousButton->setEnabled(0);
    previousButton->setSizePolicy(Qt::SizePolicy(1, 1, 1, 0, previousButton->sizePolicy()->hasHeightForWidth()));
    previousButton_font = Qt::Font(previousButton->font);
    previousButton_font->setFamily("Helvetica [Urw]");
    previousButton_font->setPointSize(14);
    previousButton->setFont(previousButton_font);
    previousButton->setText(trUtf8("&Previous"));
    previousButton->setIconSet(Qt::IconSet(uic_load_pixmap_Opder("1leftarrow.png")));
    Qt::ToolTip::add(previousButton, trUtf8("Go to the previous step of the installer"));
    $Layout17->addWidget(previousButton);

    exitButton = Qt::PushButton(centralWidget(), "exitButton");
    exitButton->setSizePolicy(Qt::SizePolicy(1, 1, 2, 0, exitButton->sizePolicy()->hasHeightForWidth()));
    exitButton_font = Qt::Font(exitButton->font);
    exitButton_font->setFamily("Helvetica [Urw]");
    exitButton_font->setPointSize(14);
    exitButton->setFont(exitButton_font);
    exitButton->setText(trUtf8("E&xit"));
    exitButton->setIconSet(Qt::IconSet(uic_load_pixmap_Opder("exit.png")));
    Qt::ToolTip::add(exitButton, trUtf8("Exit the OSCAR Package Downloader"));
    $Layout17->addWidget(exitButton);

    nextButton = Qt::PushButton(centralWidget(), "nextButton");
    nextButton->setEnabled(0);
    nextButton->setSizePolicy(Qt::SizePolicy(1, 1, 1, 0, nextButton->sizePolicy()->hasHeightForWidth()));
    nextButton_font = Qt::Font(nextButton->font);
    nextButton_font->setFamily("Helvetica [Urw]");
    nextButton_font->setPointSize(14);
    nextButton->setFont(nextButton_font);
    nextButton->setText(trUtf8("&Next"));
    nextButton->setIconSet(Qt::IconSet(uic_load_pixmap_Opder("1rightarrow.png")));
    Qt::ToolTip::add(nextButton, trUtf8("Go to the next step of the installer"));
    $Layout17->addWidget(nextButton);
    $Layout49->addLayout($Layout17);

    $OpderLayout->addLayout($Layout49, 0, 0);

    addRepositoryMenuItem= Qt::Action(this, "addRepositoryMenuItem");
    addRepositoryMenuItem->setText(trUtf8("Additional Repositories..."));
    addRepositoryMenuItem->setToolTip(trUtf8("Specify URLs for additional OPD repositories"));
    exitMenuItem= Qt::Action(this, "exitMenuItem");
    exitMenuItem->setText(trUtf8("E&xit"));
    exitMenuItem->setToolTip(trUtf8("Exit program and save state"));




    menubar= Qt::MenuBar( this, "menubar");

    PopupMenu= Qt::PopupMenu(this);
    addRepositoryMenuItem->addTo(PopupMenu);
    PopupMenu->insertSeparator;
    exitMenuItem->addTo(PopupMenu);
    menubar->insertItem(trUtf8("File"), PopupMenu);



    Qt::Object::connect(exitButton, SIGNAL "clicked()", this, SLOT "exitButton_clicked()");
    Qt::Object::connect(previousButton, SIGNAL "clicked()", this, SLOT "previousButton_clicked()");
    Qt::Object::connect(nextButton, SIGNAL "clicked()", this, SLOT "nextButton_clicked()");
    Qt::Object::connect(downloadButton, SIGNAL "clicked()", this, SLOT "downloadButton_clicked()");
    Qt::Object::connect(refreshButton, SIGNAL "clicked()", this, SLOT "refreshButton_clicked()");
    Qt::Object::connect(aboutButton, SIGNAL "clicked()", this, SLOT "aboutButton_clicked()");
    Qt::Object::connect(exitMenuItem, SIGNAL "activated()", this, SLOT "exitMenuItem_activated()");
    Qt::Object::connect(addRepositoryMenuItem, SIGNAL "activated()", this, SLOT "addRepositoryMenuItem_activated()");

    init();
}


sub init
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
  aboutForm = OpderAbout(this,"aboutForm");
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

  # Hide the previous/next buttons until we actually use them later
  previousButton->hide();
  nextButton->hide();

  # Can't download anything until something is selected
  disableDownloadButton();

  # Simulate a button click for the "Refresh Table" button to get OPD info
  Qt::Timer::singleShot(500, this, SLOT 'refreshButton_clicked()');

}

sub aboutButton_clicked
{

#########################################################################
#  Subroutine: aboutButton_clicked                                      #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the mini OSCAR image is clicked, show the About Box form.       #
#########################################################################

  aboutForm->show();

}

sub exitButton_clicked
{

#########################################################################
#  Subroutine: exitButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the exitButton is clicked, quit the application.                #
#########################################################################

  Qt::Application::exit();

}

sub refreshButton_clicked
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

sub downloadButton_clicked
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

sub previousButton_clicked
{

#########################################################################
#  Subroutine: previousButton_clicked                                   #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################


}

sub nextButton_clicked
{

#########################################################################
#  Subroutine: nextButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################


}

sub exitMenuItem_activated
{

#########################################################################
#  Subroutine: exitMenuItem_activated                                   #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine is called when the user selects Exit from the File   #
#  pulldown menu.  To make things simple, we simply call the code       #
#  that gets executed when the Exit button is pressed.                  #
#########################################################################

  exitButton_clicked();

}

sub addRepositoryMenuItem_activated
{

#########################################################################
#  Subroutine: addRepositoryMenuItem_activated                          #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################
  
  addRepositoryForm->show();

}

sub updateTextBox
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

sub rowSelectionChanged
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

sub disableDownloadButton
{

#########################################################################
#  Subroutine: disableDownloadButton                                    #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine disabled the "Download Selected Packages" button.    #
#########################################################################

  downloadButton->setEnabled(0);

}

sub updateDownloadButton
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

sub setRefreshButton
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

1;


package Qt:main;

use Qt;
use Qt::Opder;

my $a = Qt::Application(\@ARGV);
my $w = Opder;
$a->setMainWidget($w);
$w->show;
exit $a->exec;

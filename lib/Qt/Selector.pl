# Form implementation generated from reading ui file 'Selector.ui'
#
# Created: Fri Jun 27 14:08:36 2003
#      by: The PerlQt User Interface Compiler (puic)
#
# WARNING! All changes made in this file will be lost!


use strict;
use utf8;


package Selector;
use Qt;
use SelectorTable;
use Qt::isa qw(Qt::MainWindow);
use Qt::slots
    refreshPackageSetComboBox => [],
    init => [],
    aboutButton_clicked => [],
    manageSetsButton_clicked => [],
    exitButton_clicked => [],
    updateTextBox => [],
    rowSelectionChanged => [];
use Qt::attributes qw(
    titleLabel
    titleLabel_font
    packLabel
    packLabel_font
    packageSetComboBox
    packageSetComboBox_font
    manageSetsButton
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
);

use SelectorUtils;
use Qt::attributes qw( aboutForm manageSetsForm );
use SelectorManageSets;
use SelectorImages;
use SelectorAbout;
use lib "$ENV{OSCAR_HOME}/lib"; use OSCAR::Database;

sub uic_load_pixmap_Selector
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
        setName("Selector");
    }
    resize(540,456);
    setCaption(trUtf8("OSCAR Package Selector"));

    setCentralWidget(Qt::Widget(this, "qt_central_widget"));
    my $SelectorLayout = Qt::GridLayout(centralWidget(), 1, 1, 11, 6, '$SelectorLayout');

    my $Layout7 = Qt::VBoxLayout(undef, 0, 6, '$Layout7');

    my $Layout19 = Qt::HBoxLayout(undef, 0, 0, '$Layout19');

    my $Layout14 = Qt::VBoxLayout(undef, 0, 6, '$Layout14');

    titleLabel = Qt::Label(centralWidget(), "titleLabel");
    titleLabel_font = Qt::Font(titleLabel->font);
    titleLabel_font->setFamily("Helvetica [Urw]");
    titleLabel_font->setPointSize(24);
    titleLabel_font->setBold(1);
    titleLabel_font->setItalic(1);
    titleLabel->setFont(titleLabel_font);
    titleLabel->setFrameShape(&Qt::Label::NoFrame);
    titleLabel->setFrameShadow(&Qt::Label::Plain);
    titleLabel->setText(trUtf8("OSCAR Package Selector"));
    titleLabel->setAlignment(int(&Qt::Label::AlignCenter));
    $Layout14->addWidget(titleLabel);

    my $Layout13 = Qt::HBoxLayout(undef, 0, 6, '$Layout13');

    packLabel = Qt::Label(centralWidget(), "packLabel");
    packLabel->setSizePolicy(Qt::SizePolicy(4, 5, 0, 0, packLabel->sizePolicy()->hasHeightForWidth()));
    packLabel_font = Qt::Font(packLabel->font);
    packLabel_font->setFamily("Helvetica [Urw]");
    packLabel_font->setPointSize(14);
    packLabel_font->setBold(1);
    packLabel->setFont(packLabel_font);
    packLabel->setText(trUtf8("Package Set:"));
    $Layout13->addWidget(packLabel);

    packageSetComboBox = Qt::ComboBox(0, centralWidget(), "packageSetComboBox");
    packageSetComboBox->setSizePolicy(Qt::SizePolicy(3, 5, 0, 0, packageSetComboBox->sizePolicy()->hasHeightForWidth()));
    packageSetComboBox->setPaletteForegroundColor(Qt::Color(0, 85, 255));
    packageSetComboBox_font = Qt::Font(packageSetComboBox->font);
    packageSetComboBox_font->setFamily("Helvetica [Urw]");
    packageSetComboBox_font->setPointSize(14);
    packageSetComboBox_font->setBold(1);
    packageSetComboBox->setFont(packageSetComboBox_font);
    Qt::ToolTip::add(packageSetComboBox, trUtf8("Display the packages in this package set"));
    $Layout13->addWidget(packageSetComboBox);

    manageSetsButton = Qt::PushButton(centralWidget(), "manageSetsButton");
    manageSetsButton->setText(trUtf8("&Manage Sets"));
    Qt::ToolTip::add(manageSetsButton, trUtf8("Add, delete, and rename package sets"));
    $Layout13->addWidget(manageSetsButton);
    $Layout14->addLayout($Layout13);
    $Layout19->addLayout($Layout14);

    aboutButton = Qt::PushButton(centralWidget(), "aboutButton");
    aboutButton->setText(trUtf8(""));
    aboutButton->setPixmap(uic_load_pixmap_Selector("oscarsmall.png"));
    aboutButton->setFlat(1);
    Qt::ToolTip::add(aboutButton, trUtf8("View information about OSCAR"));
    $Layout19->addWidget(aboutButton);
    $Layout7->addLayout($Layout19);

    packageTable = SelectorTable(centralWidget(), "packageTable");
    packageTable->setSizePolicy(Qt::SizePolicy(7, 7, 0, 3, packageTable->sizePolicy()->hasHeightForWidth()));
    $Layout7->addWidget(packageTable);

    packageTabWidget = Qt::TabWidget(centralWidget(), "packageTabWidget");
    packageTabWidget->setSizePolicy(Qt::SizePolicy(7, 7, 0, 2, packageTabWidget->sizePolicy()->hasHeightForWidth()));
    packageTabWidget->setTabShape(&Qt::TabWidget::Triangular);
    Qt::ToolTip::add(packageTabWidget, trUtf8("Display of information about the package selected above"));

    informationTab = Qt::Widget(packageTabWidget, "informationTab");
    my $informationTabLayout = Qt::GridLayout(informationTab, 1, 1, -1, -1, '$informationTabLayout');

    informationTextBox = Qt::TextEdit(informationTab, "informationTextBox");
    informationTextBox->setReadOnly(1);

    $informationTabLayout->addWidget(informationTextBox, 0, 0);
    packageTabWidget->insertTab(informationTab, trUtf8("Information"));

    providesTab = Qt::Widget(packageTabWidget, "providesTab");
    my $providesTabLayout = Qt::GridLayout(providesTab, 1, 1, -1, -1, '$providesTabLayout');

    providesTextBox = Qt::TextEdit(providesTab, "providesTextBox");
    providesTextBox->setReadOnly(1);

    $providesTabLayout->addWidget(providesTextBox, 0, 0);
    packageTabWidget->insertTab(providesTab, trUtf8("Provides"));

    conflictsTab = Qt::Widget(packageTabWidget, "conflictsTab");
    my $conflictsTabLayout = Qt::GridLayout(conflictsTab, 1, 1, -1, -1, '$conflictsTabLayout');

    conflictsTextBox = Qt::TextEdit(conflictsTab, "conflictsTextBox");
    conflictsTextBox->setReadOnly(1);

    $conflictsTabLayout->addWidget(conflictsTextBox, 0, 0);
    packageTabWidget->insertTab(conflictsTab, trUtf8("Conflicts"));

    requiresTab = Qt::Widget(packageTabWidget, "requiresTab");
    my $requiresTabLayout = Qt::GridLayout(requiresTab, 1, 1, -1, -1, '$requiresTabLayout');

    requiresTextBox = Qt::TextEdit(requiresTab, "requiresTextBox");
    requiresTextBox->setReadOnly(1);

    $requiresTabLayout->addWidget(requiresTextBox, 0, 0);
    packageTabWidget->insertTab(requiresTab, trUtf8("Requires"));

    packagerTab = Qt::Widget(packageTabWidget, "packagerTab");
    my $packagerTabLayout = Qt::GridLayout(packagerTab, 1, 1, -1, -1, '$packagerTabLayout');

    packagerTextBox = Qt::TextEdit(packagerTab, "packagerTextBox");
    packagerTextBox->setReadOnly(1);

    $packagerTabLayout->addWidget(packagerTextBox, 0, 0);
    packageTabWidget->insertTab(packagerTab, trUtf8("Packager"));
    $Layout7->addWidget(packageTabWidget);

    my $Layout8 = Qt::HBoxLayout(undef, 0, 6, '$Layout8');

    previousButton = Qt::PushButton(centralWidget(), "previousButton");
    previousButton->setSizePolicy(Qt::SizePolicy(1, 1, 1, 0, previousButton->sizePolicy()->hasHeightForWidth()));
    previousButton_font = Qt::Font(previousButton->font);
    previousButton_font->setFamily("Helvetica [Urw]");
    previousButton_font->setPointSize(14);
    previousButton->setFont(previousButton_font);
    previousButton->setText(trUtf8("&Previous"));
    previousButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("1leftarrow.png")));
    Qt::ToolTip::add(previousButton, trUtf8("Go to the previous step of the installer"));
    $Layout8->addWidget(previousButton);

    exitButton = Qt::PushButton(centralWidget(), "exitButton");
    exitButton->setSizePolicy(Qt::SizePolicy(1, 1, 2, 0, exitButton->sizePolicy()->hasHeightForWidth()));
    exitButton_font = Qt::Font(exitButton->font);
    exitButton_font->setFamily("Helvetica [Urw]");
    exitButton_font->setPointSize(14);
    exitButton->setFont(exitButton_font);
    exitButton->setText(trUtf8("E&xit"));
    exitButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("exit.png")));
    Qt::ToolTip::add(exitButton, trUtf8("Exit the OSCAR Package Selector"));
    $Layout8->addWidget(exitButton);

    nextButton = Qt::PushButton(centralWidget(), "nextButton");
    nextButton->setSizePolicy(Qt::SizePolicy(1, 1, 1, 0, nextButton->sizePolicy()->hasHeightForWidth()));
    nextButton_font = Qt::Font(nextButton->font);
    nextButton_font->setFamily("Helvetica [Urw]");
    nextButton_font->setPointSize(14);
    nextButton->setFont(nextButton_font);
    nextButton->setText(trUtf8("&Next"));
    nextButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("1rightarrow.png")));
    Qt::ToolTip::add(nextButton, trUtf8("Go to the next step of the installer"));
    $Layout8->addWidget(nextButton);
    $Layout7->addLayout($Layout8);

    $SelectorLayout->addLayout($Layout7, 0, 0);



    menubar= Qt::MenuBar( this, "menubar");



    Qt::Object::connect(exitButton, SIGNAL "clicked()", this, SLOT "exitButton_clicked()");
    Qt::Object::connect(aboutButton, SIGNAL "clicked()", this, SLOT "aboutButton_clicked()");
    Qt::Object::connect(manageSetsButton, SIGNAL "clicked()", this, SLOT "manageSetsButton_clicked()");

    setTabOrder(aboutButton, packageSetComboBox);
    setTabOrder(packageSetComboBox, manageSetsButton);
    setTabOrder(manageSetsButton, packageTabWidget);
    setTabOrder(packageTabWidget, informationTextBox);
    setTabOrder(informationTextBox, providesTextBox);
    setTabOrder(providesTextBox, requiresTextBox);
    setTabOrder(requiresTextBox, previousButton);
    setTabOrder(previousButton, exitButton);
    setTabOrder(exitButton, nextButton);

    init();
}


sub refreshPackageSetComboBox
{

#########################################################################
#  Subroutine: refreshPackageSetComboBox                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This is called to repopulate the drop-down combo box listing all of  #
#  the package sets available.  It refreshes the contents of the list   #
#  and then refreshes the contents of the table if the selected item    #
#  is no longer available (due to deletion or rename).                  #
#########################################################################

  # Save the "currently" selected item in the combobox (if anything)
  my $lastText = packageSetComboBox->currentText();
  # Rebuild the list of items in the combobox
  SelectorUtils::populatePackageSetList(packageSetComboBox);
  # Try to reselect the previously selected item if it still exists
  my $foundit = 0;
  if (length $lastText > 0)
    {
      for (my $count = 0; 
           ($count < packageSetComboBox->count()) && (!$foundit);
           $count++)
        {
          if (packageSetComboBox->text($count) eq $lastText)
            {
              $foundit = 1;
              packageSetComboBox->setCurrentItem($count);
            }
        }
    }

  # If the previously selected item was deleted or renamed (or never 
  # existed, like at startup), then we have a different item selected
  # in the packageSetComboBox and we need to refresh the information in 
  # the table for the newly selected package set in that combo box. 
  emit packageSetComboBox->activated(packageSetComboBox->currentText())
    if (!$foundit);

}

sub init
{

#########################################################################
#  Subroutine: init                                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This code gets called after the widget is created but before it gets #
#  displayed.  This is so we can populate the packageSetComboBox and    #
#  the packageTable, as well as any other setup work.                   #
#########################################################################

  # Make sure the database is up and running
  my $success = database_connect();
  if ($success)
    {
      # Create the form windows for SelectorAbout and SelectorManageSets
      aboutForm = SelectorAbout(this,"aboutForm");
      manageSetsForm = SelectorManageSets(this,"manageSetsForm");

      # Set up the SIGNALS / SLOTS connections
      Qt::Object::connect(manageSetsForm, SIGNAL 'refreshPackageSets()', 
                          this, SLOT 'refreshPackageSetComboBox()');
      Qt::Object::connect(packageSetComboBox, 
                          SIGNAL 'activated(const QString&)',
                          packageTable,
                          SLOT 'populateTable(const QString&)');
      Qt::Object::connect(packageTable, SIGNAL 'selectionChanged()',
                          this, SLOT 'rowSelectionChanged()');

      previousButton->hide();
      nextButton->hide();

      # Populate the Package Set ComboBox / packageTable
      refreshPackageSetComboBox();
    }
  else
    {
      Carp::croak("The oda database isn't running.  Quitting"); 
    }

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

sub manageSetsButton_clicked
{

#########################################################################
#  Subroutine: manageSetsButton_clicked                                 #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the "Manage Sets" button is clicked, show the Manage Package    #
#  Sets form.                                                           #
#########################################################################

  manageSetsForm->show();

}

sub exitButton_clicked
{

#########################################################################
#  Subroutine: exitButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the exitButton is clicked, quit the application.                #
#########################################################################

  database_disconnect();
  Qt::Application::exit();

}

sub updateTextBox
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
  my $allPackages = SelectorUtils::getAllPackages();

  foreach my $row ( @{ $allPackages->{$package}{$box} } )
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
#  We update the four text boxes at the bottom of the window:           #
#  information (description), provides, requires, and conflicts.        #
#########################################################################

  # Figure out which row of the table is now selected
  my $row = packageTable->selection(0)->anchorRow();

  return if ($row < 0);

  # Find the "short name" of the package in that row
  my $package = packageTable->text($row,0);
  my $allPackages = SelectorUtils::getAllPackages();

  # Update the four infomrational text boxes
  informationTextBox->setText($allPackages->{$package}{description});
  updateTextBox("provides",$package);
  updateTextBox("requires",$package);
  updateTextBox("conflicts",$package);
  my $packagerStr = $allPackages->{$package}{packager_name};
  $packagerStr .= " <" .  $allPackages->{$package}{packager_email} . ">" if
    (length $allPackages->{$package}{packager_email} > 0);
  packagerTextBox->setText($packagerStr);

}

1;


package main;

use Qt;
use Selector;

my $a = Qt::Application(\@ARGV);
my $w = Selector;
$a->setMainWidget($w);
$w->show;
exit $a->exec;

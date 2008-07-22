# Form implementation generated from reading ui file 'Selector.ui'
#
# Created: Wed Oct 29 21:10:58 2003
#      by: The PerlQt User Interface Compiler (puic)
#
#
# Copyright (c) 2005-2006 The Trustees of Indiana University.  
#                    All rights reserved.
#
# $Id$
#########################################################################
# Note that we do not use puic anymore to modify this file. This capability has
# been lost, therefore we directly modify this file.
#


use strict;
use utf8;


package Selector;
use Qt;
use SelectorTable;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Opkg;
use Qt::isa qw(Qt::MainWindow);
use Qt::slots
    init => [],
    parseCommandLine => [],
    refreshPackageSetComboBox => [],
    aboutButton_clicked => [],
    manageSetsButton_clicked => [],
    exitButton_clicked => [],
    cancelButton_clicked => [],
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
    cancelButton
    cancelButton_font
    nextButton
    nextButton_font
    menubar
);

use SelectorUtils;
use Qt::attributes qw( aboutForm manageSetsForm installuninstall );
use SelectorManageSets;
use SelectorImages;
use SelectorAbout;
use lib "$ENV{OSCAR_HOME}/lib"; use OSCAR::Database;
use Getopt::Long;

my %options = ();
my @errors = ();

$options{debug} = 1 if $ENV{OSCAR_DB_DEBUG};

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
    resize(621,493);
    setCaption(trUtf8("OSCAR Package Selector"));

    setCentralWidget(Qt::Widget(this, "qt_central_widget"));
    my $SelectorLayout = Qt::GridLayout(centralWidget(), 1, 1, 11, 6, '$SelectorLayout');

    my $layout19 = Qt::VBoxLayout(undef, 0, 6, '$layout19');

    my $Layout19 = Qt::HBoxLayout(undef, 0, 0, '$Layout19');

    my $Layout14 = Qt::VBoxLayout(undef, 0, 6, '$Layout14');

    titleLabel = Qt::Label(centralWidget(), "titleLabel");
    titleLabel->setSizePolicy(Qt::SizePolicy(7, 5, 0, 0, titleLabel->sizePolicy()->hasHeightForWidth()));
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
    aboutButton->setSizePolicy(Qt::SizePolicy(0, 0, 0, 0, aboutButton->sizePolicy()->hasHeightForWidth()));
    aboutButton->setText(trUtf8(""));
    aboutButton->setPixmap(uic_load_pixmap_Selector("oscarsmall.png"));
    aboutButton->setFlat(1);
    Qt::ToolTip::add(aboutButton, trUtf8("View information about OSCAR"));
    $Layout19->addWidget(aboutButton);
    $layout19->addLayout($Layout19);

    packageTable = SelectorTable(centralWidget(), "packageTable");
    packageTable->setSizePolicy(Qt::SizePolicy(7, 7, 0, 3, packageTable->sizePolicy()->hasHeightForWidth()));
    $layout19->addWidget(packageTable);

    packageTabWidget = Qt::TabWidget(centralWidget(), "packageTabWidget");
    packageTabWidget->setSizePolicy(Qt::SizePolicy(7, 7, 0, 2, packageTabWidget->sizePolicy()->hasHeightForWidth()));
    packageTabWidget->setTabShape(&Qt::TabWidget::Triangular);
    Qt::ToolTip::add(packageTabWidget, trUtf8("Display of information about the package selected above"));

    informationTab = Qt::Widget(packageTabWidget, "informationTab");
    my $informationTabLayout = Qt::GridLayout(informationTab, 1, 1, 0, 6, '$informationTabLayout');

    informationTextBox = Qt::TextEdit(informationTab, "informationTextBox");
    informationTextBox->setReadOnly(1);

    $informationTabLayout->addWidget(informationTextBox, 0, 0);
    packageTabWidget->insertTab(informationTab, trUtf8("Information"));

    providesTab = Qt::Widget(packageTabWidget, "providesTab");
    my $providesTabLayout = Qt::GridLayout(providesTab, 1, 1, 0, 6, '$providesTabLayout');

    providesTextBox = Qt::TextEdit(providesTab, "providesTextBox");
    providesTextBox->setReadOnly(1);

    $providesTabLayout->addWidget(providesTextBox, 0, 0);
    packageTabWidget->insertTab(providesTab, trUtf8("Provides"));

    conflictsTab = Qt::Widget(packageTabWidget, "conflictsTab");
    my $conflictsTabLayout = Qt::GridLayout(conflictsTab, 1, 1, 0, 6, '$conflictsTabLayout');

    conflictsTextBox = Qt::TextEdit(conflictsTab, "conflictsTextBox");
    conflictsTextBox->setReadOnly(1);

    $conflictsTabLayout->addWidget(conflictsTextBox, 0, 0);
    packageTabWidget->insertTab(conflictsTab, trUtf8("Conflicts"));

    requiresTab = Qt::Widget(packageTabWidget, "requiresTab");
    my $requiresTabLayout = Qt::GridLayout(requiresTab, 1, 1, 0, 6, '$requiresTabLayout');

    requiresTextBox = Qt::TextEdit(requiresTab, "requiresTextBox");
    requiresTextBox->setReadOnly(1);

    $requiresTabLayout->addWidget(requiresTextBox, 0, 0);
    packageTabWidget->insertTab(requiresTab, trUtf8("Requires"));

    packagerTab = Qt::Widget(packageTabWidget, "packagerTab");
    my $packagerTabLayout = Qt::GridLayout(packagerTab, 1, 1, 0, 6, '$packagerTabLayout');

    packagerTextBox = Qt::TextEdit(packagerTab, "packagerTextBox");
    packagerTextBox->setReadOnly(1);

    $packagerTabLayout->addWidget(packagerTextBox, 0, 0);
    packageTabWidget->insertTab(packagerTab, trUtf8("Packager"));
    $layout19->addWidget(packageTabWidget);

    my $layout18 = Qt::HBoxLayout(undef, 11, 6, '$layout18');

    previousButton = Qt::PushButton(centralWidget(), "previousButton");
    previousButton->setSizePolicy(Qt::SizePolicy(1, 1, 1, 0, previousButton->sizePolicy()->hasHeightForWidth()));
    previousButton_font = Qt::Font(previousButton->font);
    previousButton_font->setFamily("Helvetica [Urw]");
    previousButton_font->setPointSize(14);
    previousButton->setFont(previousButton_font);
    previousButton->setText(trUtf8("&Previous"));
    previousButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("1leftarrow.png")));
    Qt::ToolTip::add(previousButton, trUtf8("Go to the previous step of the installer"));
    $layout18->addWidget(previousButton);

    exitButton = Qt::PushButton(centralWidget(), "exitButton");
    exitButton->setSizePolicy(Qt::SizePolicy(1, 1, 2, 0, exitButton->sizePolicy()->hasHeightForWidth()));
    exitButton_font = Qt::Font(exitButton->font);
    exitButton_font->setFamily("Helvetica [Urw]");
    exitButton_font->setPointSize(14);
    exitButton->setFont(exitButton_font);
    exitButton->setText(trUtf8("E&xit"));
    exitButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("exit.png")));
    Qt::ToolTip::add(exitButton, trUtf8("Exit the OSCAR Package Selector"));
    $layout18->addWidget(exitButton);

    cancelButton = Qt::PushButton(centralWidget(), "cancelButton");
    cancelButton->setSizePolicy(Qt::SizePolicy(1, 1, 2, 0, cancelButton->sizePolicy()->hasHeightForWidth()));
    cancelButton_font = Qt::Font(cancelButton->font);
    cancelButton_font->setFamily("Helvetica [Urw]");
    cancelButton_font->setPointSize(14);
    cancelButton->setFont(cancelButton_font);
    cancelButton->setText(trUtf8("&Cancel"));
    cancelButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("cancel.png")));
    Qt::ToolTip::add(cancelButton, trUtf8("Exit and abandon any changes"));
    $layout18->addWidget(cancelButton);

    nextButton = Qt::PushButton(centralWidget(), "nextButton");
    nextButton->setSizePolicy(Qt::SizePolicy(1, 1, 1, 0, nextButton->sizePolicy()->hasHeightForWidth()));
    nextButton_font = Qt::Font(nextButton->font);
    nextButton_font->setFamily("Helvetica [Urw]");
    nextButton_font->setPointSize(14);
    nextButton->setFont(nextButton_font);
    nextButton->setText(trUtf8("&Next"));
    nextButton->setIconSet(Qt::IconSet(uic_load_pixmap_Selector("1rightarrow.png")));
    Qt::ToolTip::add(nextButton, trUtf8("Go to the next step of the installer"));
    $layout18->addWidget(nextButton);
    $layout19->addLayout($layout18);

    $SelectorLayout->addLayout($layout19, 0, 0);



    menubar= Qt::MenuBar( this, "menubar");



    Qt::Object::connect(exitButton, SIGNAL "clicked()", this, SLOT "exitButton_clicked()");
    Qt::Object::connect(aboutButton, SIGNAL "clicked()", this, SLOT "aboutButton_clicked()");
    Qt::Object::connect(manageSetsButton, SIGNAL "clicked()", this, SLOT "manageSetsButton_clicked()");
    Qt::Object::connect(cancelButton, SIGNAL "clicked()", this, SLOT "cancelButton_clicked()");

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

  # Scan the command line for options
  parseCommandLine();

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

  # For now, hide the previous/next buttons, until they are needed
  previousButton->hide();
  nextButton->hide();

  # Modify the GUI depending on whether we are running this script
  # as the "OSCAR Selector" or "Install/Uninstall Packages".
  if (installuninstall > 0)
    {
      this->setCaption("Install/Uninstall OSCAR Packages");
      titleLabel->setText("Install/Uninstall Packages");
      packLabel->hide();
      packageSetComboBox->hide();
      manageSetsButton->hide();
      exitButton->setText('E&xecute');
      Qt::ToolTip::add(packageTable, 
        trUtf8("Green = Will Be Installed, Red = Will Be Uninstalled"));
      Qt::ToolTip::remove(exitButton);
      Qt::ToolTip::add(exitButton,
        "Exit and execute install/uninstall of packages");
    }
  else
    {
      cancelButton->hide();
    }

  # Populate the Package Set ComboBox / packageTable
  refreshPackageSetComboBox();

}

sub parseCommandLine
{

#########################################################################
#  Subroutine: parseCommandLine                                         #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This is called at program init to scan the command line for          #
#  any options.                                                         #
#########################################################################

  $Getopt::Long::autoabbrev = 1;        # Allow abbreviated options
  $Getopt::Long::getopt_compat = 1;     # Allow + for options
  $Getopt::Long::order = $PERMUTE;      # Option reordering
  &GetOptions("installuninstall" => \installuninstall);

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

sub exitButton_clicked {

#########################################################################
#  Subroutine: exitButton_clicked                                       #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the exitButton is clicked, quit the application.                #
#########################################################################

    # If the GUI is running as the 'Updater', then we need to go through
    # the list of all packages and find out which ones need to be installed
    # or uninstalled.  

    my $success;  # Return code for database commands

    # Then scan the table for packages to be installed/uninstalled
    my $allPackages = SelectorUtils::getAllPackages();
    my $packagesInstalled = packageTable->getPackagesInstalled();
    # Flag : selected
    # 0 -> default (Selector has not touched the field)
    # 1 -> unselected
    # 2 -> selected
    my $selected = 0;
    for (my $row = 0; $row < packageTable->numRows(); $row++){
        my $package = packageTable->item($row,0)->text();
        my $checked = packageTable->item($row,1)->isChecked();
        my @pstatus = ();
        my $check = OSCAR::Database::get_node_package_status_with_node_package(
        "oscar_server",$package,\@pstatus, \%options,\@errors);
        my $pstatus_ref = pop @pstatus if $check;
           

        if (($packagesInstalled->{$package}) && (!$checked)){
            # Need to uninstall package
            # status : 1 == should_not_be_installed
           
            $selected  = 1;
            print "Updating Node_Package_Status to should_not_be_installed\n"
               if $options{debug};
            $success = OSCAR::Database::update_node_package_status(  
                     \%options,"oscar_server",$package,1,\@errors,$selected);
        }

        if ((!($packagesInstalled->{$package})) && ($checked)){
            # Need to install package
            # status : 2 == should_be_installed

            $selected  = 2;
            print "Updating Node_Package_Status to should_be_installed\n"
                if $options{debug};
            $success = OSCAR::Database::update_node_package_status(  
                     \%options,"oscar_server",$package,2,\@errors,$selected);
        }
    }

    OSCAR::Database::initialize_selected_flag(\%options,\@errors) 
        if (installuninstall <= 0);
    OSCAR::Opkg::write_pgroup_files();
    Qt::Application::exit();

}

sub cancelButton_clicked
{

#########################################################################
#  Subroutine: cancelButton_clicked                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
########################################################################

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

  # Update the packager names / emails
  my $packagerStr = $allPackages->{$package}{packager};
  $packagerStr =~ s:,\s*:\n:g;
  $packagerStr .= "\n";
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

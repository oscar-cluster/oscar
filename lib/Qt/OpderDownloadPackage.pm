# Form implementation generated from reading ui file 'OpderDownloadPackage.ui'
#
# Created: Wed Jul 30 10:12:49 2003
#      by: The PerlQt User Interface Compiler (puic)
#
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
#
# $Id$
#########################################################################
# WARNING! All changes made in this file will be lost!

use strict;
use utf8;


package OpderDownloadPackage;
use Qt;
use Qt::isa qw(Qt::Dialog);
use Qt::slots
    init => [],
    showEvent => [],
    hideEvent => [],
    cancelButton_clicked => [],
    downloadStart => [],
    downloadNext => [],
    downloadDone => [],
    readFromStdout => [],
    getPackageTable => [],
    updateOda => [];
use Qt::attributes qw(
    downloadLabel
    downloadLabel_font
    packageLabel
    packageLabel_font
    progressBar
    cancelButton
    cancelButton_font
);

my ($dlProc,$dlPhase,$dlString,@dlPackages); # Execute opd and read results
my $opdcmd = $ENV{OSCAR_HOME} . '/scripts/opd';
use Carp;
use Qt::signals refreshButtonSet=>['int'], downloadButtonUpdate=>[];
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Package;

sub uic_load_pixmap_OpderDownloadPackage
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
    shift->SUPER::NEW(@_[0..3]);

    if( name() eq "unnamed" )
    {
        setName("OpderDownloadPackage");
    }
    resize(335,146);
    setCaption(trUtf8("Wait..."));

    my $OpderDownloadPackageLayout = Qt::GridLayout(this, 1, 1, 11, 6, '$OpderDownloadPackageLayout');

    my $Layout33 = Qt::VBoxLayout(undef, 0, 6, '$Layout33');

    downloadLabel = Qt::Label(this, "downloadLabel");
    downloadLabel_font = Qt::Font(downloadLabel->font);
    downloadLabel_font->setFamily("Helvetica [Urw]");
    downloadLabel_font->setPointSize(14);
    downloadLabel_font->setBold(1);
    downloadLabel->setFont(downloadLabel_font);
    downloadLabel->setText(trUtf8("Downloading Package File"));
    downloadLabel->setAlignment(int(&Qt::Label::AlignCenter));
    $Layout33->addWidget(downloadLabel);

    packageLabel = Qt::Label(this, "packageLabel");
    packageLabel->setPaletteForegroundColor(Qt::Color(0, 0, 179));
    packageLabel_font = Qt::Font(packageLabel->font);
    packageLabel_font->setFamily("Helvetica [Urw]");
    packageLabel_font->setBold(1);
    packageLabel->setFont(packageLabel_font);
    packageLabel->setText(trUtf8("FooBar"));
    packageLabel->setAlignment(int(&Qt::Label::AlignCenter));
    $Layout33->addWidget(packageLabel);

    progressBar = Qt::ProgressBar(this, "progressBar");
    progressBar->setSizePolicy(Qt::SizePolicy(7, 0, 0, 0, progressBar->sizePolicy()->hasHeightForWidth()));
    progressBar->setPercentageVisible(0);
    $Layout33->addWidget(progressBar);

    cancelButton = Qt::PushButton(this, "cancelButton");
    cancelButton_font = Qt::Font(cancelButton->font);
    cancelButton_font->setFamily("Helvetica [Urw]");
    cancelButton_font->setPointSize(14);
    cancelButton->setFont(cancelButton_font);
    cancelButton->setText(trUtf8("&Cancel"));
    $Layout33->addWidget(cancelButton);

    $OpderDownloadPackageLayout->addLayout($Layout33, 0, 0);

    Qt::Object::connect(cancelButton, SIGNAL "clicked()", this, SLOT "cancelButton_clicked()");

    init();
}


sub init
{

#########################################################################
#  Subroutine: init                                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine gets called after the widget gets created but before #
#  it is displayed.  It creates the QProcess needed for opd commands.   #
#########################################################################

  $dlProc = Qt::Process(this);
  Qt::Object::connect($dlProc, SIGNAL 'readyReadStdout()', 
                               SLOT   'readFromStdout()');
  Qt::Object::connect($dlProc, SIGNAL 'processExited()',  
                               SLOT   'downloadDone()');

}

sub showEvent
{

#########################################################################
#  Subroutine: showEvent                                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the widget is shown, we need to check to see if it was "newly"  #
#  shown (i.e. by the user clicking on the "Download Selected           #
#  Packages" button) or un-minimized.  In the former case, we need to   #
#  reset the progress bar and start the downloading of packages.  The   #
#  latter case is tested for by checking to see if there is a running   #
#  opd-download process.                                                #
#########################################################################

  # Make sure the opd script is there
  if ((-e $opdcmd) && (-x $opdcmd))
    {
      # If the process isn't running, then reset the progress bar to zero
      if (!($dlProc->isRunning()))
        { 
          # Reset the progress bar to 'empty'
          progressBar->reset();
          progressBar->setTotalSteps(0);
          progressBar->setPercentageVisible(1);
          progressBar->setCenterIndicator(1);
        }

      emit refreshButtonSet(0); # Disable the "Refresh Table" button
      downloadStart();          # Do the acutal work in the background
    }
  else
    {
      Carp::carp("Could not find the 'opd' script");
      Qt::Timer::singleShot(200, this, SLOT 'cancelButton_clicked()');
    }

}

sub hideEvent
{

#########################################################################
#  Subroutine: hideEvent                                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the widget is hidden, one of three things happened: (1) the     #
#  user closed the window by clicking on the "Cancel" button or the     #
#  "close window" button; (2) the QProcess controlling opd completed    #
#  successfuly; or (3) the main window got minimized and this widget    #
#  along with it.  In any case, we need to do some clean up.            #
#########################################################################

  # It could be that the widget got hidden due to the parent window 
  # (i.e. the main window) got minimized.  If so, then don't kill the
  # QProcess controlling opd.  Let it try to finish with the window
  # minimized/hidden.
  if (!(parent()->isMinimized()))
    {
      $dlPhase = 0;
      $dlProc->tryTerminate() if ($dlProc->isRunning());
      Qt::Timer::singleShot(500, $dlProc, SLOT 'kill()');
    }

  emit refreshButtonSet(1);  # Enable the "Refresh Table" button

}

sub cancelButton_clicked
{

#########################################################################
#  Subroutine: cancelButton_clicked                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  hide();

}

sub downloadStart
{

#########################################################################
#  Subroutine: downloadStart                                            #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This gets called when the widget is shown (from showEvent).  It      #
#  sets up the QProcess for downloading package tarballs with opd.      #
#########################################################################

  return if ($dlPhase);  # If we are already downloading, don't do it again

  # Figure out which packages we need to download
  @dlPackages = ();
  my $readPackages = parent()->child('downloadInfoForm')->getReadPackages();
  my $packageTableRef = getPackageTable();
  for (my $rownum = 0; $rownum < $packageTableRef->numRows(); $rownum++)
    {
      if ($packageTableRef->item($rownum,1)->isChecked())
        {
          my $arraypos = $packageTableRef->item($rownum,0)->text();
          push @dlPackages, @{$readPackages}[$arraypos];
        }
    }

  progressBar->setTotalSteps(scalar(@dlPackages));

  $dlPhase = 1;   # dlPhase = the number of package being downloaded
  downloadNext();

}

sub downloadNext
{

#########################################################################
#  Subroutine: downloadNext                                             #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine is called to download the 'next' package with opd.   #
#  It updates the progress bar and then sets up the opd command with    #
#  the URL of the next package tarball.                                 #
#########################################################################

  progressBar->setProgress($dlPhase-1);

  # Make sure we haven't downloaded everything yet
  if ($dlPhase <= scalar(@dlPackages))
    {
      # Update the string showing the package we are downloading
      packageLabel->setText($dlPackages[$dlPhase-1]->{package});

      my @args = ($opdcmd,
                  '--nomaster',
                  '--parsable',
                  '-r',$dlPackages[$dlPhase-1]->{repositoryURL},
                  '--package',$dlPackages[$dlPhase-1]->{downloadURI}[0]); 
      $dlProc->setArguments(\@args);
      $dlString = "";
      if (!$dlProc->start('LC_ALL="C"'))
        {
          Carp::carp("Couldn't download package " . 
                     $dlPackages[$dlPhase]->{package} . " with opd");
        }
    }
  else # All done!
    {
      emit downloadButtonUpdate();
      # Delay 1/2 second to show 100% status in progress bar before hiding
      Qt::Timer::singleShot(500, this, SLOT 'hide()');
    }

}

sub downloadDone
{

#########################################################################
#  Subroutine: downloadDone                                             #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This slot gets called when the opd command completes.  We check to   #
#  make sure that we got a successful completion condtion.  If so,      #
#  we uncheck the checkbox in the package table for that package.       #
#########################################################################

  return if (!$dlPhase);

  my @cmdlines = split /\n/, $dlString;
  my $packageTableRef = getPackageTable();
  foreach my $cmdline (@cmdlines)
    {
      chomp $cmdline;
      next if (length $cmdline == 0);
      if ($cmdline =~ /^\"[^\"]*\":\"downloaded\":\"expanded\"$/)
        { # Success!  Set up for the next download
          # Uncheck the check box for that package by finding the correct
          # row number and unchecking the item
          for (my $rownum = 0; $rownum < $packageTableRef->numRows(); $rownum++)
            {
              if (($packageTableRef->item($rownum,1)->text() eq
                   $dlPackages[$dlPhase-1]->{package}) &&
                  ($packageTableRef->item($rownum,2)->text() eq
                   $dlPackages[$dlPhase-1]->{class}) &&
                  ($packageTableRef->item($rownum,3)->text() eq
                   $dlPackages[$dlPhase-1]->{version}) &&
                  ($packageTableRef->item($rownum,4)->text() eq
                   $dlPackages[$dlPhase-1]->{repositoryName}))
                {
                  $packageTableRef->item($rownum,1)->setChecked(0);
                  last;
                }
            }
          # Update the oda database with the new config.xml file
          updateOda();
          $dlPhase++;
        }
      else
        {
          Carp::carp("Couldn't download package " . 
                     $dlPackages[$dlPhase-1]->{package} . " with opd\n$cmdline\n");
          $dlPhase++;  # Try the next package in the list anyway
          last;
        }
    }

  downloadNext();

}

sub readFromStdout
{

#########################################################################
#  Subroutine: readFromStdout                                           #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When there is output on STDOUT due to the QProcess of opd, we get    #
#  it into a temporary string.  The reason for this somewhat odd method #
#  of getting info from STDOUT is because readStdout wasn't working     #
#  when this code was written.  PerlQt didn't support QByteArrays.      #
#########################################################################

  while ($dlProc->canReadLineStdout())
    {
      $dlString .= $dlProc->readLineStdout() . "\n";
    }

}

sub getPackageTable
{

#########################################################################
#  Subroutine: getPackageTable                                          #
#  Parameters: None                                                     #
#  Returns   : A reference to the main window's QTable package table    #
#########################################################################

  return (parent()->child('packageTable'));

}

sub updateOda
{

#########################################################################
#  Subroutine: updateOda                                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine takes in the name of a package and updates the       #
#  oda database with the (newly downloaded) config.xml file found in    #
#  /usr/lib/oscar/packages/PACKAGE_NAME.  It does this by calling the   #
#  script $OSCAR_HOME/scripts/read_package_config_xml_into_database.    #
#########################################################################

  # Since the package name has nothing to do with the directory name
  # of where the tarball gets unpacked, we need to untar the downloaded
  # tarball and figure out the name of the directory.  To do this, strip
  # off the last bit of the downloadURI.  This file should be in
  # /var/cache/oscar/downloads/.  Then using tar, list the contents of
  # the tarball and figure out the root directory of the package.  
  # Then the config.xml file is located in /usr/lib/oscar/packages/DIR.
  my $tarball;
  my $tardir;
  my $package = $dlPackages[$dlPhase-1]->{package};
  my %options = ();
  my @errors = ();
  ($dlPackages[$dlPhase-1]->{downloadURI}[0] =~ /\/([^\/]*)$/) &&
    ($tarball = "/var/cache/oscar/downloads/$1");

  if (-e $tarball)
    {
      my $pkg;
      open(CMD,'tar -tvzf ' . $tarball . ' |');
      my $cmd_output = <CMD>;
      chomp $cmd_output;
      ($cmd_output =~ /\s([^\s]*)\/$/) && ($pkg = $1) &&
        ($tardir = "/usr/lib/oscar/packages/$pkg");
      while ($cmd_output = <CMD>) { }  # To prevent tar "stdout" error
      close CMD;

      if (-d $tardir)
        {
          my @args = (
            "$ENV{OSCAR_HOME}/scripts/package_config_xmls_to_database",
              $tardir);
          (system(@args) == 0) or
            Carp::carp("Failure updating oda for package $package: $?");

          # Run the 'setup' script for the newly downloaded package
          my $currdir = `pwd`;
          chomp($currdir);
          chdir("$tardir/scripts");
          OSCAR::Package::run_pkg_script($pkg,'setup',1) or
            Carp::carp("Failed to run setup script for $pkg");

          # The downloaded package is not selected to install yet.
          # It should not be in the package_sets_included_packages table.
          my $currSet = "Default";
          my $success = OSCAR::Database::delete_group_packages(
            $currSet,$pkg,\%options,\@errors);
          Carp::carp("Could not do oda command 'delete_group_packages".
            " $pkg $currSet'") if 
              (!$success);
          chdir($currdir);
        }
      else
        {
          Carp::carp("Couldn't update oda since $tardir doesn't exist");
        }
    }
  else
    {
      Carp::carp("Couldn't locate the tarball for $package");
    }

}

1;

# Form implementation generated from reading ui file 'OpderDownloadPackage.ui'
#
# Created: Fri Jun 27 16:37:59 2003
#      by: The PerlQt User Interface Compiler (puic)
#
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
    setObjectRefs => [],
    readFromStdout => [],
    downloadStart => [],
    downloadDone => [],
    downloadNext => [];
use Qt::attributes qw(
    downloadLabel
    downloadLabel_font
    packageLabel
    packageLabel_font
    progressBar
    cancelButton
    cancelButton_font
);

my ($downloadInfoFormRef,$downloadButtonRef,$packageTableRef,$refreshButtonRef);
my ($dlProc,$dlPhase,$dlString,@dlPackages); # Execute opd and read results
my $opdcmd = $ENV{OSCAR_HOME} . '/scripts/opd';
use Carp;

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
    resize(324,118);
    setCaption(trUtf8("Wait..."));

    my $OpderDownloadPackageLayout = Qt::GridLayout(this, 1, 1, 11, 6, '$OpderDownloadPackageLayout');

    my $Layout33 = Qt::VBoxLayout(undef, 0, 6, '$Layout33');

    downloadLabel = Qt::Label(this, "downloadLabel");
    downloadLabel_font = Qt::Font(downloadLabel->font);
    downloadLabel_font->setFamily("Helvetica [Urw]");
    downloadLabel_font->setPointSize(14);
    downloadLabel_font->setBold(1);
    downloadLabel->setFont(downloadLabel_font);
    downloadLabel->setText(trUtf8("Dowloading Package File"));
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
#########################################################################

  progressBar->reset();
  progressBar->setTotalSteps(0);
  progressBar->setPercentageVisible(1);
  progressBar->setCenterIndicator(1);

  $refreshButtonRef->setEnabled(0);

  downloadStart();

}

sub hideEvent
{

#########################################################################
#  Subroutine: hideEvent                                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  $dlPhase = 0;
  $dlProc->tryTerminate() if ($dlProc->isRunning());
  Qt::Timer::singleShot(500, $dlProc, SLOT 'kill()');

  $refreshButtonRef->setEnabled(1);

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

sub setObjectRefs
{

#########################################################################
#  Subroutine: setObjectRefs                                            #
#  Parameters: 1. Reference to the DownloadPackageInfo widget           #
#              2. Reference to the downloadButton button                #
#              3. Reference to the packageTable Table                   #
#              4. Reference to the refreshButton button                 #
#  Returns   : Nothing                                                  #
#########################################################################

  $downloadInfoFormRef = shift;
  $downloadButtonRef = shift;
  $packageTableRef = shift;
  $refreshButtonRef = shift;

}

sub readFromStdout
{

#########################################################################
#  Subroutine: readFromStdout                                           #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  while ($dlProc->canReadLineStdout())
    {
      $dlString .= $dlProc->readLineStdout() . "\n";
    }

}

sub downloadStart
{

#########################################################################
#  Subroutine: downloadStart                                            #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  return unless ((-e $opdcmd) && (-x $opdcmd));

  # Figure out which packages we have to download
  @dlPackages = ();
  my $readPackages = $downloadInfoFormRef->getReadPackages();
  for (my $rownum = 0; $rownum < $packageTableRef->numRows(); $rownum++)
    {
      if ($packageTableRef->item($rownum,1)->isChecked())
        {
          my $arraypos = $packageTableRef->item($rownum,0)->text();
          push @dlPackages, @{$readPackages}[$arraypos];
        }
    }

  progressBar->setTotalSteps(scalar(@dlPackages));

  $dlPhase = 1;
  downloadNext();

}

sub downloadDone
{

#########################################################################
#  Subroutine: downloadDone                                             #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  return if (!$dlPhase);

  my $cmdlie;
  my @cmdlines = split /\n/, $dlString;
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
          $dlPhase++;
        }
      else
        {
          Carp::carp("Couldn't download package " . 
                     $dlPackages[$dlPhase-1]->{package} . " with opd");
          $dlPhase++;
          last;
        }
    }

  downloadNext();

}

sub downloadNext
{

#########################################################################
#  Subroutine: downloadNext                                             #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  progressBar->setProgress($dlPhase-1);

  if ($dlPhase <= scalar(@dlPackages))
    {
      packageLabel->setText($dlPackages[$dlPhase-1]->{package});

      my @args = ($opdcmd,
                  '--parsable',
                  '-r',$dlPackages[$dlPhase-1]->{repositoryURL},
                  '--package',$dlPackages[$dlPhase-1]->{downloadURI}[0]); 

      $dlProc->setArguments(\@args);
      $dlString = "";
      if (!$dlProc->start())
        { # Error handling
          Carp::carp("Couldn't download package " . 
                     $dlPackages[$dlPhase]->{package} . " with opd");
        }
      
    }
  else # All done!
    {
      # Count how many check boxes are checked.  If 0, then disable
      # the downloadButton.  Otherwise, enable it.
      my $numchecked = 0;
      for (my $rownum = 0; $rownum < $packageTableRef->numRows(); $rownum++)
        {
          $numchecked++ if $packageTableRef->item($rownum,1)->isChecked();
        }
      $downloadButtonRef->setEnabled($numchecked > 0);
      
      Qt::Timer::singleShot(500, this, SLOT 'hide()');
    }

}

1;

# Form implementation generated from reading ui file 'OpderDownloadInfo.ui'
#
# Created: Fri Jun 27 16:23:09 2003
#      by: The PerlQt User Interface Compiler (puic)
#
# WARNING! All changes made in this file will be lost!


use strict;
use utf8;


package OpderDownloadInfo;
use Qt;
use Qt::isa qw(Qt::Dialog);
use Qt::slots
    init => [],
    showEvent => [],
    hideEvent => [],
    cancelButton_clicked => [],
    advanceBallTimer => [],
    refreshReadPackages => [],
    getReadPackages => [],
    readFromStdout => [],
    readDone => [],
    processRepository => [],
    extractPackageFieldNamesAndTypes => [],
    extractDownloadURIs => [],
    deepcopy => [],
    setObjectRefs => [];
use Qt::attributes qw(
    downloadLabel
    downloadLabel_font
    fiveBalls
    cancelButton
    cancelButton_font
);

my ($ballTimer,$ballNumber); # Animated graphic of 5 green balls
my ($readProc,$readPhase,$readString,@readPackages,@successfullyReadPackages); # Execute opd and read results
my (%repositories,$currRepositoryURL,$currRepositoryName); # Keep track of repositories read from opd
my $opdcmd = $ENV{OSCAR_HOME} . '/scripts/opd';
use Carp;
use Qt::signals readPackagesSuccess => [];
my ($downloadButtonRef,$packageTableRef);

sub uic_load_pixmap_OpderDownloadInfo
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
        setName("OpderDownloadInfo");
    }
    resize(130,130);
    setCursor(Qt::Cursor(0));
    setCaption(trUtf8("Wait..."));

    my $OpderDownloadInfoLayout = Qt::GridLayout(this, 1, 1, 11, 6, '$OpderDownloadInfoLayout');

    my $Layout15 = Qt::VBoxLayout(undef, 0, 6, '$Layout15');

    downloadLabel = Qt::Label(this, "downloadLabel");
    downloadLabel_font = Qt::Font(downloadLabel->font);
    downloadLabel_font->setFamily("Helvetica [Urw]");
    downloadLabel_font->setPointSize(14);
    downloadLabel_font->setBold(1);
    downloadLabel->setFont(downloadLabel_font);
    downloadLabel->setCursor(Qt::Cursor(0));
    downloadLabel->setText(trUtf8("Dowloading\n" .
    "Package\n" .
    "Information..."));
    downloadLabel->setAlignment(int(&Qt::Label::AlignCenter));
    $Layout15->addWidget(downloadLabel);

    fiveBalls = Qt::Label(this, "fiveBalls");
    fiveBalls->setCursor(Qt::Cursor(0));
    fiveBalls->setPixmap(uic_load_pixmap_OpderDownloadInfo("ball1.png"));
    fiveBalls->setScaledContents(1);
    $Layout15->addWidget(fiveBalls);

    cancelButton = Qt::PushButton(this, "cancelButton");
    cancelButton_font = Qt::Font(cancelButton->font);
    cancelButton_font->setFamily("Helvetica [Urw]");
    cancelButton_font->setPointSize(14);
    cancelButton->setFont(cancelButton_font);
    cancelButton->setText(trUtf8("&Cancel"));
    $Layout15->addWidget(cancelButton);

    $OpderDownloadInfoLayout->addLayout($Layout15, 0, 0);

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

  $ballTimer = Qt::Timer(this);
  Qt::Object::connect($ballTimer, SIGNAL 'timeout()',
                                  SLOT   'advanceBallTimer()');

  $readProc = Qt::Process(this);
  Qt::Object::connect($readProc,  SIGNAL 'readyReadStdout()', 
                                  SLOT   'readFromStdout()');
  Qt::Object::connect($readProc,  SIGNAL 'processExited()',  
                                  SLOT   'readDone()');

}

sub showEvent
{

#########################################################################
#  Subroutine: showEvent                                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  $ballNumber = 1;
  $ballTimer->start(200,0);   # Animation update every .2 seconds
  refreshReadPackages();
  $downloadButtonRef->setEnabled(0);

}

sub hideEvent
{

#########################################################################
#  Subroutine: hideEvent                                                #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  fiveBalls->setPixmap(uic_load_pixmap_OpderDownloadInfo('ball1.png'));
  $ballTimer->stop();

  $readPhase = 0;
  $readProc->tryTerminate() if ($readProc->isRunning());
  Qt::Timer::singleShot(500, $readProc, SLOT 'kill()');

  # Count how many check boxes are checked.  If 0, then disable
  # the downloadButton.  Otherwise, enable it.
  my $numchecked = 0;
  for (my $rownum = 0; $rownum < $packageTableRef->numRows(); $rownum++)
    {
      $numchecked++ if $packageTableRef->item($rownum,1)->isChecked();
    }
  $downloadButtonRef->setEnabled($numchecked > 0);

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

sub advanceBallTimer
{

#########################################################################
#  Subroutine: advanceBallTimer                                         #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  if (isVisible())
    {
      $ballNumber++;
      $ballNumber = 1 if ($ballNumber > 5);
      fiveBalls->setPixmap(uic_load_pixmap_OpderDownloadInfo(
                 "ball$ballNumber.png"));
    }

}

sub refreshReadPackages
{

#########################################################################
#  Subroutine: refreshReadPackages                                      #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  return unless ((-e $opdcmd) && (-x $opdcmd));

  my @args = ($opdcmd,'--parsable');
  $readProc->setArguments(\@args);
  @readPackages = ();
  $readPhase = 1;
  $readString = "";
  if (!$readProc->start())
    { # Error handling
      Carp::carp("Couldn't run 'opd --parsable'");
    }

}

sub getReadPackages
{

#########################################################################
#  Subroutine: getReadPackages                                          #
#  Parameters: None                                                     #
#  Returns   : A reference to an array to packages read in from OPD     #
#########################################################################

  return \@successfullyReadPackages;

}

sub readFromStdout
{

#########################################################################
#  Subroutine: readFromStdout                                           #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################
  
  while ($readProc->canReadLineStdout())
    {
      $readString .= $readProc->readLineStdout() . "\n";
    }

}

sub readDone
{

#########################################################################
#  Subroutine: readDone                                                 #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  return if (!$readPhase);

  my @cmdlines = split /\n/, $readString;
  $readString = "";
  foreach my $cmdline (@cmdlines)
    {
      chomp $cmdline;
      if ($cmdline !~ /^ERROR/)
        {
          # Remove the leading and trailing double-quotes
          $cmdline =~ s/^\"//;
          $cmdline =~ s/\"$//;
          next if (length $cmdline == 0);
          if ($readPhase == 1)
            {
              my ($repname,$reploc,$repurl) = split /\":\"/, $cmdline;
              $repositories{$repurl} = $repname;
            }
          elsif ($readPhase == 2)
            {
              # Get all of the info corresponding to oda info above
              my($name,$major,$minor,$release,$subversion,$epoch,
                 $omajor,$ominor,$orelease,$osubversion,$oepoch,
                 $packager_name,$packager_email,
                 $description,$license,$installable,$group,$summary,
                 $url,$class,$md5sum,$sha1sum,$downloaduri,
                 $providesnames,$providestypes,
                 $requiresnames,$requirestypes,
                 $conflictsnames,$conflictstypes) =
                   split /\":\"/, $cmdline;

              my $version = "";
              $version  = $major if (length $major > 0);
              $version .= '.' . $minor if (length $minor > 0);
              $version .= '.' . $subversion if (length $subversion > 0);
              $version .= '-' . $release if (length $release > 0);

              my $href;
              $href->{name} = $name;
              $href->{package} = $name;
              $href->{installable} = $installable;
              $href->{class} = $class;
              $href->{description} = $description;
              $href->{version} = $version;
              $href->{location} = "OPD";
              $href->{repositoryURL} = $currRepositoryURL;
              $href->{repositoryName} = $currRepositoryName;
              $href->{packager_name} = $packager_name;
              $href->{packager_email} = $packager_email;

              push @readPackages, $href;

              # print $readPackages[$#readPackages]->{name} . "\n";

              extractPackageFieldNamesAndTypes(
                'provides',$providesnames,$providestypes);
              extractPackageFieldNamesAndTypes(
                'requires',$requiresnames,$requirestypes);
              extractPackageFieldNamesAndTypes(
                'conflicts',$conflictsnames,$conflictstypes);
              extractDownloadURIs($downloaduri);
            }
        }
      else
        {
          %repositories = ();
          last;
        }
    }

  processRepository();

}

sub processRepository
{

#########################################################################
#  Subroutine: processRepository                                        #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#########################################################################

  my @repositories = sort keys %repositories;
  if (@repositories)
    {
      $currRepositoryURL = shift @repositories;
      $currRepositoryName = $repositories{$currRepositoryURL};
      delete $repositories{$currRepositoryURL};
      my @args = ($opdcmd,'--parsable','-r',$currRepositoryURL);
      $readProc->setArguments(\@args);
      $readPhase = 2;
      $readString = "";
      if (!$readProc->start())
        { # Error handling
          Carp::carp("Couldn't run 'opd --parsable -r $currRepositoryURL'\n");
        }
    }
  else # All done!
    {
      my $temp = deepcopy(\@readPackages);
      @successfullyReadPackages = @{$temp};
      hide();
      emit readPackagesSuccess();
    }

}

sub extractPackageFieldNamesAndTypes
{

#########################################################################
#  Subroutine: extractPackageFieldNamesAndTypes                         #
#  Parameters: (1) The "category" - one of provides/requires/conflicts  #
#              (2) The string of comma separated "names"                #
#              (3) The string of comma separated "types"                #
#  Returns   : Nothing                                                  #
#########################################################################

  my $category = shift;
  my $names = shift;
  my $types = shift;

  if (length $names > 0)
    {
      # Remove the leading and trailing double-quotes
      $names =~ s/^\"//;
      $names =~ s/\"$//;
      $types =~ s/^\"//;
      $types =~ s/\"$//;
      my @names = split /\",\"/, $names;
      my @types = split /\",\"/, $types;

      my $href;
      for (my $count = 0; $count < (scalar @names); $count++)
        {
          undef $href;
          $href->{name} = $names[$count];
          if ($count < (scalar @types))
            {
              $href->{type} = $types[$count];
            }
          else # 'type' defaults to 'package' if nothing given
            {
              $href->{type} = "package";
            }
          push @{ $readPackages[$#readPackages]->{$category} }, $href;
        }
    }

}

sub extractDownloadURIs
{

  my $uris = shift;

  if (length $uris > 0)
    {
      # Remove the leading and trailing double-quotes
      $uris =~ s/^\"//;
      $uris =~ s/\"$//;
      my @uris = split /\",\"/, $uris;

      foreach my $uri (@uris)
        {
          push @{ $readPackages[$#readPackages]->{downloadURI} }, $uri;
        }
    }

}

sub deepcopy
{

#########################################################################
#  Subroutine: deepcopy                                                 #
#  Parameter : A reference (hash or array) to copy                      # 
#  Returns   : A copy of the passed in reference (hash or array)        #
#  This subroutine is a general function to do a "deep copy" of a       #
#  data structure.  A normal "shallow copy" only copies the elements of #
#  a hash/array at the current level.  Any hashes/arrays at lower       #
#  levels don't get copied.  A "deep copy" recurses down the tree and   #
#  copies all levels.  This subroutine was taken from Unix Review       #
#  Column 30, February 2000.                                            #
#########################################################################

  my $this = shift;
  if (not ref $this)
    { $this; }
  elsif (ref $this eq "ARRAY")
    { [map deepcopy($_), @$this]; }
  elsif (ref $this eq "HASH")
    { +{map { $_ => deepcopy($this->{$_}) } keys %$this}; }
  else
    { Carp::carp("What type is $_?"); }

}

sub setObjectRefs
{

#########################################################################
#  Subroutine: setObjectRefs                                            #
#  Parameters: 1. Reference to the downloadButton button                #
#              2. Reference to the packageTable table                   #
#  Returns   : Nothing                                                  #
#########################################################################

  $downloadButtonRef = shift;
  $packageTableRef = shift;

}

1;

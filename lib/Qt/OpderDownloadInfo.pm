# Form implementation generated from reading ui file 'OpderDownloadInfo.ui'
#
# Created: Tue Oct 21 16:40:41 2003
#      by: The PerlQt User Interface Compiler (puic)
#
# Note that we do not use puic anymore to modify this file. This capability has
# been lost, therefore we directly modify this file.
#


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
    deepcopy => [];
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
use Qt::signals readPackagesSuccess=>[], downloadButtonDisable=>[], downloadButtonUpdate=>[];

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
    resize(144,164);
    setCursor(Qt::Cursor(0));
    setCaption(trUtf8("Wait..."));

    my $OpderDownloadInfoLayout = Qt::GridLayout(this, 1, 1, 11, 6, '$OpderDownloadInfoLayout');

    my $layout7 = Qt::VBoxLayout(undef, 11, 6, '$layout7');

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
    $layout7->addWidget(downloadLabel);

    fiveBalls = Qt::Label(this, "fiveBalls");
    fiveBalls->setSizePolicy(Qt::SizePolicy(1, 0, 0, 0, fiveBalls->sizePolicy()->hasHeightForWidth()));
    fiveBalls->setCursor(Qt::Cursor(0));
    fiveBalls->setPixmap(uic_load_pixmap_OpderDownloadInfo("ball1.png"));
    fiveBalls->setScaledContents(0);
    fiveBalls->setAlignment(int(&Qt::Label::AlignCenter));
    $layout7->addWidget(fiveBalls);

    cancelButton = Qt::PushButton(this, "cancelButton");
    cancelButton_font = Qt::Font(cancelButton->font);
    cancelButton_font->setFamily("Helvetica [Urw]");
    cancelButton_font->setPointSize(14);
    cancelButton->setFont(cancelButton_font);
    cancelButton->setText(trUtf8("&Cancel"));
    $layout7->addWidget(cancelButton);

    $OpderDownloadInfoLayout->addLayout($layout7, 0, 0);

    Qt::Object::connect(cancelButton, SIGNAL "clicked()", this, SLOT "cancelButton_clicked()");

    init();
}


sub init
{

#########################################################################
#  Subroutine: init                                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This code is called after the "Downloading Package Information..."   #
#  widget is created but before it is displayed.  It sets up the timer  #
#  for the strobing ball and the process which calls the command-line   #
#  version of opd.                                                      #
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
#  When the widget is displayed, start the strobing of the five green   #
#  balls.  It's just pretty animation while the work goes on in the     #
#  background.                                                          #
#########################################################################

  # Make sure the opd script is there
  if ((-e $opdcmd) && (-x $opdcmd))
    {
      $ballNumber = 1;
      $ballTimer->start(200,0);   # Animation update every .2 seconds
      emit downloadButtonDisable();
      refreshReadPackages();      # Do the actual work in the background
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

  # Stop the timer for the green ball animation
  fiveBalls->setPixmap(uic_load_pixmap_OpderDownloadInfo('ball1.png'));
  $ballTimer->stop();

  # It could be that the widget got hidden due to the parent window 
  # (i.e. the main window) got minimized.  If so, then don't kill the
  # QProcess controlling opd.  Let it try to finish with the window
  # minimized/hidden.
  if (!(parent()->isMinimized()))
    {
      $readPhase = 0;
      $readProc->tryTerminate() if ($readProc->isRunning());
      Qt::Timer::singleShot(500, $readProc, SLOT 'kill()');
    }

  emit downloadButtonUpdate();

}

sub cancelButton_clicked
{

#########################################################################
#  Subroutine: cancelButton_clicked                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the user clicks the "Cancel" button, close the window.          #
#########################################################################

  hide();

}

sub advanceBallTimer
{

#########################################################################
#  Subroutine: advanceBallTimer                                         #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This slot is called by the QTimer set up at object initialization.   #
#  It advances the ballNumber of the green ball animation and shows     #
#  the next image in the strobe sequence.                               #
#########################################################################

  if (isVisible())
    {
      $ballNumber++;
      $ballNumber = 1 if ($ballNumber > 5);
      fiveBalls->setPixmap(uic_load_pixmap_OpderDownloadInfo("ball$ballNumber.png"));
    }

}

sub refreshReadPackages
{

#########################################################################
#  Subroutine: refreshReadPackages                                      #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This gets called when the widget is shown (from showEvent).  It      #
#  sets up the QProcess for reading repository information with opd.    #
#########################################################################

  return if ($readPhase);  # If we are already reading, don't do it again

  # If there are any user-specified repository URLs, add them to
  # the hash of repositories to be processed.
  my $text = parent()->child('addRepositoryForm')->urlText;
  if (length($text) > 0)
    {
      foreach my $url (split /\n/, $text)
        { # User-specified repositories don't have a 'name'
          $repositories{$url} = "User Specified";
        }
    }

  # Check to see if we should use ONLY the user-specified repositories
  if (parent()->child('addRepositoryForm')->useRepositoriesExclusively)
    {
      if (length($text) > 0)
        {
          $readPhase = 2;
          $readString = "";
          @readPackages = ();
          processRepository();
        }
    }
  else
    {
      my @args = ($opdcmd,'--parsable');
      $readProc->setArguments(\@args);
      $readPhase = 1;
      $readString = "";
      @readPackages = ();
      if (!$readProc->start())
        { 
          Carp::carp("Couldn't run 'opd --parsable'");
        }
    }

}

sub getReadPackages
{

#########################################################################
#  Subroutine: getReadPackages                                          #
#  Parameters: None                                                     #
#  Returns   : A reference to an array to packages read in from OPD.    #
#  We need separate arrays for @successfullyReadPacakges and            #
#  @readPackages.  This is because @readPackages is the "temporary"     #
#  array used for reading information via opd.  If the entire opd       #
#  process is successful, then we copy that array to the "successful"   #
#  array which is used to update the information in the table.  So,     #
#  this subroutine returns only the "successfully read packages".       #
#########################################################################

  return \@successfullyReadPackages;

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
  
  while ($readProc->canReadLineStdout())
    { # Build up a possibly multi-line string
      $readString .= $readProc->readLineStdout() . "\n";
    }

}

sub readDone
{

#########################################################################
#  Subroutine: readDone                                                 #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  When the QProcess for opd completes, it signals readDone.  This      #
#  subroutine figures out if opd completed successfully or not.  If it  #
#  did, we figure out which phase we were in.  Phase 1 is when we get   #
#  info about the opd repositories.  Phase 2 is when we get information #
#  about the packages available from each opd repository.               #
#########################################################################

  return if (!$readPhase);

  my @cmdlines = split /\n/, $readString;  # May have had multiple STDOUT lines
  $readString = "";   # Reset it for the next time through
  foreach my $cmdline (@cmdlines)
    {
      chomp $cmdline;
      if ($cmdline !~ /^ERROR/)
        { # opd completed successfully.
          # Remove the leading and trailing double-quotes.
          $cmdline =~ s/^\"//;
          $cmdline =~ s/\"$//;
          next if (length $cmdline == 0);
          if ($readPhase == 1)
            { # Phase 1 = get info about opd repositories
              my ($repname,$reploc,$repurl) = split /\":\"/, $cmdline;
              # Save a hash of repository URLs and Names
              $repositories{$repurl} = $repname; 
            }
          elsif ($readPhase == 2)
            { # Phase 2 = get package info from each opd repository
              # Get all of the info corresponding to oda info
              my($name,$major,$minor,$release,$subversion,$epoch,
                 $omajor,$ominor,$orelease,$osubversion,$oepoch,
                 $packager_name,$packager_email,
                 $description,$license,$installable,$group,$summary,
                 $url,$class,$md5sum,$sha1sum,$downloaduri,
                 $providesnames,$providestypes,
                 $requiresnames,$requirestypes,
                 $conflictsnames,$conflictstypes) =
                   split /\":\"/, $cmdline;

              # Generate a single version string
              my $version = "";
              $version  = $major if (length $major > 0);
              $version .= '.' . $minor if (length $minor > 0);
              $version .= '.' . $subversion if (length $subversion > 0);
              $version .= '-' . $release if (length $release > 0);

              # Create a temporary hash reference containing all of the
              # required information for each pacakge.  This will be pushed
              # on to a stack.  This is slightly different from the
              # Selection because there could be multiple versions / 
              # repositories for a single package name.  We need to keep
              # such packages distinct so we can't use a simple hash keyed
              # by the package name.
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

              # Next, get the provides, requires, and conflicts lists for
              # each package.  Here the {provides}, {requires}, and
              # {conflicts} fields are arrays of hash references, each
              # containing the two fields {name} and {type}.  
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
        { # opd reported ERROR, so don't quit processsing and continue
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
#  After opd has completed phase 1, we should have a hash of            #
#  repository URLs/names.  We need to check each one for available      #
#  packages, using (naturally) opd.                                     #
#########################################################################

  # Check to see if there are any repositories left to be checked
  my @repositories = sort keys %repositories;
  if (@repositories)
    { # Save the current repository URL/Name in module-scope variables
      $currRepositoryURL = shift @repositories;
      $currRepositoryName = $repositories{$currRepositoryURL};
      # Remove this module from the hash - i.e. process it only once
      delete $repositories{$currRepositoryURL};
      # Set up the QProcess with the "read repository" opd command
      my @args = ($opdcmd,'--parsable','-r',$currRepositoryURL);
      push @args, "--nomaster"
        if parent()->child('addRepositoryForm')->useRepositoriesExclusively;
      $readProc->setArguments(\@args);
      $readPhase = 2;
      $readString = "";
      if (!$readProc->start())
        { # 
          Carp::carp("Couldn't run 'opd --parsable -r $currRepositoryURL'\n");
        }
    }
  else # An empty %repositories hash = All Done!
    {
      # Do a deep copy of the @readPackages to @successfullyReadPackages
      my $temp = deepcopy(\@readPackages);
      @successfullyReadPackages = @{$temp};
      hide();
      emit readPackagesSuccess();   # Cause the package table to be updated
      $readPhase = 0;
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
#  This is called in Phase 2 to extract the names/types for the         #
#  provides/requires/conflicts tags which get displayed in the info     #
#  windows below the package table.                                     #
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

#########################################################################
#  Subroutine: extractDownloadURIs                                      #
#  Parameters: A string of URI(s) for downloading a package             #
#  Returns   : Nothing                                                  #
#  This is called in Phase 2 to extract the URIs for downloading        #
#  a package's tarball.  There COULD be more than one location for the  #
#  tarball but it wouldn't matter too much since we tell opd to try     #
#  only the first one.  But for fun, save all the URIs in an array.     #
#  Thus, we get the package tarball from:                               #
#      $successfullyReadPackage[$pos]->{downloadURI}[0]                 #
#########################################################################

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

1;

# Form implementation generated from reading ui file 'SelectorAbout.ui'
#
# Created: Tue Jul 1 18:33:12 2003
#      by: The PerlQt User Interface Compiler (puic)
#
# Note that we do not use puic anymore to modify this file. This capability has
# been lost, therefore we directly modify this file.
#


use strict;
use utf8;


package SelectorAbout;
use Qt;
use Qt::isa qw(Qt::Dialog);
use Qt::slots
    urlButton_clicked => [];
use Qt::attributes qw(
    pictureLabel
    aboutTitleLabel
    aboutTitleLabel_font
    copyrightLabel
    urlButton
    urlButton_font
);

use SelectorImages;

sub uic_load_pixmap_SelectorAbout
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
        setName("SelectorAbout");
    }
    resize(405,150);
    setSizePolicy(Qt::SizePolicy(0, 0, 0, 0, this->sizePolicy()->hasHeightForWidth()));
    setMinimumSize(Qt::Size(405, 150));
    setMaximumSize(Qt::Size(405, 150));
    setCaption(trUtf8("About OSCAR Package Selector"));

    my $SelectorAboutLayout = Qt::GridLayout(this, 1, 1, 11, 6, '$SelectorAboutLayout');

    my $Layout38 = Qt::HBoxLayout(undef, 0, 6, '$Layout38');

    pictureLabel = Qt::Label(this, "pictureLabel");
    pictureLabel->setPixmap(uic_load_pixmap_SelectorAbout("oscar.png"));
    pictureLabel->setScaledContents(1);
    $Layout38->addWidget(pictureLabel);

    my $Layout37 = Qt::VBoxLayout(undef, 0, 6, '$Layout37');

    aboutTitleLabel = Qt::Label(this, "aboutTitleLabel");
    aboutTitleLabel_font = Qt::Font(aboutTitleLabel->font);
    aboutTitleLabel_font->setFamily("Helvetica [Urw]");
    aboutTitleLabel_font->setPointSize(24);
    aboutTitleLabel_font->setBold(1);
    aboutTitleLabel_font->setItalic(1);
    aboutTitleLabel->setFont(aboutTitleLabel_font);
    aboutTitleLabel->setText(trUtf8("OSCAR Package Selector"));
    $Layout37->addWidget(aboutTitleLabel);

    copyrightLabel = Qt::Label(this, "copyrightLabel");
    copyrightLabel->setText(trUtf8("(C) 2003 NCSA, UIUC"));
    copyrightLabel->setAlignment(int(&Qt::Label::AlignCenter));
    $Layout37->addWidget(copyrightLabel);

    urlButton = Qt::PushButton(this, "urlButton");
    urlButton->setPaletteForegroundColor(Qt::Color(85, 0, 255));
    urlButton_font = Qt::Font(urlButton->font);
    urlButton_font->setFamily("Helvetica [Urw]");
    urlButton_font->setPointSize(18);
    urlButton_font->setBold(1);
    urlButton_font->setUnderline(1);
    urlButton->setFont(urlButton_font);
    urlButton->setText(trUtf8("http://oscar.sourceforge.net/"));
    urlButton->setFlat(1);
    Qt::ToolTip::add(urlButton, trUtf8("Open the OSCAR homepage in Mozilla"));
    $Layout37->addWidget(urlButton);
    $Layout38->addLayout($Layout37);

    $SelectorAboutLayout->addLayout($Layout38, 0, 0);

    Qt::Object::connect(urlButton, SIGNAL "clicked()", this, SLOT "urlButton_clicked()");
}


sub urlButton_clicked
{

#########################################################################
#  Subroutine: urlButton_clicked                                        #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine is called when the URL button (the one with the      #
#  link to http://oscar.sourceforge.net/) is clicked.  It checks for    #
#  the mozilla binary.  If found, it launches the OSCAR homepage.       #
#########################################################################

  open(CMD,'which mozilla |');
  my $cmd_output = <CMD>;
  close CMD;
  chomp $cmd_output;  

  system($cmd_output . " http://oscar.sourceforge.net/ &") if 
    ($cmd_output !~ "^which: no mozilla");

}

1;

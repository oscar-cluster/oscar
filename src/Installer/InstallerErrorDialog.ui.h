/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/


void InstallerErrorDialog::init()
{
  errorDetailsTextEdit->hide();
  my $flags = getWFlags();
  setWFlags($flags | Qt::WDestructiveClose());
}


void InstallerErrorDialog::showDetailsButton_clicked()
{
  if (errorDetailsTextEdit->isHidden())
    {
      errorDetailsTextEdit->show();
      showDetailsButton->setText("Hide &Details <<");
    }
  else
    {
      errorDetailsTextEdit->hide();
      showDetailsButton->setText("Show &Details >>");
    }
}


void InstallerErrorDialog::okButton_clicked()
{
  done(0);
}


void InstallerErrorDialog::setErrorMainText()
{
  my($tasknum,$taskname) = @_;
  
  my $errorText = "Unable to start Task # $tasknum - ".
                  '"' . $taskname . '" '.
                  "since some prerequisites were not satisfied.  ".
                  'Click the "Show Details" button to see which '.
                  "prerequisites failed and why.  ".
                  'Click the "OK" button when finished.';
  errorMainTextEdit->setText($errorText);
}


void InstallerErrorDialog::setErrorDetailsText()
{
  errorDetailsTextEdit->setText(shift);
}


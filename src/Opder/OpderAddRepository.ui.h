/****************************************************************************
** ui.h extension file, included from the uic-generated form implementation.
**
** If you wish to add, delete or rename functions or slots use
** Qt Designer which will update this file, preserving your code. Create an
** init() function in place of a constructor, and a destroy() function in
** place of a destructor.
*****************************************************************************/


void OpderAddRepository::doneButton_clicked()
{
#########################################################################
#  Subroutine: doneButton_clicked()                                     #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine gets called when the user clicks the "Done" button.  #
#  It simply hides the window, which then generates a 'hide' event and  #
#  does the necessary post-processing.                                  #
#########################################################################

  hide();
}

void OpderAddRepository::hideEvent()
{
#########################################################################
#  Subroutine: hideEvent()                                              #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  This subroutine gets called when the user hides the window.  It      #
#  gets the new state of the window (i.e. the checkbox and textbox)     #
#  and assigns the global variables as necessary.  It also checks to    #
#  to see if any changes were made, and if so, requests that the table  #
#  be refreshed.                                                        #
#########################################################################

  # Save old state of checkbox to see if there was a change
  my $oldUseRepositoriesExclusively = useRepositoriesExclusively;
  useRepositoriesExclusively = exclusiveCheckBox->isChecked();
  
  # Save old state of textbox to see if there was a change
  my $oldUrlText = urlTextBox->text();
  # Get the URLs from the text box and fix them up a bit
  my $text = urlTextBox->text();
  urlText = "";
  $text =~ s/\n/ /g;  # Change newlines to spaces
  $text =~ s/^ *//;   # Strip leading spaces
  $text =~ s/ *$//;   # Strip trailing spaces
  $text =~ s/ +/ /g;  # Compact multiple spaces into a single space
  # Check the urls and see if we need to append http://
  foreach my $rep (split / /, $text)
    { # Append http:// for those strings that need it
      $rep = 'http://' . $rep if ($rep !~ /^(http|ftp|file):\/\//);
      # Add the completed url to the urlText global variable
      urlText .= "$rep\n";
    }
  
  # Finally, check for any changes which would require a "Refresh Table"
  my $update = 0;
  $update = 1 if (($oldUrlText ne urlText) ||
    ($oldUseRepositoriesExclusively != useRepositoriesExclusively));
  
  emit refreshTableNeeded() if ($update);
}


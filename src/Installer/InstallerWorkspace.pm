package InstallerWorkspace;

#########################################################################

=head1 NAME

InstallerWorkspace - Creates a new QWorkspace for the OSCAR Installer.

=head1 SYNOPSIS

  my $widget = InstallerWorkspace($parent,"InstallerWorkspace");

=head1 DESCRIPTION

This class is created by InstallerMainWindow and is added to the main window
within its central widget.  Description of a QWorkspace from the Qt 3.1
documentation:

I<The QWorkspace widget provides a workspace window that can contain decorated
windows, e.g. for MDI.  An MDI (multiple document interface) application has
one main window with a menu bar. The central widget of this window is a
workspace. The workspace itself contains zero, one or more document windows,
each of which displays a document.>

I<The workspace itself is an ordinary Qt widget. It has a standard constructor
that takes a parent widget and an object name. The parent window is usually
a QMainWindow, but it need not be.>

I<Document windows (i.e. MDI windows) are also ordinary Qt widgets which
have the workspace as parent widget. When you call show(), hide(),
showMaximized(), setCaption(), etc. on a document window, it is shown,
hidden, etc. with a frame, caption, icon and icon text, just as you'd
expect. You can provide widget flags which will be used for the layout of
the decoration or the behaviour of the widget itself.>

=head1 METHODS

=over

=cut

#########################################################################
                                                                                
use strict;
use utf8;
use InstallerUtils;
                                                                                
use Qt;
use Qt::isa qw(Qt::Workspace);
use Qt::signals
    signalButtonShown => ['char*','char*','bool'];
use Qt::slots
    windowsMenuAboutToShow => [];

#########################################################################

=item C<NEW($parent, $name)>

The constructor for the InstallerWorkspace class.

This returns a pointer to a new InstallerWorkspace widget.  It sets the
background to a tiled OSCAR 'penguin in a trashcan' image and enables
scrollbars so that you get a 'virtual' workspace where the workspace can be
'bigger' than the actual window containing it.

B<Note>: As with any PerlQt constructor, the NEW constructor is called
implicitly when you reference the class.  You do not need to call something
like C<classname->>C<NEW(args...)>.

=cut

### @param $parent Pointer to the parent of this widget.  Should not be
###                empty (null).
### @param $name   Name of the widget.  Will be set to "InstallerWorkspace"
###                if empty (or null).
### @return A Pointer to a new InstallerWorkspace widget.

#########################################################################
sub NEW
{
  shift->SUPER::NEW(@_[0..1]);

  setName("InstallerWorkspace") if (name() eq "unnamed");
  setPaletteBackgroundPixmap(InstallerUtils::getPixmap("oscarbg.png"));

  setScrollBarsEnabled(1);

  my $parent = parent();
  my $grandparent = $parent->parent();

  show();
}


1;

__END__

=back

=head1 SEE ALSO

InstallerMainWindow 

http://www.trolltech.com/

=head1 COPYRIGHT

Copyright E<copy> 2004 The Board of Trustees of the University of Illinois.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=head1 AUTHOR

Terrence G. Fleury (tfleury@ncsa.uiuc.edu)

First Created on February 2, 2004

Last Modified on February 23, 2004

=cut

#########################################################################
#                          MODIFICATION HISTORY                         #
# Mo/Da/Yr                        Change                                #
# -------- ------------------------------------------------------------ #
#########################################################################


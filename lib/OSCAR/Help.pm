package OSCAR::Help;
use strict;
use vars qw(%Help @EXPORT);
use base qw(Exporter);

@EXPORT = qw(open_help);

# Help messages for the OSCAR GUI.

sub open_help {
    my ($window, $section) = @_;
    my $helpwin = $window->Toplevel();
    $helpwin->title("Help");
    my $helpp = $helpwin->Scrolled("ROText",-scrollbars=>"e",-wrap=>"word",
                                 -width=>40,-height=>15);
    $helpp->grid(-sticky=>"nsew");
    my $cl_b = $helpwin->Button(-text=>"Close",
                                -command=> sub {$helpwin->destroy},-pady=>"8");
    $helpwin->bind("<Escape>",sub {$cl_b->invoke()});
    $cl_b->grid(-sticky=>"nsew",-ipady=>"4");
    $helpp->delete("1.0","end");
    $helpp->insert("end",$Help{$section});
}

%Help = (
         build_image => "This button will launch a panel which will let you define and build your OSCAR client image.  The defaults specified should work for most situations.",
         addclients => "This button will launch a panel which lets you define what clients are going to be installed with OSCAR.",
         netboot => "This button will launch the MAC Address Collection Tool which will enable you to assign specific MAC addresses to clients for installation.  Please follow the instructions on the MAC Address Collection Panel",
         post_install => "Pressing this button will run a series of post installation scripts which will complete your OSCAR installation.",
         test_install => "Pressing this button will set up the test scripts so that you can test to see if your OSCAR installation is working.",
        );
1;

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
         help_defsrv => "This button will launch a panel in which you can define your LUI installation server. You will need to specify a name for the server, its IP address & cluster subnet mask, and the default post install reboot action for the clients.",
         help_defcli => "This button will launch a panel in which you can define your LUI clients. Enter the first client IP address & the cluster subnet mask. If you entered the client MAC.info file by hand, you should specify the MACid that corresponds to the first client MAC entered. Enter the number of clients to create. You may also optionally specify the default route, an install gateway, the number of processors, and the PBS string. Finally, enter a name for your client machine group.",
         help_defres => "This button will launch a panel in which you can define the LUI resources. You will need a file resource for each filesystem on the clients, a disk resource to describe the disk partioning, a rpm resource to list the rpms to be installed on the clients, & a source resource for each file you wish to copy to the clients. For each resource defined, be sure to include the name for the resource group to which the resource should belong.",
         help_allres => "This button will launch a panel in which you can allocate the LUI resources. By allocating a resource to a client, you tell LUI to use that resource during the client installation. Enter the resource group name and client machine group name to allocate all the resources to all the clients.",
         help_pre2 => "This button will launch the OSCAR pre client installation server configuration script, which uses the information you entered about the server and clients to prepare system files and services for the client installations.",
         help_post => "This button will launch the OSCAR post client installation cluster configuration script, which is responsible for finalizing the cluster configuration.",
         mac_desc => "This is the OSCAR MAC address collection tool. It will help you to collect the ethernet MAC address from your clients.\n
This information is necessary to install the clients, but the use of this tool is optional.
You may manually create the file /etc/MAC.info if you prefer. The file must include one line for each client in the following format:\n
<MACid> <MAC address>\n
The MACid is a symbolic tag that the collection methods use to refer to the MAC address. If you are creating the file manually, something like 'nodex' where x is a node number makes sense.\n
Once you have created the file manually or collected the MAC addresses with this tool, you may continue past this step.\n
Press 'Collect' to start the collection tool or 'Done' to skip this step and then create the file manually.\n
You will need to network boot your clients one at a time in sequential order. The tool will prompt you when to boot each client. Simply follow the instructions in the pane below.",
         MAC_poweron => "\nPlease network boot the next client node.\n",
         MAC_next => "Press 'Collect' to continue or 'Done' if finished.\n",
         MAC_noip => "LUI server IP address not found. You must define the server first.\n",
         MAC_err => "Failure collecting MAC address.\n",
        );
1;

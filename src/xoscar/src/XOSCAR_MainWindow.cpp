/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file XOSCAR_MainWindow.cpp
 * @brief Actual implementation of the ??? class.
 * @author Geoffroy Vallee
 */

#include "XOSCAR_MainWindow.h"
//#include "ORM_AddRepoGUI.h"

/**
 * @author Geoffroy Vallee.
 *
 * Class constructor: initialize the widget, connect signals and slots, and also
 * get the list of default OSCAR repositories.
 */
XOSCAR_MainWindow::XOSCAR_MainWindow(QMainWindow *parent)
    : QMainWindow(parent) 
{
    setupUi(this);

    /* Connect slots and signals */
    connect(AddOSCARRepoButton, SIGNAL(clicked()),
                    this, SLOT(create_add_repo_window()));
    connect(addDistroButton, SIGNAL(clicked()),
                    this, SLOT(create_add_distro_window()));
    connect(listReposWidget, SIGNAL(itemSelectionChanged ()),
                    this, SLOT(display_opkgs_from_repo()));
    connect(listOscarClustersWidget, SIGNAL(itemSelectionChanged ()),
                    this, SLOT(refresh_list_partitions()));
    connect(listClusterPartitionsWidget, SIGNAL(itemSelectionChanged ()),
                    this, SLOT(refresh_partition_info()));
    connect(refreshListOPKGsButton, SIGNAL(clicked()),
                    this, SLOT(refresh_display_opkgs_from_repo()));
    connect(refreshListSetupDistrosButton, SIGNAL(clicked()),
                    this, SLOT(refresh_list_setup_distros()));
    connect(systemSanityCheckButton, SIGNAL(clicked()),
                    this, SLOT(do_system_sanity_check()));
    connect(oscarSanityCheckButton, SIGNAL(clicked()),
                    this, SLOT(do_oscar_sanity_check()));
    connect(QuitButton, SIGNAL(clicked()),
                    this, SLOT(destroy()));
    connect(actionAboutXOSCAR, SIGNAL(triggered()),
                    this, SLOT(handle_about_authors_action()));
    connect(actionAbout_OSCAR, SIGNAL(triggered()),
                    this, SLOT(handle_about_oscar_action()));

    /* Add the default OSCAR repositories */
    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome + "/scripts/opd2  --non-interactive --list-default-repos";
    pstream proc (cmd);
    string buf;
    while (proc >> buf) {
        QString str = buf.c_str();
        listReposWidget->addItem (str);
    }
    listReposWidget->update();

    connect(&command_thread, SIGNAL(opd_done(QString, QString)),
        this, SLOT(kill_popup(QString, QString)));

    connect(&command_thread, SIGNAL(oscar_config_done(QString)),
        this, SLOT(handle_oscar_config_result(QString)));

    connect(&command_thread, SIGNAL(sanity_command_done(QString)),
        this, SLOT(update_check_text_widget(QString)));

    connect (this->listOscarOptionsWidget, 
             SIGNAL(itemSelectionChanged()),
             this, 
             SLOT(newOscarOptionSelected()));

    connect (&add_distro_widget, SIGNAL (refreshListDistros()),
            this, SLOT(refresh_list_setup_distros()));

    command_thread.init ("", GET_SETUP_DISTROS);
    command_thread.run();

}

XOSCAR_MainWindow::~XOSCAR_MainWindow() 
{
}

/**
 * @author Geoffroy Vallee.
 *
 * Trigger the selection of the different OSCAR options (options on the 
 * left-hand side of the main GUI). The selection will activate the proper
 * widget page, giving the impression of using a standard "configuration 
 * widget".
 */
void XOSCAR_MainWindow::newOscarOptionSelected() 
{
    QString option;

    /* We get the selected repo. Note that the selection widget supports 
       currently a unique selection. */
    QList<QListWidgetItem *> list = listOscarOptionsWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    option = i.next()->text();

    if (option == "OSCAR Configuration") {
        stackedOptionsWidget->setCurrentIndex (0);
    } else if (option == "Cluster Management") {
        stackedOptionsWidget->setCurrentIndex (1);
    } else {
        cerr << "ERROR: Unknown option (" << option.toStdString() << ")" 
             << endl;
    }
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot executed when a OPD2 command ends (executed by the 
 * CommandExecutionThread). In this case, we need to update the list of OPKGs or
 * the list of repos, and we also need to close the dialog that asks to user to
 * wait while we are executing a OPD2 command.
 * Note the return depends on the query mode (see CommandExecutionThread.h file
 * for the list of supported mode). It means that the thread used for the 
 * execution of OPD2 commands can only do one query at a time. The mode defines
 * the type of query that as to be done (for example get the list of available
 * OPKGs for a specific repo or get the list of available repo).
 * Based on the mode only one result is returned for the OPD2 command execution
 * thread, others are empty QStrings.
 * Also note that we return QString because Qt signals can only deal by default
 * with very specific types. Therefore we use QString to simplify the 
 * implementation (natively supported).
 *
 * @param list_repos List of OSCAR repositories; result of the OPD2 command. The
 *                   list is empty is users request something else than the list
 *                   of repos.
 * @param list_opkgs List of OSCAR packages available via a specific OSCAR 
 *                   repository; result of the OPD2 command. The list is empty 
 *                   is users request something else than the OPKGs list.
 */
void XOSCAR_MainWindow::kill_popup(QString list_repos, QString list_opkgs)
{
    /* We update the list of available OPKGs for the selected OSCAR repo */
    string str = list_opkgs.toStdString();
    if (str.compare ("") != 0) {
        listOPKGsWidget->clear();
        vector<string> opkgs;
        Tokenize(str, opkgs, " ");
        vector<string>::iterator item;
        for(item = opkgs.begin(); item != opkgs.end(); item++) {
            string strD = *(item);
            this->listOPKGsWidget->addItem (strD.c_str());
        }
        listOPKGsWidget->update();
    }

    /* We update the list of available OSCAR repos */
    string str2 = list_repos.toStdString ();
    if (str2.compare ("") != 0) {
        listReposWidget->clear();
        vector<string> repos;
        Tokenize(str2, repos, " ");
        vector<string>::iterator item;
        for(item = repos.begin(); item != repos.end(); item++) {
            string strD = *(item);
            this->listReposWidget->addItem (strD.c_str());
        }
        listReposWidget->update();
    }

    /* We close the popup window that asks the user to wait */
    wait_popup->close();
}

/**
 * Equilvalent to the slip function in Perl: slip a string up, based on a 
 * delimiter which is a space by default.
 *
 * @param str String to slip up.
 * @param tokens Vector of string used to store the slit string.
 * @param delimiters Character used to split the string up. By default a space.
 * @todo Avoid the code duplication with the ORMAddRepoDialog class.
 */
void XOSCAR_MainWindow::Tokenize(const string& str,
                      vector<string>& tokens,
                      const string& delimiters = " ")
{
    // Skip delimiters at beginning.
    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
    // Find first "non-delimiter".
    string::size_type pos     = str.find_first_of(delimiters, lastPos);

    while (string::npos != pos || string::npos != lastPos)
    {
        // Found a token, add it to the vector.
        tokens.push_back(str.substr(lastPos, pos - lastPos));
        // Skip delimiters.  Note the "not_of"
        lastPos = str.find_first_not_of(delimiters, pos);
        // Find next "non-delimiter"
        pos = str.find_first_of(delimiters, lastPos);
    }
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot that handles the click on the "Add repo" button: it creates a dialog 
 * that allows users to enter a repository URL (with the yume or RAPT syntax).
 */
void XOSCAR_MainWindow::create_add_repo_window() 
{
    QObject::connect(add_oscar_repo_widget.buttonBox, SIGNAL(accepted()),
                     this, SLOT(add_repo_to_list()));
    add_oscar_repo_widget.show();
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot that handles the click on the "Add distro" button: it creates a dialog 
 * that allows users to select distros that are available but not yet setup for
 * OSCAR.
 */
void XOSCAR_MainWindow::create_add_distro_window() 
{
    add_distro_widget.show();
    add_distro_widget.refresh_list_distros();
}


/**
 * @author Geoffroy Vallee
 *
 * Slot that handles the selection of a specific repository in the list. For
 * that, we get the repository URL from the widget and we execute the opd2 
 * command execution thread. We also display the please wait dialog during the
 * execution of the thread.
 */
void XOSCAR_MainWindow::display_opkgs_from_repo()
{
    QString repo;

    /* We get the selected repo. Note that the selection widget supports 
       currently a unique selection. */
    QList<QListWidgetItem *> list = listReposWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    repo = i.next()->text();
    wait_popup = new ORMWaitDialog(0, repo);
    wait_popup->show();
    update();

    command_thread.init(repo, GET_LIST_OPKGS);
}

void XOSCAR_MainWindow::refresh_display_opkgs_from_repo()
{
    listOPKGsWidget->clear();
    display_opkgs_from_repo();
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot that handles the click of the ok button of the widget used to enter the
 * URL of a new repository. We get the URL and display the "Please wait" dialog,
 * the time to execute the OPD2 command (the actual query).
 */
void XOSCAR_MainWindow::add_repo_to_list()
{
    QString repo_url = add_oscar_repo_widget.lineEdit->text();

    wait_popup = new ORMWaitDialog(0, repo_url);
    wait_popup->show();
    update();

    command_thread.init(repo_url, GET_LIST_REPO);
    command_thread.init(repo_url, GET_LIST_OPKGS);
}

void XOSCAR_MainWindow::handle_oscar_config_result(QString list_distros)
{
    cout << list_distros.toStdString () << endl;
    /* We update the list of setup Linux distros */
    string str = list_distros.toStdString();
    if (str.compare ("") != 0) {
        listSetupDistrosWidget->clear();
        vector<string> distros;
        Tokenize(str, distros, " ");
        vector<string>::iterator item;
        for(item = distros.begin(); item != distros.end(); item++) {
            string strD = *(item);
            this->listSetupDistrosWidget->addItem (strD.c_str());
        }
        listSetupDistrosWidget->update();
    }
    command_thread.init("", INACTIVE);
}

void XOSCAR_MainWindow::refresh_list_setup_distros()
{
    listSetupDistrosWidget->clear();
    command_thread.init ("", GET_SETUP_DISTROS);
    command_thread.run();
}

void XOSCAR_MainWindow::do_system_sanity_check()
{
    sanityCheckTextWidget->clear();
    command_thread.init ("", DO_SYSTEM_SANITY_CHECK);
    command_thread.run();
}

void XOSCAR_MainWindow::do_oscar_sanity_check()
{
    sanityCheckTextWidget->clear();
    command_thread.init ("", DO_OSCAR_SANITY_CHECK);
    command_thread.run();
}

void XOSCAR_MainWindow::update_check_text_widget(QString text)
{
    sanityCheckTextWidget->setText(text);
}

/**
 * @author Geoffroy Vallee
 *
 * Slot called when the Quit button of the main window is clicked. This slot
 * makes sure that all xoscar related dialog are closed before exiting the
 * application.
 */
void XOSCAR_MainWindow::destroy()
{
    add_distro_widget.close();
    add_oscar_repo_widget.close();
    about_authors_widget.close();
    about_oscar_widget.close();
}

/**
 * @author Geoffroy Vallee
 *
 * Slot called when the menu item to have information of authors is clicked.
 * The widget displaying authors is then shown.
 */
void XOSCAR_MainWindow::handle_about_authors_action()
{
    about_authors_widget.show();
}

/**
 * @author Geoffroy Vallee
 *
 * Slot called when the menu item to have OSCAR information is clicked.
 * The widget displaying OSCAR info is then shown.
 */
void XOSCAR_MainWindow::handle_about_oscar_action()
{
    about_oscar_widget.show();
}

void XOSCAR_MainWindow::refresh_list_partitions ()
{
    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome 
                      + "/scripts/oscar-cluster --display-partitions";
    pstream command(cmd, pstreambuf::pstdout);
    std::string s, tmp;
    while (std::getline(command, s)) {
        QString partition_name = s.c_str();
        listClusterPartitionsWidget->addItem (partition_name);
    }

}

void XOSCAR_MainWindow::refresh_partition_info ()
{
    QListWidgetItem *item = listClusterPartitionsWidget->currentItem();
    partitonNameEditWidget->setText (item->text());

    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome 
                        + "/scripts/oscar-cluster --display-partition-nodes "
                        + item->text().toStdString();
    cout << "executing: " << cmd << endl;
    pstream command(cmd, pstreambuf::pstdout);
    std::string s, tmp;
    while (std::getline(command, tmp)) {
        s += tmp;
    }
    int i = 0;
    if (s.compare ("") != 0) {
        vector<string> nodes;
        Tokenize(s, nodes, " ");
        vector<string>::iterator item;
        for(item = nodes.begin(); item != nodes.end(); item++) {
            i++;
        }
    }
    PartitionNumberNodesSpinBox->setMinimum(i);
}


/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_MainGUI.cpp
 * @brief Actual implementation of the ORMMainWindow class.
 * @author Geoffroy Vallee
 */

#include "ORM_MainGUI.h"
#include "ORM_AddRepoGUI.h"

/**
 * @author Geoffroy Vallee.
 *
 * Class constructor: initialize the widget, connect signals and slots, and also
 * get the list of default OSCAR repositories.
 */
ORMMainWindow::ORMMainWindow(QDialog *parent)
    : QDialog(parent) 
{
    setupUi(this);

    /* Connect slots and signals */
    QObject::connect(AddButton, SIGNAL(clicked()),
                     this, SLOT(create_add_repo_window()));
    QObject::connect(listReposWidget, SIGNAL(itemSelectionChanged ()),
                     this, SLOT(display_opkgs_from_repo()));

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

    connect(&opd_thread, SIGNAL(opd_done(QString, QString)),
        this, SLOT(kill_popup(QString, QString)));
}

ORMMainWindow::~ORMMainWindow() 
{
}

/**
 * Equilvalent to the slip function in Perl: slip a string up, based on a 
 * delimiter which is a space by default.
 *
 * @param str String to slip up.
 * @param tokens Vector of string used to store the slit string.
 * @param delimiters Character used to split the string up. By default a space.
 */
void ORMMainWindow::Tokenize(const string& str,
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
void ORMMainWindow::kill_popup(QString list_repos, QString list_opkgs)
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
 * @author Geoffroy Vallee.
 *
 * Slot that handles the click on the "Add repo" button: it creates a dialog 
 * that allows users to enter a repository URL (with the yume or RAPT syntax).
 */
void ORMMainWindow::create_add_repo_window() 
{
    QObject::connect(add_widget.buttonBox, SIGNAL(accepted()),
                     this, SLOT(add_repo_to_list()));
    add_widget.show();
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot that handles the click of the ok button of the widget used to enter the
 * URL of a new repository. We get the URL and display the "Please wait" dialog,
 * the time to execute the OPD2 command (the actual query).
 */
void ORMMainWindow::add_repo_to_list()
{
    QString repo_url = add_widget.lineEdit->text();

    wait_popup = new ORMWaitDialog(0, repo_url);
    wait_popup->show();
    update();

    opd_thread.init(repo_url, GET_LIST_REPO);
    opd_thread.init(repo_url, GET_LIST_OPKGS);
}

/**
 * @author Geoffroy Vallee
 *
 * Slot that handles the selection of a specific repository in the list. For
 * that, we get the repository URL from the widget and we execute the opd2 
 * command execution thread. We also display the please wait dialog during the
 * execution of the thread.
 */
void ORMMainWindow::display_opkgs_from_repo()
{
    QString repo;

    /* We get the selected repo. Note that the selection widget supports 
       currently a unique selection. */
    QList<QListWidgetItem *> list = listReposWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    while (i.hasNext()) {
        repo = i.next()->text();
    }
    wait_popup = new ORMWaitDialog(0, repo);
    wait_popup->show();
    update();

    opd_thread.init(repo, GET_LIST_OPKGS);
}

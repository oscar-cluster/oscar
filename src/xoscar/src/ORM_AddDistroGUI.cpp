/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_AddDistroGUI.cpp
 * @brief Actual implementation of the ORMAddDistroDialog class.
 * @author Geoffroy Vallee
 */

#include "ORM_AddDistroGUI.h"

/**
 * @author Geoffroy Vallee.
 *
 */
ORMAddDistroDialog::ORMAddDistroDialog(QDialog *parent) 
    : QDialog (parent) 
{
    setupUi(this);
    connect (addDistroOkButton, SIGNAL(clicked()), 
             this, SLOT(newDistroSelected()));
    connect(listNonSetupDistrosWidget, SIGNAL(itemSelectionChanged ()),
                    this, SLOT(refresh_repos_url()));
}

ORMAddDistroDialog::~ORMAddDistroDialog ()
{
}
/*
void ORMAddDistroDialog::destroy()
{
    cout << "toto" << endl;
    this->close();
}*/

void ORMAddDistroDialog::newDistroSelected ()
{
    QString distro;
    char *ohome = getenv ("OSCAR_HOME");

    /* We get the selected distro. Note that the selection widget supports 
       currently a unique selection. */
    QList<QListWidgetItem *> list = listNonSetupDistrosWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    while (i.hasNext()) {
        distro= i.next()->text();
    }
    string cmd = (string) ohome + "/scripts/oscar-config --setup-distro "
                + distro.toStdString() + " "
                + "--use-distro-repo "
                + distroRepoEdit->text().toStdString() + " "
                + "--use-oscar-repo "
                + oscarRepoEdit->text().toStdString();
    cout << "Command to execute: " << cmd << endl;
    system (cmd.c_str());
    this->close();
    emit (refreshListDistros());
}

/**
 * Equilvalent to the slip function in Perl: slip a string up, based on a 
 * delimiter which is a space by default.
 *
 * @param str String to slip up.
 * @param tokens Vector of string used to store the slit string.
 * @param delimiters Character used to split the string up. By default a space.
 * @todo Avoid the code duplication with the ORMMainWindow class.
 */
void ORMAddDistroDialog::Tokenize(const string& str,
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

void ORMAddDistroDialog::refresh_list_distros() {
    QString list_distros;
    char *ohome = getenv ("OSCAR_HOME");

    /* First we get the list of supported distros */
    const string cmd = (string) ohome + "/scripts/oscar-config --supported-distros";
    ipstream proc(cmd);
    string buf, list_supported_distros;
    while (proc >> buf) {
        list_supported_distros += buf;
        list_supported_distros += " ";
    }

    /* Then we get the list of setup distros */
    const string cmd2 = (string) ohome 
                        + "/scripts/oscar-config --list-setup-distros";
    ipstream proc2(cmd2);
    string buf2, list_setup_distros;
    while (proc2 >> buf2) {
        list_setup_distros += buf2;
        list_setup_distros += " ";
    }
    if (list_setup_distros.find("No distribution is setup for OSCAR") 
        != string::npos) {
        list_setup_distros.replace(
            list_setup_distros.find("No distribution is setup for OSCAR"), 
                                    34, "");
    }

    /* the difference is the list of distros that can be setup for OSCAR and 
       that are not currently ready to be used. */
    vector<string> distros;
    Tokenize(list_setup_distros, distros, " ");
    vector<string>::iterator item;
    for(item = distros.begin(); item != distros.end(); item++) {
        string strD = *(item);
        list_supported_distros.replace(list_supported_distros.find(strD), 
                                       strD.length(), "");
    }

    /* Once we have the list, we update the widget */
    this->listNonSetupDistrosWidget->clear();
    vector<string> d;
    Tokenize(list_supported_distros, d, " ");
    for(item = d.begin(); item != d.end(); item++) {
        string strD = *(item);
        this->listNonSetupDistrosWidget->addItem (strD.c_str());
    }
}

/**
 * @author Geoffroy Vallee
 *
 * @todo We need here to have an option for oscar-config that gives the default
 * oscar repo, and the default distro repo. Without these two capabilities, it
 * is not possible to fill up empty widgets.
 */
void ORMAddDistroDialog::refresh_repos_url()
{
    QString distro;
    char *ohome = getenv ("OSCAR_HOME");

    /* We get the selected distro. Note that the selection widget supports 
       currently a unique selection. */
    QList<QListWidgetItem *> list = listNonSetupDistrosWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    while (i.hasNext()) {
        distro = i.next()->text();
    }

    string cmd = (string) ohome 
                + "/scripts/oscar-config --display-default-distro-repo "
                + distro.toStdString();
    ipstream proc(cmd);
    string buf, repo;
    while (proc >> buf) {
        repo += buf;
        repo += " ";
    }
    distroRepoEdit->setText(repo.c_str());

    string cmd2 = (string) ohome 
                + "/scripts/oscar-config --display-default-oscar-repo "
                + distro.toStdString();
    ipstream proc2(cmd2);
    repo = "";
    while (proc2 >> buf) {
        repo += buf;
        repo += " ";
    }
    oscarRepoEdit->setText(repo.c_str());
}


/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_AddRepoGUI.cpp
 * @brief Actual implementation of the ORMAddRepoDialog class.
 * @author Geoffroy Vallee
 */

#include "ORM_AddRepoGUI.h"

/**
 * @author Geoffroy Vallee.
 *
 * Class constructor: the widget gathers (i) a text box when the user can enter 
 * the repository URL; and (ii) a combo box where the user specify for which 
 * distribution the repository is made for. For that, it initializes the widget,
 * gets the list of setup distros in order to let user specify what distribution
 * the repository targets when a new repo is added
 *
 * @todo When we get the list of setup distros, if the list is empty we should
 * display a dialog box that says that unfortunately no distribution is 
 * currently setup.
 * @todo When a dialog will be implemented to notify to users that no 
 * distribution has been setup, we should also pop up a new widget for the 
 * configuration of OSCAR (oscar-config tftpboot related stuff).
 */
ORMAddRepoDialog::ORMAddRepoDialog(QDialog *parent) 
    : QDialog (parent) 
{
    QString list_distros;

    setupUi(this);
    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome + "/scripts/oscar-config --list-setup-distros";
    ipstream proc(cmd);
    string buf, tmp_list;
    while (proc >> buf) {
        tmp_list += buf;
        tmp_list += " ";
    }
    vector<string> distros;
    Tokenize(tmp_list, distros, " ");
    vector<string>::iterator item;
    for(item = distros.begin(); item != distros.end(); item++) {
        string strD = *(item);
        this->distroComboBox->addItem (strD.c_str());
    }
}

ORMAddRepoDialog::~ORMAddRepoDialog ()
{
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
void ORMAddRepoDialog::Tokenize(const string& str,
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

/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_AddDistroGUI.h
 * @brief Defines the class ORMAddDistroDialog that implements a widget that 
 *        allows users to enter a new OSCAR repository.
 * @author Geoffroy Vallee
 *
 * The file defines the widget for the dialog which allows user to setup a new
 * Linux distirbution for the usage of OSCAR. For that it inherents from the 
 * class generated from the .ui file created with QtDesigner.
 */

#ifndef ORM_ADDDISTROGUI_H
#define ORM_ADDDISTROGUI_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <fstream>
#include <unistd.h>

#include "ui_AddDistroWidget.h"
#include "pstream.h"

using namespace std;
using namespace redi;

class ORMAddDistroDialog : public QDialog, public Ui_AddDistroDialog
{
Q_OBJECT

public:
    ORMAddDistroDialog(QDialog *parent = 0);
    ~ORMAddDistroDialog();
    void refresh_list_distros();

public slots:
    void newDistroSelected();
    void refresh_repos_url();

signals:
    virtual void refreshListDistros();

private:
    void Tokenize(const string& str,
        vector<string>& tokens,
        const string& delimiters);
};

namespace xorm {
    class XORM_AddDistroDialog: public ORMAddDistroDialog {};
} // namespace xorm

#endif // ORM_ADDDISTROGUI_H

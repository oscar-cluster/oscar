/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_MainGUI.h
 * @brief Defines the class ORMMainWindow that implements the main xorm widget.
 * @author Geoffroy Vallee
 *
 * The file defines the main widget of xorm. For that it inherents from the 
 * class generated from the .ui file created with QtDesigner. This widget 
 * "drives" all other widgets.
 */


#ifndef ORM_MAINGUI_H
#define ORM_MAINGUI_H

#include <QApplication>
#include <QPushButton>
#include <QLabel>
#include <QWidget>
#include <QString>
#include <QMainWindow>

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <fstream>
#include <unistd.h>

#include "pstream.h"
#include "ui_ORM.h"
#include "ORM_AddRepoGUI.h"
#include "CommandExecutionThread.h"
#include "ORM_WaitDialog.h"

using namespace Ui; 
using namespace std;
using namespace redi;

class ORMMainWindow : public QDialog, public MainWindow
{
Q_OBJECT

public:
    ORMMainWindow(QDialog *parent = 0);
    ~ORMMainWindow();

public slots:
    void create_add_repo_window ();
    void add_repo_to_list ();
    void display_opkgs_from_repo ();
    void kill_popup (QString, QString);

private:
    void Tokenize(const string& str,
        vector<string>& tokens,
        const string& delimiters);

    ORMAddRepoDialog add_widget;
    ORMWaitDialog*  wait_popup;
    CommandExecutionThread opd_thread;
};

/**
 * @namespace xorm
 * @author Geoffroy Vallee.
 * @brief The xorm namespace gathers all classes needed for XORM.
 */
namespace xorm {
    class XORM_MainWindow: public ORMMainWindow {};
} // namespace xorm

#endif //ORM_MAINGUI_H

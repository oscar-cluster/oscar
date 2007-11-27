/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_WaitDialog.h
 * @brief Defines the class ORMWaitDialog that implements a widget that asks 
 *        users to wait during the execution of OPD2 commands.
 * @author Geoffroy Vallee
 *
 * The file defines the widget for the dialog which asks for users to wait 
 * during the execution of a OPD2 command. For that it inherents from the 
 * class generated from the .ui file created with QtDesigner.
 */

#ifndef ORM_WAITDIALOG_H
#define ORM_WAITDIALOG_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include "ui_WaitDialog.h"

using namespace std;

class ORMWaitDialog : public QDialog, public Ui_WaitDialog
{
Q_OBJECT

public:
    ORMWaitDialog(QDialog *parent = 0, QString url = "");
    ~ORMWaitDialog();

};

namespace xorm {
    class XORM_WaitDialog: public ORMWaitDialog {};
} // namespace xorm


#endif // ORM_WAITDIALOG_H

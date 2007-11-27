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

#ifndef XOSCAR_ABOUTOSCARSDIALOG_H
#define XOSCAR_ABOUTAUTHORSDIALOG_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include "ui_AboutOSCARDialog.h"

using namespace std;

class XOSCAR_AboutOscarDialog : public QDialog, public Ui_AboutOscarDialog
{
Q_OBJECT

public:
    XOSCAR_AboutOscarDialog(QDialog *parent = 0);
    ~XOSCAR_AboutOscarDialog();

};

namespace xoscar {
    class XOSCAR_AboutOscarDialog: public Ui_AboutOscarDialog {};
} // namespace xorm


#endif // XOSCAR_ABOUTAUTHORSDIALOG_H

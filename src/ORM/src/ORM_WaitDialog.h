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

#endif // ORM_WAITDIALOG_H

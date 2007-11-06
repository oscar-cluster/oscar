#ifndef ORM_ADDREPOGUI_H
#define ORM_ADDREPOGUI_H

#include "ui_AddRepoWidget.h"

using namespace std;

class ORMAddRepoDialog : public QDialog, public Ui_AddRepoDialog
{
Q_OBJECT

public:
    ORMAddRepoDialog(QDialog *parent = 0);
    ~ORMAddRepoDialog();

//    Ui::AddRepoDialog ui;

};

#endif // ORM_ADDREPOGUI_H

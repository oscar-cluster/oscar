#include "ORM_WaitDialog.h"

ORMWaitDialog::ORMWaitDialog(QDialog *parent, QString repo_url)
    : QDialog (parent)
{
    setupUi(this);
    repoURLLabel->setText (repo_url);
}

ORMWaitDialog::~ORMWaitDialog ()
{
}


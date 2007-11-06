#ifndef COMMANDEXECUTIONTHREAD_H
#define COMMANDEXECUTIONTHREAD_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <fstream>
#include <unistd.h>

#include <QThread>
#include <QWaitCondition>

//#include "ORM_WaitDialog.h"
#include "ui_ORM.h"
#include "pstream.h"

using namespace std;
using namespace redi;

#define GET_LIST_REPO 1
#define GET_LIST_OPKGS 2

class CommandExecutionThread : public QThread 
{
    Q_OBJECT

public:
    CommandExecutionThread(QObject *parent = 0);
    ~CommandExecutionThread();
    void init (QString, int);
    void run();

signals:
    virtual void opd_done (QString, QString);

protected:

private:
    QString repo_url;
    int mode;
};

#endif // COMMANDEXECUTIONTHREAD_H

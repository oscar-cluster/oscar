/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file CommandExecutionThread.h
 * @brief Defines a class used to execute OPD2 commands in a separate thread.
 * @author Geoffroy Vallee
 *
 * Using Qt4, the main thread, i.e., the application process, is used to
 * display widgets and as a runtime for the GUI. Therefore is the "main
 * thread" is used to do important tasks, the GUI becomes very difficult
 * to use for users (slow refresh for instance).
 * To avoid this issue, we create a separate thread to execute OPD2 commands.
 * Note that the current implementation is not perfect, there is not real
 * protection against concurency, we currently assume that only one action
 * can be made at a time with the GUI.
 */

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

namespace xorm {
    class XORM_CommandExecutionThread: public CommandExecutionThread {};
} // namespace xorm

#endif // COMMANDEXECUTIONTHREAD_H

/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file main.cpp
 * @brief Main function that launched the application.
 * @author Geoffroy Vallee
 */

#include <QApplication>
#include <QPushButton>
#include <QLabel>
#include <QWidget>
#include <QString>

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <fstream>
#include <unistd.h>

// #include "pstream.h"
#include "XOSCAR_MainWindow.h"

using namespace std;
//using namespace xorm;

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    /* We check if the OSCAR_HOME environment variable is set */
    char * ohome;
    ohome = getenv ("OSCAR_HOME");
    if (!ohome) {
        cerr << "ERROR: OSCAR_HOME is not set." << endl;
        return -1;
    }

    XOSCAR_MainWindow win;
    win.show();
    return app.exec();
} 

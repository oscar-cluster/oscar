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

#include "pstream.h"
#include "ORM_MainGUI.h"

using namespace std;

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

    QMainWindow w;
    ORMMainWindow dialog;
    dialog.show();    

    return app.exec();
} 

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

using namespace Ui; 
using namespace std;
using namespace redi;

class ORMMainWindow : public QMainWindow
{
Q_OBJECT

public:
    ORMMainWindow(QWidget *parent = 0);
    ~ORMMainWindow();

public slots:
    void create_add_repo_window ();
    void add_repo_to_list ();
    void display_opkgs_from_repo ();

private:
    Ui::MainWindow ui;
    ORMAddRepoDialog* add_widget;
};

#endif //ORM_MAINGUI_H

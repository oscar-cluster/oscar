#ifndef XOSCAR_MAINWINDOW_H
#define XOSCAR_MAINWINDOW_H

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

#include "ui_xoscar_mainwindow.h"
#include "ORM_AddRepoGUI.h"
#include "ORM_AddDistroGUI.h"
#include "CommandExecutionThread.h"
#include "ORM_WaitDialog.h"
#include "XOSCAR_AboutAuthorsDialog.h"
#include "XOSCAR_AboutOscarDialog.h"

using namespace Ui; 
using namespace std;
// using namespace redi;

class XOSCAR_MainWindow : public QMainWindow, public MainWindow
{
Q_OBJECT

public:
    XOSCAR_MainWindow(QMainWindow *parent = 0);
    ~XOSCAR_MainWindow();

public slots:
    void newOscarOptionSelected ();
    void create_add_repo_window ();
    void create_add_distro_window ();
    void add_repo_to_list ();
    void display_opkgs_from_repo ();
    void kill_popup (QString, QString);
    void handle_oscar_config_result (QString);
    void refresh_display_opkgs_from_repo();
    void refresh_list_setup_distros();
    void do_system_sanity_check();
    void do_oscar_sanity_check();
    void update_check_text_widget(QString);
    void destroy();
    void handle_about_authors_action();
    void handle_about_oscar_action();
    void refresh_list_partitions();
    void refresh_partition_info();

private:
    void Tokenize(const string& str,
        vector<string>& tokens,
        const string& delimiters);

    XOSCAR_AboutAuthorsDialog about_authors_widget;
    XOSCAR_AboutOscarDialog about_oscar_widget;
    ORMAddRepoDialog add_oscar_repo_widget;
    ORMAddDistroDialog add_distro_widget;
    ORMWaitDialog*  wait_popup;
    CommandExecutionThread command_thread;
};

/**
 * @namespace xorm
 * @author Geoffroy Vallee.
 * @brief The xorm namespace gathers all classes needed for XORM.
 */
namespace xoscar {
    class XOSCAR_MainWindow: public Ui_MainWindow {};
} // namespace xorm


#endif // XOSCAR_MAINWINDOW_H

#include "ORM_MainGUI.h"
#include "ORM_AddRepoGUI.h"

//ORMMainWindow(QMainWindow *parent = 0) : QMainWindow(parent) {
ORMMainWindow::ORMMainWindow(QWidget *parent)
    : QMainWindow(parent) 
{
    ui.setupUi(this);

    /* Connect slots and signals */
    QObject::connect(ui.AddButton, SIGNAL(clicked()),
                     this, SLOT(create_add_repo_window()));
    QObject::connect(ui.listReposWidget, SIGNAL(itemSelectionChanged ()),
                     this, SLOT(display_opkgs_from_repo()));


    /* Add the default OSCAR repositories */
    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome + "/scripts/opd2  --non-interactive --list-default-repos";
    pstream proc (cmd);
    string buf;
    while (proc >> buf) {
        QString str = buf.c_str();
        ui.listReposWidget->addItem (str);
    }
    ui.listReposWidget->update();

}

ORMMainWindow::~ORMMainWindow() 
{
}

void ORMMainWindow::create_add_repo_window() 
{
    add_widget = new ORMAddRepoDialog();
    QObject::connect(add_widget->ui.buttonBox, SIGNAL(accepted()),
                     this, SLOT(add_repo_to_list()));
    add_widget->show();
}

void ORMMainWindow::add_repo_to_list()
{
    QString qstr = add_widget->ui.lineEdit->text ();
    char *ohome = getenv ("OSCAR_HOME");

    /* We update the list of available OPKGs, based on the new repo */
    ui.listOPKGsWidget->clear();
    const string cmd = (string) ohome + "/scripts/opd2  --non-interactive " + "--repo " + qstr.toStdString ();
    cout << "Executing: " << cmd;
    pstream proc (cmd);
    string buf;
    while (proc >> buf) {
        qstr = buf.c_str();
        ui.listOPKGsWidget->addItem (qstr);
    }
    ui.listOPKGsWidget->update ();

    /* We refresh the list of available repositories */
    ui.listReposWidget->clear();
    const string cmd2 = (string) ohome + "/scripts/opd2  --non-interactive --list-repos";
    cout << "Executing: " << cmd2;
    pstream proc2 (cmd2);
    while (proc2 >> buf) {
        qstr = buf.c_str();
        ui.listReposWidget->addItem (qstr);
    }
    ui.listReposWidget->update ();   
}

void ORMMainWindow::display_opkgs_from_repo()
{
    string repo;

    /* We get the selected repo */
    QList<QListWidgetItem *> list = ui.listReposWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    while (i.hasNext()) {
        repo = i.next()->text().toStdString();
    }
    /* We update the list of available OPKGs, based on the new repo */
    ui.listOPKGsWidget->clear();
    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome + "/scripts/opd2  --non-interactive " + "--repo " + repo;
    cout << "Executing: " << cmd;
    pstream proc (cmd);
    string buf;
    while (proc >> buf) {
        QString qstr = buf.c_str();
        ui.listOPKGsWidget->addItem (qstr);
    }
    ui.listOPKGsWidget->update ();
}

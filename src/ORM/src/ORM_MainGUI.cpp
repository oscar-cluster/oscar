#include "ORM_MainGUI.h"
#include "ORM_AddRepoGUI.h"

ORMMainWindow::ORMMainWindow(QDialog *parent)
    : QDialog(parent) 
{
    setupUi(this);

    /* Connect slots and signals */
    QObject::connect(AddButton, SIGNAL(clicked()),
                     this, SLOT(create_add_repo_window()));
    QObject::connect(listReposWidget, SIGNAL(itemSelectionChanged ()),
                     this, SLOT(display_opkgs_from_repo()));

    /* Add the default OSCAR repositories */
    char *ohome = getenv ("OSCAR_HOME");
    const string cmd = (string) ohome + "/scripts/opd2  --non-interactive --list-default-repos";
    pstream proc (cmd);
    string buf;
    while (proc >> buf) {
        QString str = buf.c_str();
        listReposWidget->addItem (str);
    }
    listReposWidget->update();

    connect(&opd_thread, SIGNAL(opd_done(QString, QString)),
        this, SLOT(kill_popup(QString, QString)));
}

ORMMainWindow::~ORMMainWindow() 
{
}

void ORMMainWindow::Tokenize(const string& str,
                      vector<string>& tokens,
                      const string& delimiters = " ")
{
    // Skip delimiters at beginning.
    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
    // Find first "non-delimiter".
    string::size_type pos     = str.find_first_of(delimiters, lastPos);

    while (string::npos != pos || string::npos != lastPos)
    {
        // Found a token, add it to the vector.
        tokens.push_back(str.substr(lastPos, pos - lastPos));
        // Skip delimiters.  Note the "not_of"
        lastPos = str.find_first_not_of(delimiters, pos);
        // Find next "non-delimiter"
        pos = str.find_first_of(delimiters, lastPos);
    }
}

void ORMMainWindow::kill_popup(QString list_repos, QString list_opkgs)
{
    /* We update the list of available OPKGs for the selected OSCAR repo */
    string str = list_opkgs.toStdString();
    if (str.compare ("") != 0) {
        listOPKGsWidget->clear();
        vector<string> opkgs;
        Tokenize(str, opkgs, " ");
        vector<string>::iterator item;
        for(item = opkgs.begin(); item != opkgs.end(); item++) {
            string strD = *(item);
            this->listOPKGsWidget->addItem (strD.c_str());
        }
        listOPKGsWidget->update();
    }

    /* We update the list of available OSCAR repos */
    string str2 = list_repos.toStdString ();
    if (str2.compare ("") != 0) {
        listReposWidget->clear();
        vector<string> repos;
        Tokenize(str2, repos, " ");
        vector<string>::iterator item;
        for(item = repos.begin(); item != repos.end(); item++) {
            string strD = *(item);
            this->listReposWidget->addItem (strD.c_str());
        }
        listReposWidget->update();
    }

    /* We close the popup window that asks the user to wait */
    wait_popup->close();
}

void ORMMainWindow::create_add_repo_window() 
{
    QObject::connect(add_widget.buttonBox, SIGNAL(accepted()),
                     this, SLOT(add_repo_to_list()));
    add_widget.show();
}

void ORMMainWindow::add_repo_to_list()
{
    QString repo_url = add_widget.lineEdit->text();

    wait_popup = new ORMWaitDialog(0, repo_url);
    wait_popup->show();
    update();

    opd_thread.init(repo_url, GET_LIST_REPO);
    opd_thread.init(repo_url, GET_LIST_OPKGS);
}

void ORMMainWindow::display_opkgs_from_repo()
{
    QString repo;

    /* We get the selected repo. Note that the selection widget supports 
       currently a unique selection. */
    QList<QListWidgetItem *> list = listReposWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    while (i.hasNext()) {
        repo = i.next()->text();
    }
    wait_popup = new ORMWaitDialog(0, repo);
    wait_popup->show();
    update();

    opd_thread.init(repo, GET_LIST_OPKGS);
}

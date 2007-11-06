

#include "CommandExecutionThread.h"

CommandExecutionThread::CommandExecutionThread(QObject *parent) 
    : QThread (parent)
{
}

CommandExecutionThread::~CommandExecutionThread()
{
}

void CommandExecutionThread::init (QString url, int m)
{
    repo_url = url;
    mode = m;
    start(QThread::TimeCriticalPriority);
}

void CommandExecutionThread::run()
{
    char *ohome = getenv ("OSCAR_HOME");
    QString list_opkgs = "", list_repos = "";

    if (mode == GET_LIST_REPO) {
        /* We refresh the list of available repositories */
        const string cmd2 = (string) ohome + "/scripts/opd2  --non-interactive --list-repos";
        ipstream proc2 (cmd2);
        string buf2, tmp_list2;
        while (proc2 >> buf2) {
            tmp_list2 += buf2;
            tmp_list2 += " ";
        }
        list_repos = tmp_list2.c_str();
    } else if (mode == GET_LIST_OPKGS) {
        /* We update the list of available OPKGs, based on the new repo */
        const string cmd = (string) ohome + "/scripts/opd2  --non-interactive " + "--repo " + repo_url.toStdString ();
        ipstream proc(cmd);
        string buf, tmp_list;
        while (proc >> buf) {
            tmp_list += buf;
            tmp_list += " ";
        list_opkgs = tmp_list.c_str();
        }
    } else {
        cerr << "ERROR: Unsupported mode: " << mode << endl;
        exit (-1);
    }

    emit (opd_done(list_repos, list_opkgs));
}

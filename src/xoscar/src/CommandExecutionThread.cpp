/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file CommandExecutionThread.cpp
 * @brief Actual implementation of the CommandExecutionThread class.
 * @author Geoffroy Vallee
 */

#include "CommandExecutionThread.h"

CommandExecutionThread::CommandExecutionThread(QObject *parent) 
    : QThread (parent)
{
}

CommandExecutionThread::~CommandExecutionThread()
{
}

/**
  * @author Geoffroy Vallee.
  *
  * Thread initialization function. Used to set data used later on by the
  * thread when running.
  *
  * @param url Repository URL that has to be used by the thread when running.
  * @param m Query mode. For instance, get the list of repositories or 
  *          the list of OSCAR packages for the specified repository. The 
  *          different modes are defined in CommandExecutionThread.h
  */
void CommandExecutionThread::init (QString url, int m)
{
    repo_url = url;
    mode = m;
    start(QThread::TimeCriticalPriority);
}

/**
  * @author Geoffroy Vallee.
  */
void CommandExecutionThread::run()
{
    char *ohome = getenv ("OSCAR_HOME");
    QString list_opkgs = "", list_repos = "";

    if (mode == INACTIVE) {
        return;
    } else if (mode == GET_LIST_REPO) {
        /* We refresh the list of available repositories */
        const string cmd2 = (string) ohome + "/scripts/opd2  --non-interactive --list-repos";
        ipstream proc2 (cmd2);
        string buf2, tmp_list2;
        while (proc2 >> buf2) {
            tmp_list2 += buf2;
            tmp_list2 += " ";
        }
        list_repos = tmp_list2.c_str();
        emit (opd_done(list_repos, list_opkgs));
        return;
    } else if (mode == GET_LIST_OPKGS) {
        /* We update the list of available OPKGs, based on the new repo */
        const string cmd = (string) ohome + "/scripts/opd2  --non-interactive " + "--repo " + repo_url.toStdString ();
        ipstream proc(cmd);
        string buf, tmp_list;
        while (proc >> buf) {
            tmp_list += buf;
            tmp_list += " ";
        }
        list_opkgs = tmp_list.c_str();
        emit (opd_done(list_repos, list_opkgs));
        return;
    } else if (mode == GET_SETUP_DISTROS) {
        /* We update the list of available OPKGs, based on the new repo */
        QString result;
        const string cmd = (string) ohome + "/scripts/oscar-config --list-setup-distros";
        ipstream proc(cmd);
        string buf, tmp_list;
        while (proc >> buf) {
            tmp_list += buf;
            tmp_list += " ";
        }
        result = tmp_list.c_str();
        emit (oscar_config_done(result));
        return;
    } else if (mode == DO_SYSTEM_SANITY_CHECK) {
        QString result;
        const string cmd = (string) ohome + "/scripts/system-sanity";
        pstream command(cmd, pstreambuf::pstdout);
        std::string s, tmp;
        while (std::getline(command, s)) {
            tmp += s;
            tmp += "\n";
        }
        result = tmp.c_str();
        emit (sanity_command_done(result));
        return;
    } else if (mode == DO_OSCAR_SANITY_CHECK) {
        QString result;
        const string cmd = (string) ohome + "/scripts/sanity_check";
        pstream command(cmd, pstreambuf::pstdout);
        std::string s, tmp;
        while (std::getline(command, s)) {
            tmp += s;
            tmp += "\n";
        }
        result = tmp.c_str();
        emit (sanity_command_done(result));
        return;
    } else {
        cerr << "ERROR: Unsupported mode: " << mode << endl;
        exit (-1);
    }

}

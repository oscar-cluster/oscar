/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_WaitDialog.cpp
 * @brief Actual implementation of the ORMWaitDialog class.
 * @author Geoffroy Vallee
 */

#include "ORM_WaitDialog.h"

ORMWaitDialog::ORMWaitDialog(QDialog *parent, QString repo_url)
    : QDialog (parent)
{
    setupUi(this);
    repoURLLabel->setText (repo_url);
}

ORMWaitDialog::~ORMWaitDialog ()
{
}


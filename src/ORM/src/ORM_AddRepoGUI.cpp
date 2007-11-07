/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file ORM_AddRepoGUI.cpp
 * @brief Actual implementation of the ORMAddRepoDialog class.
 * @author Geoffroy Vallee
 */

#include "ORM_AddRepoGUI.h"

ORMAddRepoDialog::ORMAddRepoDialog(QDialog *parent) 
    : QDialog (parent) 
{
    setupUi(this);
}

ORMAddRepoDialog::~ORMAddRepoDialog ()
{
}

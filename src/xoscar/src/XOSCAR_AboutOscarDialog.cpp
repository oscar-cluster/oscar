/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file XOSCAR_AboutOscarDialog.cpp
 * @brief Actual implementation of the XOSCAR_AboutOscarDialog class.
 * @author Geoffroy Vallee
 */

#include "XOSCAR_AboutOscarDialog.h"

XOSCAR_AboutOscarDialog::XOSCAR_AboutOscarDialog(QDialog *parent)
    : QDialog (parent)
{
    setupUi(this);
}

XOSCAR_AboutOscarDialog::~XOSCAR_AboutOscarDialog ()
{
}


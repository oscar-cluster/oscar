/* Code initial taken from Qt documentation: 
 * http://doc.trolltech.com/qq/qq09-file-browser.html
 */

/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the xorm software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file XOSCAR_FileBrowser.cpp
 * @brief Actual implementation of the XOSCAR_FileBrowser class.
 * @author Geoffroy Vallee
 */

#include "XOSCAR_FileBrowser.h"

XOSCAR_FileBrowser::XOSCAR_FileBrowser(const QString &filter,
                         QDialog *parent,
                         const char *name)
        : QDialog (parent)
{
    setupUi(this);
    nameFilter = filter;
    setDir(QDir::currentPath());
    connect(fileListingWidget, SIGNAL(itemClicked(QListWidgetItem *)),
            this, SLOT(selectionChanged(QListWidgetItem *)));
    connect(selectFileBrowserButton, SIGNAL(clicked()),
            this, SLOT(itemSelected()));
}

/**
 * @author Geoffroy Vallee.
 *
 * Update the current path and update the widget with the list of files & 
 * directories accordingly.
 *
 * @param path Path of the new current directory.
 */
void XOSCAR_FileBrowser::setDir(const QString &path)
{
    QDir dir(path, nameFilter, QDir::DirsFirst);
    if (!dir.isReadable())
        return;
    if(fileListingWidget->currentRow() == -1) {
        cout << fileListingWidget->currentRow() << endl;
        fileListingWidget->clear();
    }

    QStringList entries = dir.entryList();
    QStringList::ConstIterator it = entries.constBegin();
    while (it != entries.constEnd()) {
        if (*it != ".")
            fileListingWidget->addItem(*it);
        ++it;
    }
    basePath = dir.canonicalPath();
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot called when the user click on an element of the list of files & dir.
 * If the item the user clicked on is a directory or "..", we change the 
 * current directory and update the view.
 *
 * @param i Selected item (i.e., selected file or directory).
 */
void XOSCAR_FileBrowser::selectionChanged(QListWidgetItem *i)
{
    if (fileListingWidget->currentRow() == -1) {
        return;
    }
    QString text;
    text = i->text();
    QString path = basePath + "/" + text;
    if (QFileInfo(path).isDir() || text.compare("..") == 0) {
        /* do not forget the unselect the current item or when you clear the
           the widget, it crashes. */
        fileListingWidget->setCurrentRow(-1);
        setDir(path);
    }
}

/**
 * @author Geoffroy Vallee.
 *
 * Slot called when the user click on "Open" button, get the selected item,
 * emit the signal to notify that a file has to be selected. The signal provides
 * the path of the file that has to be open.
 *
 * @todo We do not check that when the user click "Open", a file is actually
 *       selected. The "Open" button should be disable until a file is selected.
 */
void XOSCAR_FileBrowser::itemSelected()
{
    QString text;
    QList<QListWidgetItem *> list = fileListingWidget->selectedItems();
    QListIterator<QListWidgetItem *> i(list);
    text = i.next()->text();

    const QString path = basePath + "/" + text;
    if (QFileInfo(path).isDir())
        setDir(path);
    emit (fileSelected(path));
    close();
}

/* Code initial taken from Qt documentation: 
 * http://doc.trolltech.com/qq/qq09-file-browser.html
 */

/**
 * @file XOSCAR_FileBrowser.h
 * @brief Defines the class XOSCAR_FileBrowser that implements a widget for file selection.
 * @author Geoffroy Vallee
 *
 * The class provides a portable widget for file selection. For that it 
 * inherents from the class generated from the .ui file created with QtDesigner.
 */

#ifndef XOSCAR_FILE_BROWSER_H
#define XOSCAR_FILE_BROWSER_H

#include <QDir>

#include "ui_FileBrowser.h"
#include <iostream>

using namespace std;

class XOSCAR_FileBrowser : public QDialog, public Ui_FileBrowserDialog
{
Q_OBJECT

public:
    XOSCAR_FileBrowser(const QString &filter,
                QDialog *parent = 0, 
                const char *name = 0);
    void setDir(const QString &path);

signals:
    virtual void fileSelected(const QString &fileName);

private slots:
    void itemSelected();
    void selectionChanged(QListWidgetItem *);

private:
    QString nameFilter;
    QString basePath;
};

/**
 * @namespace xoscar
 * @author Geoffroy Vallee.
 * @brief The xoscar namespace gathers all classes needed for XOSCAR.
 */
namespace xoscar {
    class XOSCAR_FileBrowser: public Ui_FileBrowserDialog {};
} // namespace xoscar

#endif // XOSCAR_FILE_BROWSER_H

unix {
  UI_DIR = .ui
  MOC_DIR = .moc
  OBJECTS_DIR = .obj
}
FORMS	= NodeMgmtDialog.ui \
	NodeSettingsDialog.ui
IMAGES	= images/ball1.png \
	images/ball2.png \
	images/ball3.png \
	images/ball4.png \
	images/ball5.png \
	images/close.png \
	images/download.png \
	images/editcopy.png \
	images/editcut.png \
	images/editpaste.png \
	images/filenew.png \
	images/fileopen.png \
	images/filesave.png \
	images/getinfo.png \
	images/nextarrow.png \
	images/oscarbg.png \
	images/print.png \
	images/redo.png \
	images/searchfind.png \
	images/undo.png
TEMPLATE	=app
CONFIG	+= qt warn_on release
LANGUAGE	= C++

unix {
  UI_DIR = .ui
  MOC_DIR = .moc
  OBJECTS_DIR = .obj
}
FORMS	= NodeMgmtDialog.ui \
	NodeSettingsDialog.ui
TEMPLATE	=app
CONFIG	+= qt warn_on release
LANGUAGE	= C++

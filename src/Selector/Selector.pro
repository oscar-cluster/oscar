unix {
  UI_DIR = .ui
  MOC_DIR = .moc
  OBJECTS_DIR = .obj
}
FORMS	= Selector.ui
IMAGES	= images/backarrow.png \
	images/close.png \
	images/nextarrow.png
TEMPLATE	=app
CONFIG	+= qt warn_on release
LANGUAGE	= C++

unix {
  UI_DIR = .ui
  MOC_DIR = .moc
  OBJECTS_DIR = .obj
}
FORMS	= Opder.ui \
	OpderDownloadInfo.ui \
	OpderDownloadPackage.ui \
	OpderAddRepository.ui
IMAGES	= images/backarrow.png \
	images/nextarrow.png \
	images/close.png \
	images/download.png \
	images/getinfo.png \
	images/ball1.png \
	images/ball2.png \
	images/ball3.png \
	images/ball4.png \
	images/ball5.png
TEMPLATE	=app
CONFIG	+= qt warn_on release
LANGUAGE	= C++

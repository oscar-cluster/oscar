PUIC		= @PUIC@
PERL_CW		= @PERL@ -cw

pms		= \
		nodesettingsDialog.pm \
		nodemgmtTable.pm \
		nodemgmtDialog.pm

pls		= nodemgmtDialog.pl

uis		= \
		nodemgmtdialog.ui \
		nodesettingsdialog.ui

uihs		= \
		nodemgmtdialog.ui.h \
		nodesettingsdialog.ui.h

# These are items to be distributed
EXTRA_DIST		= $(pms) $(pls) $(uis) $(uihs) GUI.xml

instdir			= $(prefix)/Installer/NodeMgmt
inst_SCRIPTS		= $(pls) $(pms)
inst_DATA		= GUI.xml

nodemgmtDialog.pl: nodemgmtdialog.ui.h nodemgmtdialog.ui $(pms)
	$(PUIC) -x -o nodemgmtDialog.pl nodemgmtdialog.ui

nodemgmtDialog.pm: nodemgmtdialog.ui.h nodemgmtdialog.ui nodesettingsDialog.pm nodemgmtTable.pm 
	$(PUIC) -o nodemgmtDialog.pm nodemgmtdialog.ui

nodesettingsDialog.pm: nodesettingsdialog.ui nodesettingsdialog.ui.h
	$(PUIC) -o nodesettingsDialog.pm nodesettingsdialog.ui

# Hook target that Automake runs at the end of its own internal
# "clean" target.
clean-local:
	rm -f nodemgmtDialog.pm nodesettingsDialog.pm $(pls)

all-local: $(pls) $(pms)
#echo "Fixing QWidgetStack problem"
#perl -pi -e 's/QWidgetStack/Qt::WidgetStack/' *.p*

check-local: $(pls) $(pms)
	@err=0; \
	for myfile in $(pls) $(pms); do \
	  $(PERL_CW) $$myfile; \
	  if [ $$? -ne 0 ]; then \
	    err=1; \
	  fi; \
	done; \
	if [ $$err -eq 1 ]; then \
	  echo "ERROR IN BUILT CODE!!!"; \
	  exit 1; \
	else \
	  echo "OK"; \
	fi

run: nodemgmtDialog.pl
	perl ./nodemgmtDialog.pl

debug: nodemgmtDialog.pl
	perl -MQt::debug=calls,gc,ambiguous,verbose ./nodemgmtDialog.pl

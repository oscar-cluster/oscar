DESTDIR=

TOPDIR = ..
include $(TOPDIR)/Config.mk

SUBDIRS := OCA

FILES := AddNode.pm Help.pm Prereqs.pm Bootstrap.pm ImageMgt.pm \
         OpkgDB.pm psm.pm Logger.pm Opkg.pm ClientMgt.pm LSBreleaseParser.pm \
         PxegrubConfigManager.pm CLI_MAC.pm MACops.pm osm.pm pxegrub.pm \
         CmpVersions.pm MAC.pm PackageBest.pm SISBuildSetup.pm Configbox.pm \
         PackageInUn.pm ConfigFile.pm PackagePath.pm SwitcherAPI.pm \
         ConfigManager.pm msm.pm SystemSanity.pm Package.pm Tk.pm \
         Configurator.pm Network.pm PackageSet.pm Utils.pm DelNode.pm \
         NextIp.pm VersionParser.pm Distro.pm NodeConfigManager.pm \
         PackageSmart.pm VMConfigManager.pm Env.pm NodeMgt.pm \
         PartitionConfigManager.pm  WizardEnv.pm FileUtils.pm OCA.pm \
         PartitionMgt.pm GUI_MAC.pm SystemInfo.pm SystemServices.pm \
         SystemServicesDefs.pm Configurator_backend.pm Defs.pm

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/OSCAR
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/OSCAR
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(LIBDIR)/OSCAR; rm -rf ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~

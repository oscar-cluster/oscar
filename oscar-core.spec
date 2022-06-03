# $Id$

#define _unpackaged_files_terminate_build 0

%define opkgc_version 0.6.0
%define packman_version 3.2.0
#define is_suse %(test -f /etc/SuSE-release && echo 1 || echo 0)
%define is_suse %(grep -E "(suse)" /etc/os-release > /dev/null 2>&1 && echo 1 || echo 0)
%define oscar_version %(scripts/get-oscar-version.sh VERSION --base)
%define oscar_release 0.%(scripts/get-oscar-version.sh VERSION --build-r | sed -e 's/[^0-9]//g')

%define pkg_mkisofs mkisofs
%define pkg_ncat nmap
%define pkg_pidof sysvinit-tools

%if 0%{?rhel} == 6
%define web_vhosts_dir %{_sysconfdir}/httpd/conf.d
%endif
%if 0%{?rhel} == 7
%define web_vhosts_dir %{_sysconfdir}/httpd/conf.d
%endif
%%if 0%{?rhel} == 8
%define web_vhosts_dir %{_sysconfdir}/httpd/conf.d
%endif
%if 0%{?fedora} > 26
%define web_vhosts_dir %{_sysconfdir}/httpd/conf.d
%endif
%if %is_suse%{?is_opensuse}
%define web_vhosts_dir %{_sysconfdir}/apache2/vhosts.d
%endif

Summary: 	OSCAR package
Name: 		oscar
Version: 	%oscar_version
Release: 	%oscar_release%{?dist}
License: 	GPL
URL: 		http://oscar.openclustergroup.org
Group: 		Applications/System
Source: 	%{name}-%{version}.tar.gz
Requires: 	lib%{name}-server == %{version}-%{release}
Requires: 	%{name}-core == %{version}-%{release}
Requires:	%{name}-data == %{version}-%{release}
Vendor: 	OSCAR
Distribution: 	OSCAR
Packager: 	Olivier LAHAYE
BuildRequires:	make
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 6
BuildRequires:  perl-generators, perl-interpreter
%endif
%if %{?is_suse}%{?is_opensuse}
BuildRequires:  rpm, perl
%endif
BuildRequires:  perl(Pod::Man)

Buildroot: 	%{_tmppath}/%{name}-%{version}-root
BuildArch: 	noarch
Obsoletes: oscar-base

%description
OSCAR package.
"Virtual" package that installs the basic dependencies to have OSCAR able to
bootstrap using RPMs.

%prep
%setup -n %{name}-%{version}
%__patch -s -p1 share/prereqs/base/prereq.cfg debian/patches/01_base_prereq.patch

%build

%install
%__rm -rf %{buildroot}
%__make install DESTDIR=%{buildroot} DOCDIR=%{_defaultdocdir}
%__mkdir_p %{buildroot}%{_sysconfdir}/oscar
%__mkdir_p %{buildroot}%{_defaultdocdir}/oscar
%__cp -rf CREDITS ChangeLog COPYING README VERSION %{buildroot}%{_defaultdocdir}/oscar/

%clean
%__rm -rf %{_tmppath}/%{name}-%{version}-root

%files
%defattr(-,root,root)

%package -n oscar-core
Group: Applications/System
Summary: Base OSCAR package
Requires(post): %{name}-data == %{version}-%{release}
# Requiring oscar virtual package let uninstal the whole oscar by removing oscar package.
# all other oscar-base-* packages depends on oscar-base.
Requires: lib%{name}-server == %{version}-%{release}
# systeminstaller-oscar is handeled by prereqs, but this needs to be here
# for rpm compliance (shouldn't be possible to install a package with missing deps)
Requires: systeminstaller-oscar
Requires: iproute, syslinux, tftp-server, syslinux-tftpboot
Requires: yume, oda, systemimager-server
Obsoletes: oscar-base-scripts

%description -n oscar-core
Base OSCAR package.
OSCAR allows users, regardless of their experience level with a *nix
environment, to install a Beowulf type high performance computing cluster. It
also contains everything needed to administer and program this type of HPC
cluster. OSCAR's flexible package management system has a rich set of
pre-packaged applications and utilities which means you can get up and running
without laboriously installing and configuring complex cluster administration
and communication packages. It also lets administrators create customized
packages for any kind of distributed application or utility, and to distribute
those packages from an online package repository, either on or off site.

%post -n oscar-core
%{_bindir}/oscar-config --generate-config-file
%{_bindir}/oscar-updater

%files -n oscar-core
%{_bindir}/*
%exclude %{_bindir}/distro-query
%{_mandir}/man1/*
%exclude %{_mandir}/man1/distro-query.*

%package -n oscar-data
Group: Applications/System
Summary: Datafiles for OSCAR clustering package.
Obsoletes: oscar-base

%description -n oscar-data
Datafiles and configuration files for OSCAR Clustering package.

%files -n oscar-data
%defattr(-,root,root)
%{_sysconfdir}/oscar
%{_defaultdocdir}/oscar
%{_prefix}/lib/oscar
%{_datarootdir}/oscar
%exclude %{_datarootdir}/oscar/webgui

%package -n liboscar-server
Group: Applications/System
Summary: Libraries for OSCAR clustering package (server side).
Requires: perl-XML-Simple
Requires: perl-AppConfig
Requires: perl-Tk-TextANSIColor
Requires: wget
Requires: apitest
#Requires: shadow-utils, passwd
#Requires: iproute
Requires: lib%{name}-client == %{version}-%{release}
Requires: %{name}-data == %{version}-%{release}
Obsoletes: oscar-base-lib

%description -n liboscar-server
Libraries for OSCAR clustering base package (server side).

%files -n liboscar-server
%defattr(-,root,root)
%{perl_vendorlib}/*
%exclude %{perl_vendorlib}/OSCAR/Env.pm
%exclude %{perl_vendorlib}/OSCAR/OCA/OS_*
%exclude %{perl_vendorlib}/OSCAR/OCA/PM_*
%exclude %{perl_vendorlib}/OSCAR/OCA/RM_*
%exclude %{perl_vendorlib}/OSCAR/Logger*
%exclude %{perl_vendorlib}/OSCAR/Utils.pm
#exclude %{perl_vendorlib}/OSCAR/osm.pm
#exclude %{perl_vendorlib}/OSCAR/psm.pm

%package -n liboscar-client
Group: Applications/System
Summary: Libraries for OSCAR clustering package (client side).

%description -n liboscar-client
Libraries for OSCAR clustering base package (server side).

%files -n liboscar-client
%defattr(-,root,root)
%{perl_vendorlib}/OSCAR/Env.pm
%{perl_vendorlib}/OSCAR/OCA
%exclude %{perl_vendorlib}/OSCAR/OCA/Sanity*
%{perl_vendorlib}/OSCAR/Logger*
%{perl_vendorlib}/OSCAR/Utils.pm

%package -n oscar-utils
Group: Applications/System
Summary: Utilities for OSCAR clustering package.
Requires: %{name}-core == %{version}-%{release}
Requires: lib%{name}-server == %{version}-%{release}
Requires: syslinux-tftpboot

%description -n oscar-utils
Scripts for OSCAR clustering base package.

%files -n oscar-utils
%defattr(-,root,root)
%{_bindir}/distro-query
%{_mandir}/man1/distro-query.*

%package -n oscar-webgui
Group: Applications/System
Summary: Web GUI for managing OSCAR Cluster.
Requires: %{name}-core == %{version}-%{release}
Requires: httpd, php

%description -n oscar-webgui
Web GUI for managing OSCAR Cluster.

%files -n oscar-webgui
%defattr(0644, root, root, 0755)
#config(noreplace) %{web_vhosts_dir}/oscar.conf
#dir %{_datarootdir}/oscar/webgui

%package -n oscar-devel
Group: Applications/System
Summary: Everything needed for OSCAR related developments
Requires: %{name}-base == %{version}-%{release}
Requires: opkgc >= %{opkgc_version}
Requires: packman >= %{packman_version}
Requires: createrepo

%description -n oscar-devel
Everything needed for OSCAR related developments.

%files -n oscar-devel
%defattr(-,root,root)
%{_sysconfdir}/rpm/macros.oscar
%{_prefix}/lib/oscar/build/Config.mk
%{_mandir}/man3/*

%package -n oscar-release
Summary: OSCAR release file and RPM repository configuration
Group: Applications/System

%description -n oscar-release
OSCAR release file. This package contains apt, yum and smart
configuration for the OSCAR RPM Repository, as well as the public
GPG keys used to sign them.

%files -n oscar-release
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 6
%{_sysconfdir}/yum.repos.d/oscar.repo
%endif
%if %{?is_suse}%{?is_opensuse}
%{_sysconfdir}/yum/repos.d/repo-oscar.repo
%{_sysconfdir}/zypp/repos.d/repo-oscar.repo
%endif
%{_sysconfdir}/apt/sources.list.d/oscar.list
%{_sysconfdir}/smart/channels/oscar.channel
%{_sysconfdir}/sysconfig/rhn/sources.oscar.txt
#{_sysconfdir}/pki/rpm-gpg/*

%changelog
* Fri Jun  3 2022 Olivier Lahaye <olivier.lahaye@cea.fr>
- Major packagin rewrite.
* Fri May 22 2020 Olivier Lahaye <olivier.lahaye@cea.fr>
- Add support for zypper and openSuSE yum. (openSuSE/leap packaging)
* Tue May 19 2020 Olivier Lahaye <olivier.lahaye@cea.fr>
- Add support for specific docdir. (openSuSE/leap packaging)
* Fri Dec 06 2013 Olivier Lahaye <olivier.lahaye@cea.fr>
- Added missing deps on iproute, oscarbase for scripts and so on.
* Tue Dec 03 2013 Olivier Lahaye <olivier.lahaye@cea.fr>
- Fixed packaging for FHS
- Removed define _unpackaged_files_terminate_build 0
  (leads to incomplete packages without notices)
- fixed files or directory listed twice.
* Thu Feb 21 2013 Olivier Lahaye <olivier.lahaye@cea.fr>
- Added oscar-release package (repository setup)
* Mon Jan 28 2013 Olivier Lahaye <olivier.lahaye@cea.fr>
- Fix doc directory (/usr/share/doc/oscar without %{version})
* Sun Dec 09 2012 Geoffroy Vallee <valleegr@ornl.gov>
- Add a dependency to wget since it is not necessarily installed by default on
  some minimal configurations of CentOS 6.
* Wed Nov 14 2012 Olivier Lahaye <olivier.lahaye@cea.fr>
- Add macros.oscar to devel package.
- Full spec file update (use macros instead og hardcoded paths)
* Thu Mar 03 2011 Geoffroy Vallee <valleegr@ornl.gov>
- Add a oscar-devel packages.
* Sat Jan 31 2009 Geoffroy Vallee <valleegr@ornl.gov>
- Merge the oscar.spec.in and oscar-base.spec.in files.
- Re-organize the spec file to start to address issues with FC10.
* Tue Dec 02 2008 Geoffroy Vallee <valleegr@ornl.gov>
- Add the /usr/bin/system-sanity.d directory into the scripts RPM.
* Wed Nov 26 2008 Geoffroy Vallee <valleegr@ornl.gov>
- Modify the spec file to be based on the Makefile.
- Install OSCAR directly into the system, instead of using /opt.
* Thu Nov 29 2007 Bernard Li <bernard@vanhpc.org>
- Added directories to the %files sections so that they will be removed
  when the RPMs are uninstalled
* Thu Oct 4 2007 Erich Focht
- Initial package.

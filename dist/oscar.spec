%define name oscar
%define version 1.4 
%define release 1
%define _prefix /opt/oscar
%define _buildroot %{_tmppath}/%{name}-buildroot
%define _oscarbuildroot %{_buildroot}/opt/%{name}-%{version}
%define _oscarroot /opt/%{name}-%{version}

Summary: OSCAR - Beowulf Clustering Solution
Name: %{name}
Version: %{version}
Release: %{release}
Source0: %{name}-%{version}.tar.gz
Distribution: OSCAR
License: GPL / Freely Distributable
Group: Clustering
BuildRoot: %{_buildroot}
Prefix: %{_prefix}

%description

%prep
%setup -q

%build 
echo %{_buildroot}

%install
pwd
install -d %{_oscarbuildroot}
install -d %{_oscarbuildroot}/share/serverlists
cp share/serverlists/*rpmlist %{_oscarbuildroot}/share/serverlists
install -d %{_oscarbuildroot}/share/clientlists
cp oscarsamples/*rpmlist %{_oscarbuildroot}/share/clientlists
install -d %{_oscarbuildroot}/share/disktables
cp oscarsamples/*disk*  %{_oscarbuildroot}/share/disktables
install -d %{_oscarbuildroot}/lib/OSCAR
cp lib/OSCAR/*pm %{_oscarbuildroot}/lib/OSCAR

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%dir %{_oscarroot}
%{_oscarroot}/share/*
%{_oscarroot}/lib/*

%changelog
* Thu Aug  8 2002 Sean Dague <sean@dague.net> 1.4 -1
- Added first minimal pass at spec file


# end of file

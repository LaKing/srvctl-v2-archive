#!/bin/bash

## This script updates the srvctl version number, and builds an rpm package.
## I assume you cloned srvctl into your home directory

cd ~/srvctl

if [ ! -f "srvctl.sh" ]
then
    echo "Please clone srvctl into your home directory. Stopping for now."
    exit 1
fi

## this is the main file
g='srvctl.sh'

NOW=$(date +%Y.%m.%d-%H:%M:%S)
echo "Updateing $g $NOW"

cat $g > $g.bak

cv=`head -n 3 $g | grep "version" | sed 's/[^0-9.]*//g'`
nv=`echo $cv | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}'`
echo $cv" > "$nv

cat $g > $g.bak

echo "Updateing $g from $cv to $nv $NOW"

echo '#!/bin/bash' > $g
echo '# Last update:'$NOW >> $g
echo '# version '$nv >> $g
tail -n +4 $g.bak >> $g

rm $g.bak

echo "Packaging srvctl $nv"

if [ -z "$(rpmbuild --version 2> /dev/null | grep version)" ]
then
    ## install the fedora packager
    sudo yum -y install @development-tools
    sudo yum -y install fedora-packager
    user=$(whoami)
    sudo usermod -a -G mock $user
fi

## set up an enviroment in the home folder of the user
cd ~
#rm -rf ~/rpmbuild
rpmdev-setuptree

## I assume that the srvctl source is cloned into the home directory
tar -cvzf srvctl-$nv.tar.gz --exclude-vcs srvctl

mv srvctl-$nv.tar.gz ~/rpmbuild/SOURCES/

echo 'Summary: Command line tool to manage Fedora servers and container farms.
Name: srvctl
Version: '$nv'
Release: 1%{?dist}
URL:     http://D250.hu
License: GPLv3
Group: System Environment/Base
BuildRoot: %{_tmppath}/%{name}-%{version}-root
Requires: bash
Source0: srvctl-'$nv'.tar.gz
BuildArch: noarch

%description
Server managment scripts for cpntainers and applications.

%define _unpackaged_files_terminate_build 0

%prep

%setup -n srvctl

%build

%install
rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}%{_datadir}/%{name}
cp -r * ${RPM_BUILD_ROOT}%{_datadir}/%{name}/
rm -rf ${RPM_BUILD_ROOT}%{_datadir}/%{name}/README.md
rm -rf ${RPM_BUILD_ROOT}%{_datadir}/%{name}/LICENSE
rm -rf ${RPM_BUILD_ROOT}%{_datadir}/%{name}/build.sh

%clean
rm -rf ${RPM_BUILD_ROOT}


%files
%{_datadir}/%{name}/*

%attr(755,root,root) %{_datadir}/%{name}/srvctl.sh
%defattr(-,root,root)

%post
ln -sf %{_datadir}/%{name}/srvctl.sh /bin/srvctl
ln -sf %{_datadir}/%{name}/srvctl.sh /bin/sc

%postun
rm -rf %{_datadir}/%{name}
rm -f /bin/srvctl
rm -f /bin/sc


%changelog
* Thu Jan 1 2015 István Király LaKing@D250.hu
- script has been split into several files as of 2.x.

' > ~/rpmbuild/SPECS/srvctl.spec

rpmbuild --bb ~/rpmbuild/SPECS/srvctl.spec

cp ~/rpmbuild/RPMS/noarch/* ~

echo "Done. $g $nv"

## send back to the repo/fork it was cloned from
cd ~/srvctl
echo "git add $nv"
git add . --all
echo "git commit $nv"
git commit -m $nv
echo "git push $nv"
git push 
#-f

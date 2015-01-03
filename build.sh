#!/bin/bash

## this is for debugging 
set -u

## This script updates the srvctl version number, and builds an rpm package.

is_root=false

## IF you are an user or root ...
if (("$UID" < "1000"))
then
    if [ "$UID" -ne "0" ]
    then
        ## I assume that if you run this as a system user, the its srv
        if [ "$(whoami)" -ne "srv" ]
        then
            echo "ERROR - system user $(whoami) is unknown. Use a normal user."
            exit 1
        fi
    else
        if [ -z "$(rpmbuild --version 2> /dev/null | grep version)" ]
        then
            ## install the fedora packager
            yum -y install rpmdevtools
            yum -y install rpm-build
        fi
        echo "WARNING started as root - will use user/folder srv for packaging"
        is_root=true
    fi
else
        echo "OK user $(whoami)"
        if [ -z "$(rpmbuild --version 2> /dev/null | grep version)" ]
        then
            echo "WARNING - rpmbuild not found, attemt to install it with sudo"
            ## install the fedora packager
            sudo yum -y install @development-tools
            sudo yum -y install fedora-packager
            user=$(whoami)
            sudo usermod -a -G mock $user
        fi
        if [ -z "$(rpmbuild --version 2> /dev/null | grep version)" ]
        then
            echo "ERROR - rpmbuild installation failed. Login as root and run:"
            echo "yum -y install @development-tools"
            echo "yum -y install fedora-packager"
            echo "Exiting for now."
            exit
        fi
fi

## I assume you cloned srvctl into your home directory

cd ~/srvctl
if $is_root
then
    cd /srv
else
    cd ~
fi

cd srvctl

if [ ! -f "srvctl.sh" ]
then
    echo "ERROR - Please clone srvctl into your home directory. srvctl.sh not found in $(pwd) - Stopping for now."
    exit 1
fi

## this is the main file
g='srvctl.sh'

NOW=$(date +%Y.%m.%d-%H:%M:%S)

cat $g > $g.bak

cv=`head -n 3 $g | grep "version" | sed 's/[^0-9.]*//g'`
nv=`echo $cv | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}'`

cat $g > $g.bak

echo "Updateing $g from $cv to $nv $NOW"

echo '#!/bin/bash' > $g
echo '# Last update:'$NOW >> $g
echo '# version '$nv >> $g
tail -n +4 $g.bak >> $g

rm $g.bak

echo "GIT action"
## send back to the repo/fork it was cloned from
git config --global push.default simple
#echo "git add $nv"
git add . --all
#echo "git commit $nv"
git commit -m $nv
#echo "git push $nv"
git push 
#-f


echo "Packaging srvctl $nv"

## set up an enviroment in the home folder of the user - or in /srv
cd ..
mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS,tmp}

## I assume that the srvctl source is cloned into the home directory
echo "Compressing tarball"
tar -cvzf srvctl-$nv.tar.gz --exclude-vcs srvctl

echo "Moving from $(pwd)"
mv srvctl-$nv.tar.gz rpmbuild/SOURCES/

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

' > rpmbuild/SPECS/srvctl.spec

if $is_root
then
    chown -R srv:srv /srv/rpmbuild
    su -s /bin/bash -c "rpmbuild --bb /srv/rpmbuild/SPECS/srvctl.spec" srv
else
    rpmbuild --bb rpmbuild/SPECS/srvctl.spec
fi

cp rpmbuild/RPMS/noarch/* ~

echo "Done. $g $nv"

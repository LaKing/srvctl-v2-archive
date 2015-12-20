#!/bin/bash

## constants
ve="CONTAINER"
hs="HOST"

## get project directory - this file should reside in the project root folder
wd="$(dirname $(readlink -f '$0'))"

## INCREMENT VERSION

if ! [ -f "$wd/version" ]
then
    echo 0.0.0 > $wd/version
fi

    ## current version
    cv=`cat $wd/version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}'`
    echo $cv > $wd/version

    echo "VERSION $cv"


if [ "$(whoami)" == codepad ] && [ "$hostname" == "$ve" ]
then
    cd $wd

    git add . --all
    if [ "$?" != "0" ]
    then
        exit 11
    fi
    
    git commit -m codepad-push

    if [ "$?" != "0" ]
    then
        exit 12
    fi
    
    git push
    
    if [ "$?" != "0" ]
    then
        exit 13
    fi
    
    exit 0
    
fi

## check if we are in the proper directory

if [ "$(pwd)" != "$wd" ]
then
    echo "cd $wd"
    cd $wd
fi


## GIT ACTION



if [ "$(hostname)" == "$hs" ]
then
    echo "PUSH from $hs"
    echo git add . --all
    ssh root@$ve "cd /srv/node-project && git add . --all"
    echo git commit -m "$cv $(whoami)@r2.d250.hu"
    ssh root@$ve "cd /srv/node-project && git commit -m '$cv $(whoami)@r2.d250.hu'"
    echo git push
    ssh root@$ve 'cd /srv/node-project && git push && chown -R codepad:srv /srv/node-project'
fi

if [ "$(hostname)" == "$ve" ]
then
    echo "PUSH from $ve"
    echo "git add . --all"
    git add . --all
    echo "git commit -m '$cv root@$ve'"
    git commit -m "$cv root@$ve"
    echo "git push"
    git push
    echo "chown -R codepad:srv /srv/node-project"
    chown -R codepad:srv /srv/node-project
    
fi

if [ "$(hostname)" != "$hs" ] && [ "$(hostname)" != "$ve" ]
then
    echo "PUSH from local"
    git config --global push.default simple
    echo "git add . --all"
    git add . --all
    echo "git commit -m '$cv $(whoami)@$(hostname)'"
    git commit -m "$cv $(whoami)@$(hostname)"
    echo "git push"
    git push
    echo ssh $hs "ssh root@$ve 'cd /srv/node-project && git-pull && chown -R codepad:srv /srv/node-project'"
    ssh $hs "ssh root@$ve 'cd /srv/node-project && git pull && chown -R codepad:srv /srv/node-project'"
fi


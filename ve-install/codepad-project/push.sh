#!/bin/bash

## get project directory - this file should reside in the project root folder
wd=/srv/codepad-project

log=/var/codepad/project.log
pid=/var/codepad/project.pid

chown -R codepad:codepad $wd
chmod -R +X $wd
NOW=$(date +%Y.%m.%d-%H:%M:%S)

if [ ! -z "$(find . -name '*.ts')" ]
then
    if [ ! -f /usr/bin/tsc ]
    then
        if [ $USER == root ]
        then
            npm -g install typescript
        else
            echo "Tyspescript propably needed, but not installed!"
        fi
    fi
fi

## enforce codepad user
if [ $USER != codepad ]
then    
    su codepad -s /bin/bash -c $0
    exit
fi

cd $wd

## INCREMENT VERSION

if ! [ -f "$wd/version" ]
then
    echo 0.0.0 > $wd/version
fi

## current version
cv=`cat $wd/version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}'`
echo $cv > $wd/version
echo "PUSH VERSION $cv of $HOSTNAME:$wd $NOW"
echo "PUSH VERSION $cv of $HOSTNAME:$wd $NOW" > $log


## push to local
if [ -d "$wd/.git" ]
then
    echo "## git push"
    git add -A . >> $log
    git commit -m codepad-auto  >> $log
    git push  >> $log
fi

if [ ! -z "$(find . -name '*.ts')" ]
then
        if [ ! -f $wd/tsconfig.json ]
        then
            tsc --init >> $log
        fi
    ## run the typescript compiler
    tsc >> $log
fi

if [ -f "$wd/server.js" ]
then

    echo "PUSH - RESTARTING server.js" >> $log

    kill $(cat $pid)

    /bin/node $wd/server.js >> $log 2>&1 &
    echo $! > $pid
fi

echo "Ready."


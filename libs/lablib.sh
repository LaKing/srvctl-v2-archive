#!/bin/bash

## Lablib functions

## constants

## MYSQL / MARIADB conf file that stores the mysql root password - in containers
MDF=/etc/mysqldump.conf

## global variables with default values
all_arg_set=false


green='\e[32m'
red='\e[31m'
blue='\e[34m'
yellow='\e[33m'

NC='\e[0m' # No Color

function bak {
    ## create a backup of the file, with the same name, same location .bak extension
    ## filename=$1
if [ -f $1 ]
then        
    echo $MSG" (bak)" >> $1.bak
    cat $1 >> $1.bak
    #echo $1" has a .bak file"
fi
}

function new_file {
    ## cerate a new file if it does not exists
    ## filename=$1 content=$2

    if ! [ -f $1 ];
    then
      #echo "creating "$1
      echo "$2" > $1
    fi
}

function set_file {
    ## cerate a file with the content overwriting everything
    ## filename=$1 content=$2

    if [ -f $1 ];
     then bak $1
    fi
    #echo "creating "$1
    echo "$2" > $1
}

function sed_file {
    ## used to replace a line in a file
    ## filename=$1 oldline=$2 newline=$3
    bak $1
    cat $1 > $1.tmp
    sed "s|$2|$3|" $1.tmp > $1
    rm $1.tmp
}

function add_conf {
    ## check if the content string is present, and add if necessery. Single-line content only.
    ## filename=$1 content=$2
    if [ -f "$1" ]
    then
        if ! grep -q "$2" $1
        then
            bak $1
            echo "$2" >> $1
        fi
    else 
        echo "File not found! $1"
    fi
}

function msg {
    ## message for the user
    echo -e ${green}$@${NC}
}

function ntc {
    ## notice for the user
    echo -e ${yellow}$@${NC}
}


function log {
    ## create a log entry
    echo -e ${yellow}$1${NC}
    echo $NOW': '$@ >> $LOG
}

## silent log
function logs {
    ## create a log entry
    echo $NOW': '$@ >> $LOG
}

function dbg {
    ## debug message
        if $debug
        then
            echo -e ${yellow}'#'$BASH_LINENO' '${FUNCNAME[1]}': '$@${NC}
            echo $NOW': '$@ >> $LOG
        fi
}

function err {
    ## error message
    echo -e ${red}$@${NC}
    echo $NOW': '$@ >> $LOG
    SUCC=$SUCC" "$@
}

function is_fqdn() {
    ## check if argument is a FQDN - fully qualified domain name
    local fqdn_test=$(echo $1 | grep -P '(?=^.{6,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')
    # '
            if [ -z "$fqdn_test" ]
            then
              return 1
            else
              return 0
            fi
}

## exit if failed
function exif {
    if [ "$?" != "0" ]
    then 
        err "Error."
        exit 1;
    fi
}

## choose a package manager based on relese
function pm {
        echo dnf -y install $@
        dnf -y install $@
        exif
}

function pm_update {
        echo dnf -y update
        dnf -y update
        exif
}

function pm_groupinstall {
        echo dnf -y groupinstall $@
        dnf -y groupinstall $@
        exif
}



## Lablib functions end here.


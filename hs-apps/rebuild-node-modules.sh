#!/bin/bash

function process_require {
    
    local _p=$2
    
    if [ $_p == assert ]; then return; fi
    if [ $_p == buffer ]; then return; fi
    if [ $_p == child_process ]; then return; fi
    if [ $_p == cluster ]; then return; fi
    if [ $_p == console ]; then return; fi
    if [ $_p == constants ]; then return; fi
    if [ $_p == crypto ]; then return; fi
    if [ $_p == dgram ]; then return; fi
    if [ $_p == dns ]; then return; fi
    if [ $_p == domain ]; then return; fi
    if [ $_p == events ]; then return; fi
    if [ $_p == fs ]; then return; fi
    if [ $_p == http ]; then return; fi
    if [ $_p == https ]; then return; fi
    if [ $_p == module ]; then return; fi
    if [ $_p == net ]; then return; fi
    if [ $_p == os ]; then return; fi
    if [ $_p == path ]; then return; fi
    if [ $_p == process ]; then return; fi
    if [ $_p == punycode ]; then return; fi
    if [ $_p == querystring ]; then return; fi
    if [ $_p == readline ]; then return; fi
    if [ $_p == repl ]; then return; fi
    if [ $_p == stream ]; then return; fi
    if [ $_p == string_decoder ]; then return; fi
    if [ $_p == timers ]; then return; fi
    if [ $_p == tls ]; then return; fi
    if [ $_p == tty ]; then return; fi
    if [ $_p == url ]; then return; fi
    if [ $_p == util ]; then return; fi
    if [ $_p == v8 ]; then return; fi
    if [ $_p == vm ]; then return; fi
    if [ $_p == zlib ]; then return; fi            
    
    echo "npm install $_p"

     npm install $_p

}

function process_directory {
    
    DIR=$1

    echo "working in $DIR"

    if [ ! -d "$DIR/node_modules" ]
    then
        echo "No node modules."
    else
        echo "Deleting npm packages."
        rm -fr $DIR/node_modules/*
    fi



    for e in $(cat $DIR/*.js | grep require)
    do
        if [ "${e:0:7}" == require ]
        then
            process_require $(echo "$e" | tr "'" " " | tr "(" " " | tr ")" " " | tr '"' ' ' | tr ';' ' ')
        fi
    done
 
}

echo "Nodejs npm regenerator."

    if [ -z "$1" ]
    then
        echo "No argument given, processing current directory."
       
        DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        ## "
        
        process_directory "$DIR"
    fi


echo "ready..."


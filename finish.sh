#!/bin/bash

## hint provides a sort of help functionality
function hint {
 if [ ! -z "$1" ]
  then
        ## print formatted hint
        printf ${green}"%-40s"${NC} "  $1" 
        printf ${yellow}"%-48s"${NC} "$2"
        ## newline
        echo ''
 fi
} 

### thats it. Display help or succes info.
if [ -z "$SUCC" ]
then

     ## check for arguments
  if [ -z "$CMD" ]
  then
        printf ${red}"No Command."${NC} 
        echo ''
    else 
        ##COMMENTED OUT - i think this should be deprecated
        ## check for the default command       
        #if [ "$CMD" == "$(/bin/srvctl ls | grep $CMD)" ]
        #then
        #    /bin/srvctl exec $ARGS
        #    exit 76
        #fi
  
        printf ${red}"Invalid Command."${NC} 
        echo ''
 fi
 
  msg "Usage: srvctl command [argument]"
  msg "list of currently active commands:" 


        hint_commands
        ## print formatted hint about man
        printf ${green}"%-40s"${NC} "  help" 
        printf ${yellow}"%-48s"${NC} "see more detailed descriptions about commands."
        ## newline
        echo ''
        echo ''
        
        if $isROOT && $onVE
        then
            msg "CMS list:"         
            hint_cms
            echo ''
        fi
        
else
 echo -e "$SUCC"
fi

## return to the directory we started from.
cd $CWD >> /dev/null 2> /dev/null



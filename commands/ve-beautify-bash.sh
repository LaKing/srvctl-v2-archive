#!/bin/bash
if [ -f /bin/shellcheck ] && [ -f /bin/python ]
then

        hint "beautify-bash [DIR]" "Syntax check and beautify bash."
        if [ "$CMD" == "beautify-bash" ]
        then
        
                PROJECT="$CWD"
       
                if [ ! -z "$ARG" ]
                then
                    if ! [ -d "$ARG" ]
                    then
                        err "Argument must be a directory."
                        exit
                    else    
                        PROJECT="$ARG"
                    fi
                fi
                
                find "$PROJECT" > /tmp/srvctl-bash-beautify
 
                while read file 
                do

                    if [[ "${file:0, -3 }" == ".sh" ]]
                    then
                        msg "bash-beautify $file"
                        
                        shellcheck "$file"
                        /bin/python $install_dir/apps/beautify_bash.py "$file"
                    fi

                done < /tmp/srvctl-bash-beautify
       
                        
        ok
        fi ## add-cms

fi

man '
    Use ShellChek and beautiy-bash to syntax check your bash project tree and to format.
    https://github.com/koalaman/shellcheck
    https://github.com/ewiger/beautify_bash   
'



        msg "User tools"
        if [ -z "$(type -a vncserver | grep 'vncserver is ')" ]
        then
            pm tigervnc-server
        fi
        
        if [ -z "$(type -a hg | grep 'hg is ')" ]
        then       
            pm mercurial
        fi
        
        if [ -z "$(type -a fdupes | grep 'fdupes is ')" ]
        then
            pm fdupes
        fi
        
        if [ -z "$(type -a mail | grep 'mail is ')" ]
        then
            pm mailx
        fi




        msg "User tools"
        if [ -z "$(type -a vncserver | grep 'vncserver is ')" ]
        then
            pm install tigervnc-server
        fi
        
        if [ -z "$(type -a hg | grep 'hg is ')" ]
        then       
            pm install mercurial
        fi
        
        if [ -z "$(type -a git | grep 'git is ')" ]
        then
            pm install git
        fi
        
        if [ -z "$(type -a fdupes | grep 'fdupes is ')" ]
        then
            pm install fdupes
        fi


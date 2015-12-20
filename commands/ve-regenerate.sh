if $onVE && $isROOT
then ## no identation.

## regenerate configs 
hint "regenerate" "Restore permissions on important files and folders."
if [ "$CMD" == "regenerate" ] || [ "$CMD" == "!" ]
then
    
    ## home folders
    for u in $(ls /home)
    do
        echo "chown -R $u:$u /home/$u"
        chown -R $u:$u /home/$u
    done
    
    #echo "chown -R root:root /root"
    #chown -R root:root /root
    
    echo "chown -R apache:apache /var/www/html"
    chown -R apache:apache /var/www/html
    echo "chown -R git:git /var/git"
    chown -R git:git /var/git
    
    echo "chown -R srv:srv /srv"
    chown -R srv:srv /srv
    if [ -d /srv/node-project ]
    then
        echo "chown -R codepad:srv /srv/node-project"
        chown -R codepad:srv /srv/node-project
    fi  
ok
fi ## regenerate

man '
    Set ownership, and mode on files and folders, as good as possible.
'

fi


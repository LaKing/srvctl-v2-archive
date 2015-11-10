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
    
    echo "chown -R apache:apache /var/www/html"
    chown -R apache:apache /var/www/html
    echo "chown -R srv:srv /srv"
    chown -R srv:srv /srv
    echo "chown -R root:root /root"
    chown -R root:root /root
         
ok
fi ## regenerate

man '
    Set ownership, and mode on files and folders, as good as possible.
'

fi


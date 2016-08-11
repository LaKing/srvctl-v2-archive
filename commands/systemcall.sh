if $isROOT
then

    if [ "$CMD" == 'create_ca_certificate' ] && [ "$ROOTCA_HOST" == "$HOSTNAME" ]
    then
        create_ca_certificate $OPAS
        
        ok
    fi 

fi


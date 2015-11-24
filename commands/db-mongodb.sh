## mongodb setup by m1r0 hello@hisi.hr

if $onVE && $isROOT
then ## no identation.

        hint "setup-mongodb" "MongoDB installation! "
        if [ "$CMD" == "setup-mongodb" ]
        then
            install_mongodb
        ok
        fi ## do something

fi

man '
        Setup MongoDB repository and install latest version!
'



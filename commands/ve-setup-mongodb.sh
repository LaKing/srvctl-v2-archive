## mongodb setup by m1r0 hello@hisi.hr

if $onVE && $isROOT
then ## no identation.

        hint "setup-mongodb" "MongoDB installation! "
        if [ "$CMD" == "setup-mongodb" ]
        then
            msg "MongoDB - setup repository and install latest version!"

                dnf config-manager --add-repo https://repo.mongodb.org/yum/redhat/7/mongodb-org/3.0/x86_64/ 
                dnf -y update
                dnf -y install mongodb-org --nogpgcheck        

                msg "MongoDB - setup system services!"

                #Start-Up MongoDB

                systemctl start mongod

                #Check MongoDB Service Status

                systemctl status mongod

                #Start the MongoDB Service at Boot

                systemctl enable mongod


            msg "MongoDB - setup complete!"

        ok
        fi ## do something

fi

man '
        Setup MongoDB repository and install latest version!
'


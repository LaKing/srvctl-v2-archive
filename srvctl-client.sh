
#!/bin/bash
## install as follows:

## curl https://raw.githubusercontent.com/LaKing/srvctl/master/srvctl-client.sh > srvctl-client.sh && chmod +x srvctl-client.sh && bash srvctl-client.sh

## This script should be ...
## - running on any Linux distribution
## - running on OsX
## - running on windows git bash - http://msysgit.github.io/ 

## This script will help to
## - connect to containers
## - map ports to localhost
## - backup databases 
## - upload, download, sync files 
## - clone git repos

## argument is a hostname (VE name)

## If user is root or runs on root privileges, continiue. (TODO: userspace implementation)
if [ "$UID" == "0" ]
then
  echo "Running the client script as root is not recommended. exiting." 
  exit
fi

## lets start ... 
CWD=$(pwd)

cd ~

CWF="srvctl-client"

## source or set here as default
U=$(whoami)
H="localhost"
A=true
I=true



if [ -f $CWF.conf ]
then
        source $CWF.conf
else

    read -r -p "Connection hostname: " H
    
    ##H=$(echo $H | grep -P '(?=^.{6,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')
    ## FGDN hostname check ' - doesent work on wind

    if [ -z "$H" ]
    then
        echo "Invalid hostname"
        exit
    fi

    echo "Current system username: $U"
    read -r -p "Connection username: " -i "$U" U


    if [ -z "$U" ]
    then
        U=$(whoami)
    fi
    echo "Using $U@$H"

    echo -n "Use interactive mode by default? "
    read -s -r -p "[y/N] " -n 1 -i "y" key
    if [[ $key == y ]]; then
        key="yes"
        I=true
    else
        key="no";
        I=false
    fi
    echo $key

        ## TODO add line-break for windos
        echo '## U - user, H - host, A - auto-update, I - interactive ' > $CWF.conf
        echo $'\n' >> $CWF.conf
        echo 'U='$U >> $CWF.conf
        echo $'\n' >> $CWF.conf
        echo 'H='$H >> $CWF.conf
        echo $'\n' >> $CWF.conf
        echo 'A='$A >> $CWF.conf
        echo $'\n' >> $CWF.conf
        echo 'I='$I >> $CWF.conf
        echo $'\n' >> $CWF.conf
fi

if ! [ -z "$1" ]
then
    I=false
fi

echo "USERNAME: $U"
echo "HOSTNAME: $H"

if [ "$H" == "localhost" ]
then
    echo "Please set a valid hostname in $(pwd)/$CWF.conf"
    exit
fi

## test if git is available
curl_avail=false
test_client=$(curl --version 2> /dev/null)
if ! [ -z "$test_client" ]
then
        curl_avail=true

        ## auto update
        if $A
        then

                ## Update this script if possible
                echo "AUTO-UPDATE"
                url_response=$(curl --write-out %{http_code} --silent --output $CWF-latest.sh https://raw.githubusercontent.com/LaKing/srvctl/master/$CWF.sh)
                if ! [ "$url_response" == "200" ]
                then
                        echo "Failed to download latest version of this script."
                else
                        if  diff  $CWF-latest.sh $0 2> /dev/null 1> /dev/null
                        then
                                echo "This is the latest release of the script"
                        else
                            ## default for non-interactive + auto-update
                            key="yes"
                            
                            if $I
                            then
                                echo "Script has been modified, or is not the latest version."
                                echo -n "Do you wish to update and run the latest release of this script? "
                                read -s -r -p "[y/N] " -n 1 -i "y" key
                                if [[ $key == y ]]; then
                                        key="yes"
                                else
                                        key="no";
                                fi
                                echo $key
                            fi
                            
                                if [[ $key == y* ]]
                                then
                                        echo "Switching to latest version."
                                        #cat $CWF-latest.sh > $CWF.sh
                                        #rm -rf $CWF-latest.sh
                                        bash $CWF-latest.sh
                                        exit
                                    fi
                        fi
                fi
        fi
fi
echo "OK - STARTED"


NOW=$(date +%Y.%m.%d-%H:%M:%S)

## create keypair if necessery
if [ -f ~/.ssh/id_rsa ] 
then
        echo "OK - ID rsa exists."
else
        echo  "NO ID rsa, create key as $USER@$HOSTNAME ..."
        mkdir -p ~/.ssh
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N '' -C "$USER@$HOSTNAME $NOW $U@$H"
fi

## check for existence of id_rsa
if [ -f ~/.ssh/id_rsa.pub ]
then
        echo "OK - public key exists."
        cat ~/.ssh/id_rsa.pub > ~/$U.pub
else
        echo "ERR. No public key! Exiting."
        exit
fi

## add host-key to known_hosts
hostkey=$(ssh-keyscan -t rsa -H $H 2> /dev/null)
touch ~/.ssh/known_hosts

if [ -z "$hostkey" ]
then
        echo "ERR. Connection to $H failed."
        exit
fi

if grep -q "${hostkey:68}" ~/.ssh/known_hosts
then
        echo "OK - Host $H is known."
else
        echo "Saving host-key."
        echo $hostkey >> ~/.ssh/known_hosts
fi

## test connectivity
ssh -q $U@$H exit
if [ "$?" == 255 ] 
then
        echo "ERR. failed to connect. $U@$H"
        echo "A public key is needed for $H. Your public key is:"
        echo ""
        cat ~/.ssh/id_rsa.pub
        echo ""
        echo "Copy the public key above or attach it from $(pwd)/$U.pub"
        echo "Email it to webmaster@$H"
        echo "NOTE for windows users: On the top header of the git-bash window is a context menu with right click."
        exit
else
        echo "OK - SSH connected."
fi

## Create client local folder 
if [ -d ~/$H ]
then
        echo "OK - Local $(pwd)/$H folder exists."
else
        echo "Createing local ~/$H folder."
        mkdir -p ~/$H
fi

## from here, use git or rsync
if $I
then

    ## test if rsync is available
    rsync_avail=false
    test_client=$(rsync --version 2> /dev/null)
    if [ ! -z "$test_client" ]
    then
        ## this is not really necessery, but we should do it right.
        test_server=$(ssh -q $U@$H "rsync --version 2> /dev/null")
        if [ ! -z "$test_server" ]
        then
                echo "OK - Method rsync available."
                rsync_avail=true
        fi
    fi

    ## test if git is available
    git_avail=false
    test_client=$(git --version 2> /dev/null)
    if [ ! -z "$test_client" ]
    then
        ## this is not really necessery, but we should do it right.
        test_server=$(ssh -q $U@$H "git --version 2> /dev/null")
        if [ ! -z "$test_server" ]
        then
                echo "OK - Method git available."
                git_avail=true
        fi
    fi
fi


echo "--- VE list for $U@$H ---"


function process_folder {
        #echo -e " --- "$F

        has_git=false
        options='Skip'

        ## is remote dir empty?
        has_remote_files=false
        if ! [ -z "$(ssh -q $U@$H 'ls /home/'$U'/'$D'/'$F' 2> /dev/null')" ]
        then
                has_remote_files=true
                options=$options" Download"
        #else
        #        echo 'Empty remote directory.'
        fi

        ## has non-empty local folder?
        has_local_files=false

        if ! [ -z "$(ls ~/$H/$D/$F 2> /dev/null)" ]
        then
                has_local_files=true        
                options=$options" Upload"
        #else 
        #        echo 'Empty local directory.'
        fi



        if $rsync_avail && $has_remote_files || $has_local_files
        then
                options=$options" | rsync:"

                if $has_remote_files 
                then
                        options=$options" Remote-to-local"
                fi
                if $has_local_files
                then
                        options=$options" Local-to-remote"
                fi
        fi

        if $git_avail && [ "$F" == "git" ]
        then 

                # check for remote bare repository
                git_status=$(ssh -q $U@$H 'cat /home/'$U'/'$D'/'$F'/description 2> /dev/null') 
                options=$options" | git: "

                if [ ! -z "$git_status" ]
                then
                        ## echo "HAS GIT repo"
                        has_git=true
                        options="Skip | git: "

                        if [ ! -d ~/$H/$D/$F/.git ]
                        then
                                options=$options"Clone"                        
                        else
                                options=$options"Pull/Commit+push"
                        fi

                        options=$options" "${git_status:0:20}
                else
                        options=$options"Init"
                fi
        fi

        


        read -s -r -p " - $D/$F [$options] " -n 1 key
        echo '... '$key        

        if [ ! -z "$key" ]
        then
                ## output each command for user tracking - with ## ...

                ## ssh/scp download
                ## should be available everywhere, so if not a git repo ...
                if ! $has_git
                then
                        if [ "$key" == d ] || [ "$key" == D ] && $has_remote_files
                        then

                                echo "##  scp -r -C $U@$H:$D/$F ~/$H/$D"
                                scp -r -C $U@$H:$D/$F ~/$H/$D
                                echo '... ready'
                        fi

                        if [ "$key" == u ] || [ "$key" == U ] && $has_local_files
                        then
                                echo "##  scp -r -C ~/$H/$D/$F $U@$H:~/$D"
                                scp -r -C ~/$H/$D/$F $U@$H:~/$D
                                echo '... ready'
                        fi
                fi


                if $rsync_avail && ! $has_git
                then
                        if [ "$key" == r ] || [ "$key" == R ] && $has_remote_files
                        then
                                echo "## rsync --delete -chavzP --stats $U@$H:$D/$F ~/$H/$D"
                                    rsync --delete -chavzP --stats $U@$H:$D/$F ~/$H/$D
                                echo '... ready'
                        fi

                        if [ "$key" == l ] || [ "$key" == L ] && $has_local_files
                        then
                                echo "## rsync --delete -chavzP --stats ~/$H/$D/$F $U@$H:~/$D"
                                    rsync --delete -chavzP --stats ~/$H/$D/$F $U@$H:~/$D
                                echo '... ready'
                        fi
                fi


                if $git_avail && ! $has_git
                then
                        if [ "$key" == i ] || [ "$key" == I ]
                        then
                                ## Init
                                echo "## ssh -q $U@$H 'cd /home/'$U'/'$D'/'$F'/ && git init --bare && echo project-'$D' > description'"
                                ssh -q $U@$H 'cd /home/'$U'/'$D'/'$F'/ && git init --bare && echo project-'$D' > description' 

                                echo "## mkdir -p ~/$H/$D/$F"
                                mkdir -p ~/$H/$D/$F

                                echo "## git clone $U@$H:$D/$F ~/$H/$D/$F"
                                git clone $U@$H:$D/$F ~/$H/$D/$F

                                echo '... ready'
                        fi                
                fi

                if $git_avail && $has_git
                then
                        if [ "$key" == c ] || [ "$key" == C ]
                        then
                                if [ -d ~/$H/$D/$F/.git ]
                                then
                                        ## Commit & push
                                        echo "## cd  ~/$H/$D/$F"
                                        cd  ~/$H/$D/$F

                                        echo "## git add . --all"
                                        git add . --all

                                        echo "## git commit -a -m $U@$H"
                                        git commit -a -m $U@$H

                                        echo "## git push"
                                        git push

                                        echo '... ready'
  
                                else
                                        ## Clone
                                        echo "## mkdir -p ~/$H/$D/$F"
                                        mkdir -p ~/$H/$D/$F

                                        echo "## git clone $U@$H:$D/$F ~/$H/$D/$F"
                                        git clone $U@$H:$D/$F ~/$H/$D/$F

                                        echo '... ready'
                                fi
                        fi

                        if [ "$key" == p ] || [ "$key" == P ]
                        then
                                if [ -d ~/$H/$D/$F/.git ]
                                then
                                        ## Pull
                                        echo "## cd ~/$H/$D/$F"                        
                                        echo "## git pull"

                                        cd ~/$H/$D/$F                        
                                        git pull

                                        echo '... ready'
                                fi
                        fi
        
                fi

        fi
}


sshconnect=""

#ssh -q $U@$H cat /etc/hosts

## disconnect all tunnels
#echo "SSH - disconnecting all tunnels!"
#kill $(ps ax | grep "ssh " | grep " -L " | grep "$U@$H" | cut -f 1 -d " ")

Dc=0

## list domains on server
for D in $(ssh -q $U@$H "ls -d *.*/" )
do
    D="${D%?}"

    options=" Que | Skip "
    echo ""
    Dc=$((Dc+1))
    sshlocalport=$((22000+$Dc))



    if ! [ -z "$1" ]
    then
        if [ "$D" == "$1" ]
        then
            sshconnect=$sshlocalport
        else
            continue
        fi
    fi

    echo $D

    testaux=$(ps ax | grep "ssh " | grep " -L " | grep "$U@$H" | grep "$sshlocalport:$D:22" | cut -f 1 -d " ")

    if [ -z "$testaux" ]
    then
        killaux=$(ps ax | grep "ssh " | grep " -L " | grep "$U@$H" | grep "$sshlocalport:" | cut -f 1 -d " ")
        if ! [ -z "$killaux" ]
        then
            echo "SSH - Closing tunnel on $sshlocalport"
            kill $killaux
        fi

        echo "SSH - $D = localhost:$sshlocalport"
        ssh -C -L $sshlocalport:$D:22 -N -f $U@$H
    fi
    
    if [ "$(ssh -p $sshlocalport root@localhost hostname)" == "$D" ]
    then
        echo "\$ ssh -p $sshlocalport root@localhost"
        options=" Connect |$options"
    else
        echo "Connection test failed. VE not running?"
    fi

    key="s"

    if $I
    then
        read -s -r -p "$D [$options] " -n 1 key
        echo '... '$key        

        if [ "$key" == c ] || [ "$key" == C ]
        then
           echo "SSH - connecting to root@$D"
           ssh -p $sshlocalport root@localhost "srvctl client-noop"
           ssh -p $sshlocalport root@localhost 
           exit
        fi


        ## que questions
        if [ "$key" == q ] || [ "$key" == Q ]
        then

                url_response=''
                if $curl_avail
                then
                        url_response=$(curl --write-out %{http_code} --silent --output /dev/null http://$D )
                fi

                echo "-- "$D" "$url_response
                mkdir -p ~/$H/$D

                has_db=$(ssh -q $U@$H "ssh root@$D 'systemctl is-active mariadb.service'")
                if [ "$has_db" == "active" ]
                then
                        read -s -r -p " - $D [Backup database] " -n 1 key
                        echo '... '$key        

                        if [ "$key" == "b" ] || [ "$key" == "B" ]
                        then
                                ssh -q $U@$H "ssh root@$D 'srvctl backup-db'"
                        fi
                fi



                for F in $(ssh -q $U@$H ls $D)
                do
                        process_folder
                done
        fi
    fi

done

if ! [ -z "$1" ]
then
echo "SSH-connect root@$1 $sshconnect"
           ssh -p $sshconnect root@localhost "srvctl client-noop"
           ssh -p $sshconnect root@localhost 
fi

echo ""
cd $CWD
echo "OK - Done."
exit



function install_nodejs_getver {
    
    ## we will update this variable
    nodejs_ver='6.3.0-1'
    
    ## get the listing
    
    local _nodesource='https://rpm.nodesource.com/pub_6.x/fc'
    
    curl -s $_nodesource/$VERSION_ID/$ARCH/ | grep 'href="nodejs-' > /tmp/nodeversion
    
    if [ "$?" == "0" ]
    then

        ## local variables we use
        local _checkcount=0
        local _checknum=0
        local _check=''

        ## process 
        while read line
        do
            echo $line
            
            if ! [[ "${line:16:1}" == "d" ]]
            then
                ## substract the version from that listing
                _check=${line:16:7}
                _checknum=$(echo $_check | tr '.' '0' | tr '-' '0' )

                
                if [ "$_checknum" -gt "$_checkcount" ]
                then
                ## update version number, as it seems to be the highest so far
                    _checkcount=$_checknum
                    nodejs_ver=$_check
                fi
            fi

        done < /tmp/nodeversion
        msg "latest node version is $nodejs_ver according to nodesource"
    else
         msg "latest node version known is $nodejs_ver"
    fi
    
    nodejs_rpm_url=$_nodesource'/'$VERSION_ID'/'$ARCH'/nodejs-'$nodejs_ver'nodesource.fc'$VERSION_ID'.'$ARCH'.rpm'
   
}

function install_nodejs_latest {

    install_nodejs_getver

    node_ver=0

    if [ -f /bin/node ]
    then
        node_ver=$(/bin/node --version)
    fi

    ## check if we have the latest version
    if [ "$node_ver" != "v${nodejs_ver:0:-2}" ]
    then
        if [ -f /bin/node ]
        then
            dnf -y remove nodejs 
            dnf -y remove npm
        fi
        
        echo "dnf -y install $nodejs_rpm_url"
        dnf -y install $nodejs_rpm_url
        
        if [ "$?" !== '0' ]
        then
            err "nodejs installation failed!"
        fi
    fi
}


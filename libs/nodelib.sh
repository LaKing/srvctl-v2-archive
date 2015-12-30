function install_nodejs_latest {

## get the listing
curl -s https://rpm.nodesource.com/pub_5.x/fc/$VERSION_ID/$ARCH/ | grep 'href="nodejs-' > /tmp/nodeversion

## we will update this variable
nodejs_ver=''

## local variables we use
_checkcount=0
_checknum=0
_check=''

## process 
while read line
do
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
    rpm_url='https://rpm.nodesource.com/pub_5.x/fc/'$VERSION_ID'/'$ARCH'/nodejs-'$nodejs_ver'nodesource.fc'$VERSION_ID'.'$ARCH'.rpm'
    echo "dnf -y install $rpm_url"
    dnf -y install $rpm_url
fi


}


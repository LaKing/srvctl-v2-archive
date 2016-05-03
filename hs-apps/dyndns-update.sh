#!/bin/bash

## argument host
D=$1

IP=$(cat /var/dyndns/$D.ip)
    
if [ -f /var/dyndns/$D.lock ]
then
    LIP=$(cat /var/dyndns/$D.lock)
    if [ "$IP" == "$LIP" ]
    then
        echo "Nothing to do."
        exit
    fi
fi
    
if [ ${IP:0:7} == '::ffff:' ]
then

    ip=${IP:7}
    update=/var/dyndns/$D.updt
    
    echo "nsupdate $D to $ip on $HOSTNAME"

    echo "server localhost" > $update
    echo "debug yes" >> $update
    echo "update delete $D A" >> $update 
    echo "update delete $D MX" >> $update
    echo "update delete $D AAAA" >> $update
    echo "update add $D 60 A $ip" >> $update
    echo "send" >> $update
    
    nsupdate -k /var/dyndns/srvctl-include-key.conf -v $update

    echo -n $IP > /var/dyndns/$D.lock
else
    echo "Dyndns is not implemented for IPV6 yet"
fi




#!/bin/bash


## srvctl functions

function argument {

        if [ -z "$ARG" ]
        then
                    if [ "$1" == "C" ] || [ "$1" == "_C" ] || [ "$1" == "_c" ]
                then
                  err "No container-name supplied .."
                  exit
                fi

                    if [ "$1" == "U" ] || [ "$1" == "_U" ] || [ "$1" == "_u" ]
                then
                  err "No username supplied .."
                  exit
                fi

                err "No $1 supplied .."
                    exit
        fi

        ## this might need further tests or investigation.
        ## TODO check if this is waterproof
        
        ## lowercase _var=${var,,}
        eval $1=${ARG,,}

}

function to_ip {

        local __counter=$1
        local __c=$(( 1 + $__counter / 250 ))
        local __d=$(( 1 + $__counter % 250 ))

        ## return
        echo $__c"."$__d
}

function to_mac {

        local __counter=$1
        local __c=$(( 1 + $__counter / 250 ))
        local __d=$(( 1 + $__counter % 250 ))

        ## return
        echo $(printf '%x\n'  $__c)":"$(printf '%x\n'  $__d)
}





function create_certificate { ## for container $C

        ## Prepare self-signed Certificate creation

        cert_path=$SRV/$C/cert



        if ! [ -z "$1" ]
        then
                cert_path=$1
                C=$(hostname)
        fi

        ssl_days=1085
        ssl_random=$cert_path/random.txt
        ssl_config=$cert_path/$C.txt
        ssl_key=$cert_path/$C.key
        ssl_org=$cert_path/$C.key.org
        ssl_crt=$cert_path/$C.crt
        ssl_csr=$cert_path/$C.csr
        ssl_pem=$cert_path/$C.pem

        msg "Create certificate for $C."

        mkdir -p $cert_path

        ## TODO generate a self signed wildcard certificate!

        set_file $ssl_config "       RANDFILE               = $ssl_random

        [ req ]
        default_bits           = 2048
        default_keyfile        = keyfile.pem
        distinguished_name     = req_distinguished_name
        attributes             = req_attributes
        prompt                 = no
        output_password        = $ssl_password

        [ req_distinguished_name ]
        C                      = $CCC
        ST                     = $CCST
        L                      = $CCL
        O                      = $CMP
        OU                     = $CMP CA
        CN                     = $C
        emailAddress           = webmaster@$C

         [ req_attributes ]
        challengePassword              = A challenge password"

        #### create certificate for https ### good howto: http://www.akadia.com/services/ssh_test_certificate.html        

        ## Step 1: Generate a Private Key
        openssl genrsa -des3 -passout pass:$ssl_password -out $ssl_key 2048

        ## Step 2: Generate a CSR (Certificate Signing Request)
        openssl req -new -passin pass:$ssl_password -passout pass:$ssl_password -key $ssl_key -out $ssl_csr -days $ssl_days -config $ssl_config
        
        ## Step 3: Remove Passphrase from Key
        cp $ssl_key $ssl_org
        openssl rsa -passin pass:$ssl_password -in $ssl_org -out $ssl_key        
        
        ## Step 4: Generating a Self-Signed Certificate
        ## later on, use signed certificates, eg. verisign, startssl or netlock.hu
        ## To use your own CA openssl ca -batch -out $ssl_crt -config /etc/pki/[YOU_AS_CA]/openssl.cnf -passin pass:[YOU_AS_CA_PASS] -in $ssl_csr
        ## We will generate now a self-signed certificate
        openssl x509 -req -days $ssl_days -passin pass:$ssl_password  -in $ssl_csr -signkey $ssl_key -out $ssl_crt

        ## create a certificate keychain in pem format
        cat $ssl_key >  $ssl_pem
        cat $ssl_crt >> $ssl_pem


        if [ "$1" == "/root" ]
        then
                cat $ssl_key >  /root/key.pem
                cat $ssl_crt >  /root/crt.pem
        fi
}




function create_keypair { ## for user $U

        mkdir /home/$U/.ssh

        ## create ssh keypair
        if [ ! -f /home/$U/.ssh/id_rsa.pub ]; then
           ssh-keygen -t rsa -b 4096 -f /home/$U/.ssh/id_rsa -N '' -C $U@@$(hostname)
        fi

        chown -R $U:$U /home/$U/.ssh
        chmod -R 600 /home/$U/.ssh
        chmod    700 /home/$U/.ssh
}

function get_password {

        ## TODO make hash based password eventually? ...

        ## You may want to add your own sillyables, or faorite characters and customy security measures.
        declare -a pwarra=("B" "C" "D" "F" "G" "H" "J" "K" "L" "M" "N" "P" "R" "S" "T" "V" "Z")
        pwla=${#pwarra[@]}

        declare -a pwarrb=("a" "e" "i" "o" "u")
        pwlb=${#pwarrb[@]}        

        declare -a pwarrc=("" "." ":" "@" ".." "::" '@@')
        pwlc=${#pwarrc[@]}

        p=''
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        # p=$p${pwarrc[$(( RANDOM % $pwlc ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}

        ## return passowrd
        password="$p"

}

function update_password_hash {

        _u=$1

        if [ -f "/home/$_u/.password" ]
        then
                password=$(cat /home/$_u/.password)
                ## create password hashes
                echo -n $password | openssl dgst -sha512 | cut -d ' ' -f 2 > /home/$_u/.password.sha512
        else
                err "/home/$_u/.password - not found"
        fi

}

function update_password {
        ## for local user
        _u=$1

        ## check if .password file exists and not empty
        if ! [ -f "/home/$_u/.password" ] || [ -z "$(cat /home/$_u/.password 2> /dev/null)" ]
        then
                ## generate new password
                get_password
                echo $password > /home/$_u/.password
                log "User: $_u password: $password set on "$(hostname)
        else
                ## use existing password
                password=$(cat /home/$_u/.password)
        fi

        ## set password on the system
        echo $password | passwd $_u --stdin 2> /dev/null

        ## save
        echo $password > /home/$_u/.password

        update_password_hash $_u

}

function add_user {

        _u=$1

        if [ ! -d "/home/$_u" ]; then

                adduser $_u

                update_password $_u

                create_keypair

        fi
}

function set_file_limits {

    ## You can increase the amount of open files and thus the amount of client connections by using "ulimit -n ". 
    ## For example, to allow pound to accept 5,000 connections and forward 5,000 connection to back end servers (10,000 total) use "ulimit -n 10000".
    ulimit -n 100000

    ## Hint from Tamás Papp to fix Error: Too many open files
    sysctl fs.inotify.max_user_watches=81920 >> /dev/null
    sysctl fs.inotify.max_user_instances=1024 >> /dev/null
}

function create_named_zone {

        ## argument domain ($C or alias)
        D=$1

        mkdir -p /var/named/srvctl
        chown -R named:named /var/named/srvctl

        named_conf=/var/named/srvctl/$D.conf
        named_slave_conf=/var/named/srvctl/$D.slave.conf
        named_zone=/var/named/srvctl/$D.zone

        if [ ! -f $named_conf ]
        then
## TODO convert to single string and command, this is ugly.
                echo '## srvctl named.conf '$D > $named_conf
                echo 'zone "'$D'" {' >> $named_conf
                echo '        type master;'  >> $named_conf
                echo '        file "'$named_zone'";' >> $named_conf
                echo '};' >> $named_conf
        fi

        if [ ! -f $named_slave_conf ]
        then
                echo '## srvctl named.slave.conf '$D > $named_slave_conf
                echo 'zone "'$D'" {' >> $named_slave_conf
                echo '        type slave;'  >> $named_slave_conf
                echo '        masters {'$HOSTIPv4';};'  >> $named_slave_conf
                echo '        file "'$named_zone'";' >> $named_slave_conf
                echo '};' >> $named_slave_conf
        fi

        if [ ! -f $named_zone ]
        then
                

                serial_file=/var/named/serial-counter.txt

                if [ ! -f $serial_file ]
                then
                  serial='1'        
                  echo $serial > $serial_file
                else        
                  serial=$(($(cat $serial_file)+1))
                  echo $serial >  $serial_file
                fi

                set_file $named_zone '$TTL 1D
@        IN SOA        @ hostmaster.'$CDN'. (
                                        '$serial'        ; serial
                                        1D        ; refresh
                                        1H        ; retry
                                        1W        ; expire
                                        3H )        ; minimum
        IN         NS        ns1.'$CDN'.
        IN         NS        ns2.'$CDN'.
*        IN         A        '$HOSTIPv4'
@        IN         A        '$HOSTIPv4'
@        IN        MX        10        mail
        AAAA        ::1'

## TODO add IPv6 support

        fi

        chown named:named $named_conf
        chown named:named $named_slave_conf
        chown named:named $named_zone

        ## TODO create a nice file structure and re-enable this.
        #if [ ! -L $SRV/$C/$D.named.conf ]
        #then
        #   ln -s $named_conf $SRV/$C/$D.named.conf
        #fi

        #if [ ! -L $SRV/$C/$D.named.zone ]
        #then
        #   ln -s $named_zone $SRV/$C/$D.named.zone
        #fi
}

function  get_randomstr {
    randomstr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

function msg_yum_version_installed {
    v=$(yum info $1 | grep -m1 Version)
    i=$(yum info $1 | grep -m1 installed)    
    msg "$1 ${v:13:8} ${i:13}"

}

function generate_lxc_config {

## argument container name.
_c=$1

ntc "Generating lxc configarion files for $_c"

_counter=$(cat $SRV/$_c/config.counter)

_mac=$(to_mac $_counter)
_ip4=$(to_ip $_counter)        

#lxc.network.type = veth
#lxc.network.flags = up
#lxc.network.link = inet-br
#lxc.network.hwaddr = 00:00:00:aa:'$_mac'
#lxc.network.ipv4 = 192.168.'$_ip4'/8
#lxc.network.name = inet-'$_counter'

set_file $SRV/$_c/config '## Template for srvctl created fedora container #'$_counter' '$_c' '$NOW'

lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = srv-net
lxc.network.hwaddr = 00:00:10:10:'$_mac'
lxc.network.ipv4 = 10.10.'$_ip4'/8
lxc.network.name = srv-'$_counter'

lxc.network.ipv4.gateway = auto
#lxc.network.ipv6.gateway = auto

lxc.rootfs = '$SRV'/'$_c'/rootfs
lxc.include = '$lxc_usr_path'/share/lxc/config/fedora.common.conf
lxc.utsname = '$_c'
lxc.autodev = 1

lxc.mount = '$SRV'/'$_c'/fstab
'
## this is there since srvctl 1.x
echo "/var/srvctl $SRV/$_c/rootfs/var/srvctl none ro,bind 0 0" > $SRV/$_c/fstab
## in srvctl 2.x we add the folowwing
echo "$install_dir $SRV/$_c/rootfs/$install_dir none ro,bind 0 0" >> $SRV/$_c/fstab


set_file $SRV/$_c/rootfs/etc/resolv.conf "# Generated by srvctl
search local
nameserver 10.10.0.1
"
echo "10.10."$_ip4 > $SRV/$C/config.ipv4

}


function wait_for_ve_online {

        ## wait for the container to get up check via keyscan
        __llimit=300        
        __n=0

        echo -n '..'

        while [  $__n -lt $__llimit ] 
        do
                sleep 0.1
                res=$(ssh-keyscan -t rsa -H $1 2> /dev/null)

                if [ "${res:0:3}" == '|1|' ]
                then
                        __n=$__llimit 
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done

        echo " online"
}


function wait_for_ve_connection {

        ## wait for the container to get up check via ssh connect
        __llimit=300
        __n=0

        echo -n '..'

        while [  $__n -lt $__llimit ] 
        do
                sleep 0.1
                res=$(ssh $1 exit 2> /dev/null)

                if [ ! "$?" -gt 0 ]
                then
                        __n=$__llimit
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done


        echo " connected"
}


## srvctl functions end here.

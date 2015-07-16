#!/bin/bash


## srvctl functions

function argument {

        if [ -z "$ARG" ]
        then
                if [ "$1" == "C" ] 
                then
                  err "No container-name supplied .."
                  exit
                fi

                if [ "$1" == "U" ] 
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
        arg=${ARG,,}
           
        ## used arguments are
        ## C U db db_name
        
        if [ "$1" == "C" ]
        then
            C=$arg
        fi
        
        if [ "$1" == "U" ]
        then
            U=$arg
        fi

        if [ "$1" == "db" ]
        then
            db=$arg
        fi
        
        if [ "$1" == "db_name" ]
        then
            db_name=$arg
        fi

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

function to_ipv6 {
## TODO implement range
        local __counter=$1

        ## return
        echo $(printf '%x\n'  $__counter)
    
}



function create_certificate { ## for container $C

        ## Prepare self-signed Certificate creation

        # default        
        Cname=$C
        cert_path=$SRV/$C/cert

        if [ ! -z "$1" ]
        then
            if [ -d "$1" ]
            then
                ## argument is a directory, eg. /root
                Cname=$(hostname)
                cert_path=$1
            else 
                ## argument must be a VE
                Cname=$1
                cert_path=$SRV/$Cname/cert
            fi
        fi        
        
        

        ssl_days=1085
        ssl_random=$cert_path/random.txt
        ssl_config=$cert_path/$Cname.txt
        ssl_key=$cert_path/$Cname.key
        ssl_org=$cert_path/$Cname.key.org
        ssl_crt=$cert_path/$Cname.crt
        ssl_csr=$cert_path/$Cname.csr
        ssl_pem=$cert_path/$Cname.pem

        msg "Create certificate for $Cname."

        mkdir -p $cert_path

        ## TODO generate a self signed wildcard certificate!

        set_file $ssl_config "       RANDFILE               = $ssl_random

        [ req ]
        default_bits           = 2048
        default_keyfile        = keyfile.pem
        distinguished_name     = req_distinguished_name
        attributes             = req_attributes
        prompt                 = no
        x509_extensions        = v3_req
        output_password        = $ssl_password

        [ req_distinguished_name ]
        C                      = $CCC
        ST                     = $CCST
        L                      = $CCL
        O                      = $CMP
        OU                     = $CMP CA
        CN                     = $Cname
        emailAddress           = webmaster@$Cname


        [v3_req]
        keyUsage = keyEncipherment, dataEncipherment
        extendedKeyUsage = serverAuth
        subjectAltName = @alt_names
        [alt_names]
        DNS.1 = $Cname
        DNS.2 = *.$Cname

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
        #else
        #        err "/home/$_u/.password - not found"
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
                log "Password is $password for $_u@"$(hostname)
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

function  get_randomstr {
    randomstr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

function msg_yum_version_installed {
    v=$(yum info $1 2> /dev/null | grep -m1 Version)
    i=$(yum info $1 2> /dev/null | grep -m1 installed)    
    msg "$1 ${v:13:8} ${i:13}"

}

function lxc_ls {
    ## special lxc-ls that honors the call via sudo
    for _lsi in $(lxc-ls)
    do
            if [ ! -z "$SC_SUDO_USER" ]
            then
                _skp=true
                for _uti in $(cat $SRV/$_lsi/users)
                do
                    if [ "$_uti" == "$SC_SUDO_USER" ]
                    then
                        _skp=false
                        break
                    fi
                done
                
                if $_skp
                then
                    continue
                fi
            fi
            
            echo $_lsi
            
      done
}

function sudomize {
    ## switch to root
    if $isUSER
    then
        sudo $install_dir/srvctl-sudo.sh $ARGS
        exit
    fi
}

function authorize { ## sudo access container $C for current user
    _aok=false
    
    if [ ! -z "$SC_SUDO_USER" ]
    then   
        for _uti in $(cat $SRV/$C/users)
        do
                    if [ "$_uti" == "$SC_SUDO_USER" ]
                    then
                        _aok=true
                        break
                    fi
        done
        
        if ! $_aok
        then
            err "Permission denied. $SC_SUDO_USER@$C"
            exit
        fi
    fi  
}

function make_aliases_db {

#argument $1=filesystem

if [ ! -f /etc/aliases.db ] || $all_arg_set
then

## We will mainly use these files to copy over to clients. Main thing is: info should not be aliased.
set_file $1/etc/aliases '
#
#  Aliases in this file will NOT be expanded in the header from
#  Mail, but WILL be visible over networks or from /bin/mail.
#
#        >>>>>>>>>>        The program "newaliases" must be run after
#        >> NOTE >>        this file is updated for any changes to
#        >>>>>>>>>>        show through to sendmail.
#

# Basic system aliases -- these MUST be present.
mailer-daemon:        postmaster
postmaster:        root

# General redirections for pseudo accounts.
bin:                root
daemon:                root
adm:                root
lp:                root
sync:                root
shutdown:        root
halt:                root
mail:                root
news:                root
uucp:                root
operator:        root
games:                root
gopher:                root
ftp:                root
nobody:                root
radiusd:        root
nut:                root
dbus:                root
vcsa:                root
canna:                root
wnn:                root
rpm:                root
nscd:                root
pcap:                root
apache:                root
webalizer:        root
dovecot:        root
fax:                root
quagga:                root
radvd:                root
pvm:                root
amandabackup:        root
privoxy:        root
ident:                root
named:                root
xfs:                root
gdm:                root
mailnull:        root
postgres:        root
sshd:                root
smmsp:                root
postfix:        root
netdump:        root
ldap:                root
squid:                root
ntp:                root
mysql:                root
desktop:        root
rpcuser:        root
rpc:                root
nfsnobody:        root

ingres:                root
system:                root
toor:                root
manager:        root
dumper:                root
abuse:                root

newsadm:        root #news
newsadmin:        root #news
usenet:                root #news
ftpadm:                root #ftp
ftpadmin:        root #ftp
ftp-adm:        root #ftp
ftp-admin:        root #ftp
www:                webmaster
webmaster:        root
noc:                root
security:        root
hostmaster:        root
#info:                postmaster
#marketing:        postmaster
#sales:                postmaster
#support:        postmaster


# trap decode to catch security attacks
decode:                root

# Person who should get roots mail
#root:                marc
'

## TODO alternatives set postfix as default MTA - or newaliases wont work.

fi ## set aliases
}


## srvctl functions end here.
## additional configuration checks.
### TODO 2.x check if this is needed. propably only on source install

if $onHS
then
        ## yum and source builds work with different directories.
        lxc_usr_path="/usr"
        lxc_bin_path="/usr/bin"
        if [ "$LXC_INSTALL" == "git" ] || [ "$LXC_INSTALL" == "src" ] || [ "$LXC_INSTALL" == "tar" ]
        then
                lxc_usr_path="/usr/local"
                lxc_bin_path="/usr/local/bin"
                
                if [ -z $(echo $LD_LIBRARY_PATH | grep '/usr/local/lib') ]
                then
                        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
                fi
        fi
        
    if [ -z $(echo $PATH | grep $lxc_bin_path) ]
    then
        export PATH=$PATH:$lxc_bin_path
    fi        
    

    if [ ! -d "$lxc_usr_path/share/lxc" ]
    then
        err "Configuration error. Directory not found: $lxc_usr_path/share/lxc"
        exit
    fi    
    
    if [ ! -d "$lxc_usr_path/share/lxc/templates" ]
    then
        err "Configuration error. Directory not found: $lxc_usr_path/share/lxc/templates"
        exit
    fi
        
    if [ ! -d "$lxc_usr_path/share/lxc/config" ]
    then
        err "Configuration error. Directory not found: $lxc_usr_path/share/lxc/config"
        exit
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-ls" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-ls (part of lxc-extra)"
        locate lxc-ls
        exit
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-start" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-start"
        locate lxc-start
        exit
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-stop" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-start"
        locate lxc-start
        exit
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-info" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-start"
        locate lxc-start
        exit
    fi
fi


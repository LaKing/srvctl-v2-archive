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
                
                if [ "$1" == "D" ] 
                then
                  err "No domain-name supplied .."
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
        
        if [ "$1" == "D" ]
        then
            D=$arg
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
        
        if [ "$1" == "CMS" ]
        then
            CMS=$arg
        fi
        
        
        if [ "$1" == "dyndnshost" ]
        then
            dyndnshost=$arg
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

function update_password { ## for local user

    local _u=$1
    local password=''
    local passtor=/var/srvctl-users/$_u
    mkdir -p $passtor
    
    ## make sure we dont have empty passwords
    if [ -z "$(cat $passtor/.password 2> /dev/null)" ]
    then
        rm -rf $passtor/.password
    fi
    
    if [ -z "$(cat /home/$_u/.password 2> /dev/null)" ]
    then
        rm -rf /home/$_u/.password
    fi
    
    ## Generate the passcode, which is the default password by the system
    if [ "$ROOTCA_HOST" == $HOSTNAME ]
    then
        if [ ! -f /var/srvctl-users/$_u/.passcode ]
        then
            get_password
            echo -n "$password" > $passtor/.passcode
        fi
        password="$(cat $passtor/.passcode )"
        
        if [ ! -f $passtor/.password ]
        then
            echo -n "$(cat $passtor/.passcode)"  > $passtor/.password
        fi 
    fi
    
    ## copy from home to store
    if [ -f /home/$_u/.password.sha512 ]
    then
        echo -n "$(cat /home/$_u/.password.sha512)" > $passtor/.password.sha512
    fi

    ## copy from store to home
    if [ -f $passtor/.password.sha512 ] && [ ! -f /home/$_u/.password.sha512 ]
    then
        echo -n "$(cat $passtor/.password.sha512)" > /home/$_u/.password.sha512
    fi

    if [ -f /home/$_u/.password ]
    then
        echo -n "$(cat /home/$_u/.password)"  > $passtor/.password
    fi
   
    if  [ ! -f /home/$_u/.password ] && [ -f $passtor/.password ]
    then
        echo -n "$(cat $passtor/.password)" > /home/$_u/.password
    fi  
       
    if [ -f "$passtor/.password" ]
    then
                ## use existing password
                password=$(cat $passtor/.password )
    fi
       
    if [ -z "$password" ]
    then
        err "Password-system encountered an error. Skipping."
        return
    fi
    
    if [ -f "$passtor/$HOSTNAME.password" ]
    then
            ## use existing password
            current_password=$(cat $passtor/$HOSTNAME.password )
    fi
    
    if [ "$password" != "$current_password" ]
    then

        ## set password on the system
        echo $password | passwd $_u --stdin 2> /dev/null 1> /dev/null
        echo -n "$password" > $passtor/$HOSTNAME.password
        log "Password is $password for $_u@$HOSTNAME"    
    
        ## save
        echo -n $(echo -n $password | openssl dgst -sha512 | cut -d ' ' -f 2) > $passtor/.password.sha512
        echo -n $(cat $passtor/.password.sha512) > /home/$_u/.password.sha512
    
        echo -n $password > /home/$_u/.password

    fi
    
        chown $_u:$_u /home/$_u/.password
        chmod 400 /home/$_u/.password  
        chown $_u:$_u /home/$_u/.password.sha512
        chmod 400 /home/$_u/.password.sha512

}

function create_user_keypair { ## for user $U
        
        local _u=$1
        mkdir -p /home/$_u/.ssh
        
        ## create ssh keypair
    
    if $onHS
    then
        
        if [ "$ROOTCA_HOST" == $HOSTNAME ]
        then
            if [ ! -f /var/srvctl-users/$_u/user_id_rsa.pub ] || [ ! -f /var/srvctl-users/$_u/user_id_rsa ]
            then
                rm -fr /var/srvctl-users/$_u/user_id_rsa.pub
                rm -fr /var/srvctl-users/$_u/user_id_rsa
        
               msg "Creating keypair for user "$_u
               ssh-keygen -t rsa -b 4096 -f /var/srvctl-users/$_u/user_id_rsa -N '' -C $_u@$CDN
            fi
        fi
        
        if [ ! -f /var/srvctl-users/$_u/user_id_rsa.pub ] || [ ! -f /var/srvctl-users/$_u/user_id_rsa ]
        then
            ntc "No user_id_rsa for $_u"
        else
            cat /var/srvctl-users/$_u/user_id_rsa.pub > /home/$_u/.ssh/id_rsa.pub
            cat /var/srvctl-users/$_u/user_id_rsa > /home/$_u/.ssh/id_rsa
        fi
        
    fi
    
    if $onVE
    then
        ## create ssh keypair
        if [ ! -f /home/$_u/.ssh/id_rsa.pub ]
        then
           msg "Creating keypair for user "$_u
           ssh-keygen -t rsa -b 4096 -f /home/$_u/.ssh/id_rsa -N '' -C $_u@@$(hostname)
        fi
    fi
    
    
        chown -R $_u:$_u /home/$_u/.ssh
        chmod -R 600 /home/$_u/.ssh
        chmod    700 /home/$_u/.ssh
    
}
function create_srvctl_keypair { ## for user $U
    
    if [ "$ROOTCA_HOST" == $HOSTNAME ]
    then
        
        local _u=$1

        ## srvctl-gui keypair
        mkdir -p /var/srvctl-users/$_u
    
        if [ ! -f /var/srvctl-users/$_u/srvctl_id_rsa.pub ]
        then
            ssh-keygen -t rsa -b 4096 -f /var/srvctl-users/$_u/srvctl_id_rsa -N '' -C $_u-srvtcl-key
        fi
    fi
}


function add_user {
    
    ## onHS or onVE
    ## add-user command
    ## add-user to container command
    ## add-user from container-settings

    local U=$1
    local _had=false

    if [ $U == root ]
    then
        return
    fi
    
    if ! $all_arg_set
    then
        if [ ! -z "$(cat /etc/passwd | grep /home/$U:)" ] && [ -d /home/$U ] && [ -d /var/srvctl-users/$U ]
        then
            return
        fi
    fi
    
    if [ -d /home/$U ] && [ ! -z "$(cat /etc/passwd | grep '/home/$U:')" ]
    then
        err "User dont exist on system but has a home folder !"
    fi

    if [ ! -d /home/$U ]
    then
        msg "add user $U"
        adduser $U
    fi
    
    if [ -f /bin/git ]
    then
        if [ -z "$(su $_U -c 'cd ~ && git config --global user.email')" ]
        then
            su $_U -c "cd ~ && git config --global user.email $_U@$HOSTNAME"
        fi
        if [ -z "$(su $_U -c 'cd ~ && git config --global user.name')" ]
        then
            su $_U -c "cd ~ && git config --global user.name $_U"
        fi
        if [ -z "$(su $_U -c 'cd ~ && git config --global push.default')" ]
        then
            su $_U -c "cd ~ && git config --global push.default simple"
        fi
    fi
    
    if $onVE
    then
        update_password $U
        create_user_keypair $U
        return
    fi
    
    if [ "$ROOTCA_HOST" == $HOSTNAME ]
    then

        update_password $U
        create_user_keypair $U
        create_srvctl_keypair $U
        create_ca_certificate client usernet $U
        
    else
    
        if [ ! -d /var/srvctl-users/$U ]
        then
            err "Cannot sync user, not availble from the authoritive host $ROOTCA_HOST"
        fi
    
        update_password $U
        create_user_keypair $U        
        
    fi
    
}

function  get_randomstr {
    randomstr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

function msg_dnf_version_installed {
    v=$(dnf info $1 2> /dev/null | grep -m1 Version)
    i=$(dnf info $1 2> /dev/null | grep -m1 installed)    
    msg "$1 ${v:13:8} ${i:13}"

}


function sudomize {
    ## switch to root
    if $isUSER
    then
        sudo $install_dir/srvctl-sudo.sh $ARGS
        exit
    fi
}

function authorize { ## sudo access to container $C for current user
    _aok=false
    
    if [ -z "$C" ]
    then
        err "No container specified."
        exit 34
    fi
    
    if [ ! -f $SRV/$C/config ] && [ -f /var/dyndns/$C.auth ]
    then
        auth=$(cat /var/dyndns/$C.auth)
            
        if [ "${auth:0:${#SC_USER}}" == $SC_USER ] || [ $SC_USER == root ]
        then
            echo OK > /dev/null
        else
            err "Permission denied. $SC_USER@$C"
            exit 7
        fi
    fi
    
    if [ ! -f $SRV/$C/config ] && [ ! -f /var/dyndns/$C.auth ]
    then
        err "No such thing here."
        exit 35
    fi
    
    if $isSUDO && [ -f $SRV/$C/settings/users ]
    then   
        for _uti in $(cat $SRV/$C/settings/users)
        do
                    if [ "$_uti" == "$SC_USER" ]
                    then
                        _aok=true
                        break
                    fi
        done
        
        if ! $_aok
        then
            err "Permission denied. $SC_USER@$C"
            exit 7
        fi
    fi  
}

function make_aliases_db {

#argument $1=filesystem

if [ ! -f $1/etc/aliases.db ] || $all_arg_set
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

postalias $1/etc/aliases

fi ## set aliases
}

function add_service {
    
    if [ -f /usr/lib/systemd/system/$1.service ]
    then
        mkdir -p /etc/srvctl/system
        ln -s /usr/lib/systemd/system/$1.service /etc/srvctl/system/$1.service 2> /dev/null

        systemctl enable $1.service
        systemctl restart $1.service
        systemctl status $1.service --no-pager
    else
        err "No such service - $1 (add)"
    fi
    
   
}

function rm_service {
    
    if [ -f /usr/lib/systemd/system/$1.service ]
    then
    
        rm -rf /etc/srvctl/system/$1.service 2> /dev/null
    
        systemctl disable $1.service
        systemctl stop $1.service
    
    else
        err "No such service - $1 (rm)"
    fi
}



## srvctl functions end here.
## additional configuration checks.
### TODO 2.x check if this is needed. propably only on source install

if $onHS
then
        ## dnf and source builds work with different directories.
        lxc_usr_path="/usr"
        lxc_bin_path="/usr/bin"
        if [ "$LXC_INSTALL" == "git" ] || [ "$LXC_INSTALL" == "src" ] || [ "$LXC_INSTALL" == "tar" ]
        then
                lxc_usr_path="/usr/local"
                lxc_bin_path="/usr/local/bin"

                ## err? ... has to be disabled for lxc 2.0 and up? or no?
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
    fi    
    
    if [ ! -d "$lxc_usr_path/share/lxc/templates" ]
    then
        err "Configuration error. Directory not found: $lxc_usr_path/share/lxc/templates"
    fi
        
    if [ ! -d "$lxc_usr_path/share/lxc/config" ]
    then
        err "Configuration error. Directory not found: $lxc_usr_path/share/lxc/config"
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-ls" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-ls (part of lxc-extra)"
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-start" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-start"
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-stop" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-start"
    fi
    
    if [ ! -f "$lxc_bin_path/lxc-info" ]
    then
        err "Configuration error. binary not found: $lxc_bin_path/lxc-start"
    fi
    
        
fi





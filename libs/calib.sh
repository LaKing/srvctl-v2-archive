## https://github.com/coolaj86/nodejs-ssl-trusted-peer-example/blob/master/make-root-ca-and-certificates.sh

## For client certificates

sc_ca_dir=/etc/srvctl/CA

function root_CA_create {
    
    local _name=$1
    
    if [ ! -f "$sc_ca_dir/ca/$_name.key.pem" ]
    then
        # Create own Root Certificate Authority
        msg "create $_name ca-key"
    
        openssl genrsa \
        -out $sc_ca_dir/ca/$_name.key.pem \
        2048
        
        chmod 600 $sc_ca_dir/ca/$_name.key.pem
    fi
    
    if [ ! -f "$sc_ca_dir/ca/$_name.crt.pem" ]
    then
        msg "create $_name ca-cert"
        openssl req \
        -x509 \
        -new \
        -nodes \
        -key $sc_ca_dir/ca/$_name.key.pem \
        -days 3652 \
        -out $sc_ca_dir/ca/$_name.crt.pem \
        -subj "$rootca_subj/CN=$CMP-$_name-ca"
    fi 
    
    if [ ! -f "$sc_ca_dir/ca/$_name.srl" ]
    then
        echo 02 > $sc_ca_dir/ca/$_name.srl
    fi

}


function root_CA_init {

if [ "$rootca_host" == "$HOSTNAME" ]
then    
    # make directories to work from
    mkdir -p $sc_ca_dir/{usernet,hostnet,ca,tmp}
    chmod 600 $sc_ca_dir/ca/*
    chmod 600 $sc_ca_dir/usernet/*
    chmod 600 $sc_ca_dir/hostnet/*

    root_CA_create usernet
    root_CA_create hostnet
fi    
}


function create_client_certificate { ## argument user, ca

if [ "$rootca_host" == "$HOSTNAME" ]
then
    
    local _name=$1
    local _u=$2
    
    local _file=$_u
    
    if [ "$1" == usernet ]
    then
        _file=$CDN-$_u
    fi
    
    if [ ! -f "$sc_ca_dir/$_name/$_file.key.pem" ]
    then
        msg "create $_name $_u key"
        openssl genrsa \
        -out $sc_ca_dir/$_name/$_file.key.pem \
        2048
        
        chmod 600 $sc_ca_dir/$_name/$_file.key.pem
    fi

    if [ ! -f "$sc_ca_dir/tmp/$_file.csr.pem" ]
    then
        msg "create $_name $_u csr"
    
        # Create a trusted client cert
        openssl req -new \
        -key $sc_ca_dir/$_name/$_file.key.pem \
        -out $sc_ca_dir/tmp/$_file.csr.pem \
        -subj "$rootca_subj/CN=$_u"
    fi
    
    if [ ! -f "$sc_ca_dir/$_name/$_file.crt.pem" ]
    then
        msg "create $_name $_u cert"

        # Sign the request from Trusted Client with your Root CA
        # we wont use CAcreateserial   
        openssl x509 \
        -req -in $sc_ca_dir/tmp/$_file.csr.pem \
        -CA $sc_ca_dir/ca/$_name.crt.pem \
        -CAkey $sc_ca_dir/ca/$_name.key.pem \
        -CAserial $sc_ca_dir/ca/$_name.srl \
        -out $sc_ca_dir/$_name/$_file.crt.pem \
        -days 1095
    fi

    if [ -f /var/srvctl-host/users/$_u/.password ]
    then
        local _passphrase="$(cat $passtor/.password)"

        if [ ! -f "$sc_ca_dir/$_name/$_file.p12" ]
        then
            msg "create $_u p12"

            openssl pkcs12 -export \
            -passout pass:$_passphrase \
            -in $sc_ca_dir/$_name/$_file.crt.pem \
            -inkey $sc_ca_dir/$_name/$_file.key.pem \
            -out $sc_ca_dir/$_name/$_file.p12
        fi
    
        if [ ! -f "/home/$_u/$_file.p12" ] 
        then
            cat $sc_ca_dir/$_name/$_file.p12 > /home/$_u/$_file.p12
            chown $_u:$_u /home/$_u/$_file.p12
            chmod 400 /home/$_u/$_file.p12
        fi
    fi

#else
#    msg ".. this is not the CA"
fi

}


## For pound / self signed certificates

function check_pound_pem {
  
  if [ -f "$pound_pem" ]
  then
    if openssl x509 -checkend 604800 -noout -in $pound_pem
    then
      #dbg "$pound_pem OK" 
      echo 0 > /dev/null
    else
      msg "Certificate has expired or will do so within a week! $pound_pem"
      rm -rf $pound_pem
    fi
  fi
  
}

## create selfsigned certificate the hard way
function create_certificate { ## for domain
                
        domain=$1
        #cert_path=/etc/srvctl/cert/$domain
        
        if [ -z "$domain" ]
        then
            err "No domain specified to create certificate"
            return
        fi
        
        if [ -z "$cert_path" ]
        then
            err "No cert_path specified"
            return
        fi
        
        mkdir -p $cert_path

        ssl_days=365
        
        ## configuration files
        ssl_random=$cert_path/random.txt
        ssl_config=$cert_path/config.txt
        ssl_extfile=$cert_path/extfile.txt
        
        ## key unencrypted
        ssl_key=$cert_path/$domain.key
        ## key encrypted
        ssl_org=$cert_path/$domain.key.org
        
        ## certificate signing request
        ssl_csr=$cert_path/$domain.csr
        
        ## the self signed certificate
        ssl_crt=$cert_path/$domain.crt
        
        ## THE CERTIFICATE - overwrite with:
        ## key 
        ## CA signed crt
        ssl_pem=$cert_path/$domain.pem
        ssl_cab=$cert_path/ca-bundle.pem
        
        if [ ! -f $ssl_cab ]
        then
            ssl_cab=''
        fi
        
        if [ -f $ssl_pem ] && [ ! -z "$(cat $ssl_pem)" ]
        then
            if openssl x509 -checkend 604800 -noout -in $ssl_pem
            then
                openssl verify -CAfile $ssl_pem $ssl_pem > /dev/null
                if [ "$?" == "2" ]
                then
                    #ntc "$domain already has a Self signed certificate!" 
                    return
                else
                    if openssl verify -CAfile $ssl_pem -verify_hostname $domain $ssl_pem > /dev/null
                    then
                        if [ ! -f $ssl_key ]
                        then
                            err "Domain $domain has certificate, but no key-file! $ssl_key ?"
                            exit
                        fi                   
                        cat $ssl_pem > $cert_path/pound.pem
                        msg "$domain has a valid certificate."
                        return    
                    fi

                fi
            else
                ntc "$domain certificate invalid or will expire soon! $ssl_pem"
            fi
        fi
        
        if [ -f $ssl_crt ] || [ -f $ssl_pem ]
        then
            ntc "Remove $cert_path manually to create a new certificate."
            ntc "Certificate files must be: $ssl_key $ssl_crt"
            ls $cert_path
            return
        fi

        if [ -z "$ssl_password" ]
        then
            get_password
            ssl_password="$password"
            
            get_password
            ssl_password="$ssl_password$password"
        fi

        msg "Create certificate for $domain."

        mkdir -p $cert_path

        set_file $ssl_config "## srvctl generated config file
        
        RANDFILE               = $ssl_random

        [ req ]
        prompt                 = no
        string_mask            = utf8only
        default_bits           = 2048
        default_keyfile        = keyfile.pem
        distinguished_name     = req_distinguished_name

        req_extensions         = v3_req
        
        output_password        = $ssl_password

        [ req_distinguished_name ]
        CN                     = $domain
        emailAddress           = webmaster@$domain
"


        set_file $ssl_extfile "
        [ v3_req ]
        basicConstraints = critical,CA:FALSE
        keyUsage = keyEncipherment, dataEncipherment
        extendedKeyUsage = serverAuth
        subjectAltName = @alt_names
        [alt_names]
        DNS.1 = $domain
        DNS.2 = *.$domain
"
        

        cat $ssl_extfile >> $ssl_config

        #### create certificate      

        ## Generate a Private Key
        openssl genrsa -des3 -passout pass:$ssl_password -out $ssl_key 2048 2> /dev/null

        ## Generate a CSR (Certificate Signing Request)
        openssl req -new -passin pass:$ssl_password -passout pass:$ssl_password -key $ssl_key -out $ssl_csr -days $ssl_days -config $ssl_config 2> /dev/null
        
        ## Remove Passphrase from Key
        cp $ssl_key $ssl_org
        openssl rsa -passin pass:$ssl_password -in $ssl_org -out $ssl_key 2> /dev/null       
        
        ## Self-Sign Certificate
        openssl x509 -req -days $ssl_days -passin pass:$ssl_password -extensions v3_req -extfile $ssl_extfile -in $ssl_csr -signkey $ssl_key -out $ssl_crt 2> /dev/null

        ## create a certificate chainfile in pem format
        cat $ssl_key >  $ssl_pem
        cat $ssl_crt >> $ssl_pem
        
        ## pound.pem - ready to use certificate chain for pound
        ## key 
        ## CA signed crt
        ## ca-bundle
        cat $ssl_pem > $cert_path/pound.pem
}


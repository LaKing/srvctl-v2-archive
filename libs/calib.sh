## For client certificates

sc_ca_dir=/etc/srvctl/CA

function root_CA_init {

if [ "$rootca_host" == "$HOSTNAME" ]
then

    #msg "This server is the SC-CA"
    
    # make directories to work from
    mkdir -p $sc_ca_dir/{server,client,ca,tmp}

    if [ ! -f "$sc_ca_dir/ca/$CDN-root-ca.key.pem" ]
    then
        # Create own Root Certificate Authority
        msg "create root-ca-key"
    
        openssl genrsa \
        -out $sc_ca_dir/ca/$CDN-root-ca.key.pem \
        2048

        # Self-sign Root Certificate Authority
        # Since this is private, the details can be as bogus as you like
        
    fi
    
    if [ ! -f "$sc_ca_dir/ca/$CDN-root-ca.crt.pem" ]
    then
        msg "create root-ca-cert"
        openssl req \
        -x509 \
        -new \
        -nodes \
        -key $sc_ca_dir/ca/$CDN-root-ca.key.pem \
        -days 3652 \
        -out $sc_ca_dir/ca/$CDN-root-ca.crt.pem \
        -subj "$rootca_subj/CN=$CMP"
    fi

else
    msg "this is not the CA"
fi    
}

function create_server_certificate { ## argument server-hostname

local _servername="$1"

if [ "$rootca_host" == "$HOSTNAME" ]
then

    root_CA_init 

    # Create a Device Certificate for a domain,
    # such as example.com, *.example.com, awesome.example.com
    # NOTE: You MUST match CN to the domain name or ip address you want to use

    if [ ! -f "$sc_ca_dir/server/$CDN-$_servername.key.pem" ]
    then
        msg "create $_servername key"
        openssl genrsa \
        -out $sc_ca_dir/server/$CDN-$_servername.key.pem \
        2048
        
    fi
    
    
    if [ ! -f "$sc_ca_dir/tmp/$CDN-$_servername.csr.pem" ]
    then
        msg "create $_servername csr"
    
        # Create a request from your Device, which your Root CA will sign
        openssl req -new \
        -key $sc_ca_dir/server/$CDN-$_servername.key.pem \
        -out $sc_ca_dir/tmp/$CDN-$_servername.csr.pem \
        -subj "$rootca_subj/CN=$_servername"
        
    fi
    
    if [ ! -f "$sc_ca_dir/server/$CDN-$_servername.crt.pem" ]
    then
        msg "create $_servername cert"
    
        # Sign the request from Device with your Root CA
        # -CAserial $sc_ca_dir/ca/$CDN-root-ca.srl
        openssl x509 \
        -req -in $sc_ca_dir/tmp/$CDN-$_servername.csr.pem \
        -CA $sc_ca_dir/ca/$CDN-root-ca.crt.pem \
        -CAkey $sc_ca_dir/ca/$CDN-root-ca.key.pem \
        -CAcreateserial \
        -out $sc_ca_dir/server/$CDN-$_servername.crt.pem \
        -days 1095

    fi

        # Create a public key, for funzies
        #openssl rsa \
        #  -in $sc_ca_dir/server/$CDN-server.key.pem \
        #  -pubout -out $sc_ca_dir/client/$CDN-server.pub

else
    msg "this is not the CA"
fi
}

function create_client_certificate { ## argument user

local _u=$1

local passtor=/var/srvctl-host/users/$_u
local _commonname="$_u"
local _passphrase="$(cat $passtor/.password)"

if [ "$rootca_host" == "$HOSTNAME" ]
then

    root_CA_init 

    # Create a Device Certificate for each trusted client
    # such as example.net, *.example.net, awesome.example.net
    # NOTE: You MUST match CN to the domain name or ip address you want to use
    
    if [ ! -f "$sc_ca_dir/client/$CDN-$_commonname.key.pem" ]
    then
        msg "create $_commonname key"
        openssl genrsa \
        -out $sc_ca_dir/client/$CDN-$_commonname.key.pem \
        2048
    fi

    if [ ! -f "$sc_ca_dir/tmp/$CDN-$_commonname.csr.pem" ]
    then
        msg "create $_commonname csr"
    
        # Create a trusted client cert
        openssl req -new \
        -key $sc_ca_dir/client/$CDN-$_commonname.key.pem \
        -out $sc_ca_dir/tmp/$CDN-$_commonname.csr.pem \
        -subj "$rootca_subj/CN=$_commonname"
    fi
    
    if [ ! -f "$sc_ca_dir/client/$CDN-$_commonname.crt.pem" ]
    then
        msg "create $_commonname cert"

        # Sign the request from Trusted Client with your Root CA
        # -CAserial $sc_ca_dir/ca/$CDN-root-ca.srl
        openssl x509 \
        -req -in $sc_ca_dir/tmp/$CDN-$_commonname.csr.pem \
        -CA $sc_ca_dir/ca/$CDN-root-ca.crt.pem \
        -CAkey $sc_ca_dir/ca/$CDN-root-ca.key.pem \
        -CAcreateserial \
        -out $sc_ca_dir/client/$CDN-$_commonname.crt.pem \
        -days 1095
    fi

    if [ ! -f "$sc_ca_dir/client/$CDN-$_commonname.p12" ]
    then
        msg "create $_commonname p12"

        openssl pkcs12 -export \
        -passout pass:$_passphrase \
        -in $sc_ca_dir/client/$CDN-$_commonname.crt.pem \
        -inkey $sc_ca_dir/client/$CDN-$_commonname.key.pem \
        -out $sc_ca_dir/client/$CDN-$_commonname.p12
    fi
    
    if [ ! -f "/home/$_u/$CDN-$_commonname.p12" ] 
    then
        cat $sc_ca_dir/client/$CDN-$_commonname.p12 > /home/$_u/$CDN-$_commonname.p12
    fi



# Create a public key, for funzies
#openssl rsa \
#  -in $sc_ca_dir/client/$CDN-app-client.key.pem \
#  -pubout -out $sc_ca_dir/client/$CDN-app-client.pub

else
    msg ".. this is not the CA"
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


#!/bin/bash

if $onHS
then

hint "show-csr VE" "Show the certificate signing request, (CSR) for secure https connections of the VE."

if [ "$CMD" == "show-csr" ]
then

    argument C
    sudomize
    authorize

    if [ ! -d "$SRV/$C" ]
    then
        err "Could not find container $C"
        exit
    fi

    if [ ! -f "$SRV/$C/cert/$C.csr" ]
    then
        err "There is no CSR for $C"
        exit
    fi

    msg "The Certificate-signing-request (CSR) for $C"
    cat $SRV/$C/cert/$C.csr
ok
fi

man '
    The certificate signing request to be used for signing. mandatory for HTTPS connections.
'

hint "import-crt [CRT]" "Import a signed certificate for secure https connections of the VE."

if [ "$CMD" == "import-crt" ]
then

    tmp_file=$TMP/$USER-srvctl-import.crt

    if [ -z "$ARG" ]
    then
        rm -rf $tmp_file
        msg "Please paste the signed certificate. (CRT)"
        while read line
        do
            # break if the line is empty
            if [ -z "$line" ]
            then 
                break
            fi
            echo "$line" >> $tmp_file
        done
    else

        msg "Import CRT from file-path."

        
        imp_file=$ARG

        if [ ! -f "$ARG" ]
        then
            imp_file=$CWD/$ARG
        fi
    
        if [ ! -f "$imp_file" ]
        then
            err "Certificate not found. $imp_file"
            exit
        else
            cat $imp_file > $tmp_file
        fi
    fi  

 #dbg "@&@ USER:$USER SUDO:$SC_USER isROOT: $isROOT"
 
    msg "--- Certificate ---"
    openssl x509 -text -in $tmp_file
    msg "-------------------"
 
    _path=''
    if $isROOT
    then
        _path=$SRV
    else
        _path="/home/$USER/$SC_USER"
    fi
    
    C=''

    crt_subject=$(openssl x509 -subject -noout -in $tmp_file 2> /dev/null)
    
    if [ -z "$crt_subject" ]
    then
        err "Not a certificate."
        exit
    fi
    
    
    #dbg "$crt_subject"
    ## example subject= /OU=Domain Control Validated/OU=Gandi Standard SSL/CN=otvoreni.market
    
    ## SUBSTRACT COMMON NAME from certificate - TODO work on this
    crt_cn=$(echo $crt_subject | grep -o -P '(?<=CN=).*(?=/)')
    
    
    if [ "${crt_cn:0:2}" == "*." ]
    then
        crt_cn="${crt_cn:2}"
    fi
    
    if [ "${crt_cn:0:4}" == "www." ]
    then
        crt_cn="${crt_cn:4}"
    fi
    
    if [ -d "$_path/$crt_cn" ] && ! [ -z "$crt_cn" ]
    then
        ## looks like an existing domain was found
        C="$crt_cn"
    fi        
    
    if [ -z "$C" ]
    then
        
        crt_altnames=$(openssl x509 -text -in $tmp_file | grep -A 1 "X509v3 Subject Alternative Name:" | tail -n 1 | xargs)
        IFS=', ' read -a array <<< "$crt_altnames"

        ## try to find a matching pair
        for element in "${array[@]}"
        do
            crt_an="${element:4}"

            if [ "${crt_an:0:2}" == "*." ]
            then
                crt_an="${crt_an:2}"
            fi
    
            if [ "${crt_an:0:4}" == "www." ]
            then
                crt_an="${crt_an:4}"
            fi        
        
            if [ -d "$_path/$crt_an" ]
            then
                ## looks like an existing domain was found
                C="$crt_an"
                break
            fi        
        
        done
    fi
    
    if [ -z "$C" ]
    then
       msg "Could not find a matching container. $crt_cn $crt_altnames"
       exit
    fi
    
    ## container name is extracted from the certificate
        
    if ! $isROOT
    then
        #dbg "@SUDOMIZE USER:$USER SUDO:$SC_USER isROOT: $isROOT"
        sudo $install_dir/srvctl-sudo.sh import-crt $tmp_file
        exit
    fi
    
    authorize
        #dbg "AUTHORIZED"

    if [ ! -d "$SRV/$C" ] || [ -z "$C" ]
    then
        err "Could not find container $C"
        exit
    else 
        msg "Using container $C"
    fi

    cat $tmp_file > $SRV/$C/cert/$C.import.crt
    rm -rf $tmp_file
    
    if [ -z "$(openssl x509 -subject -noout -in $SRV/$C/cert/$C.import.crt | grep $C)" ]
    then
        err "Certificate does not appear to match domain name. $C"
        exit
    fi
    
    
    cat $SRV/$C/cert/$C.key > $SRV/$C/cert/$C.import.pem
    cat $SRV/$C/cert/$C.import.crt >>  $SRV/$C/cert/$C.import.pem
    
    cert_status=$(openssl verify -CAfile /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt $SRV/$C/cert/$C.import.pem 2> /dev/null | tail -n 1 | tail -c 3)


    if [ "$cert_status" == "OK" ]
    then 
        # echo "VALID CERT FOUND"
        bak $SRV/$C/cert/pound.pem
        cat $SRV/$C/cert/$C.import.pem > $SRV/$C/cert/pound.pem
        cp -r $SRV/$C/cert /var/pound/$C 
        msg "certificate added for $C"
        systemctl restart pound.service
        systemctl status pound.service  --no-pager
        #echo 'Cert "'$SRV/$C/cert'/pound.pem"' >> /var/pound/https-certificates.cfg
    else
        err "Could not verify the certificate."
        openssl verify -CAfile /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt $SRV/$C/cert/$C.import.pem
        # echo "CERT INVALID"
        bak $SRV/$C/cert/import.pem
        rm -rf $SRV/$C/cert/import.pem
    fi

ok
fi

man '
    The HTTPS protocol requires certificates to work. By default srvctl generates self-signed certificates.
    Signed certificates can be imported with this command. Encryped certificates are not supported.
    The CRT may contain the CA-bundle, eg. the certificate chain, the key, and the signed certificate in PEM format.
'

if $isROOT
then
hint "import-ca CRT" "Import a pem format root-certificate file issued from a trusted certificate authority."

if [ "$CMD" == "import-ca" ]
then

    for c in $(ls /etc/pki/ca-trust/source/anchors)
    do   
       msg "CA-CRT: $(openssl x509 -noout -subject -in /etc/pki/ca-trust/source/anchors/$c) #$(openssl x509 -noout -serial -in /etc/pki/ca-trust/source/anchors/$c)"
    done

    if [ -z "$ARG" ]
    then
        err "Certificate needed for import."
        exit
    fi
    
    ca_file=$ARG

    if [ ! -f "$ARG" ]
    then
        ca_file=$CWD/$ARG
    fi
    
    if [ ! -f "$ca_file" ]
    then
        err "Certificate not found."
        exit
    fi
        
    ca_file_name=$(basename $ca_file)
    if [ ! "${ca_file_name: -4}" == ".pem" ] && [ ! "${ca_file_name: -4}" == ".crt" ]
    then
        err "Extension mismach. $ca_file_name"
        exit 
    fi    
    
    if [ ! "$(openssl verify $ca_file)" == "$ca_file: OK" ]
    then
        err "Could not verify $ca_file"
        exit
    fi

    ca_hash=$(openssl x509 -noout -hash -in $ca_file)

    if [ -f "/etc/pki/ca-trust/source/anchors/$ca_hash.pem" ]
    then
        err "Certificate already present. #$ca_hash"
        exit
    fi
    
    cat $ca_file_name >  /etc/pki/ca-trust/source/anchors/$ca_hash.pem   
    update-ca-trust
    log "Imported root-certificate $ca_file_name $(openssl x509 -noout -subject -in /etc/pki/ca-trust/source/anchors/$ca_hash.pem)"
    systemctl restart pound.service
    systemctl status pound.service  --no-pager
    
ok
fi # CMD

man '
    Import CA root certificates to be used system-wide. ...
'

fi #isROOT

fi #onHS



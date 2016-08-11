function setup_rootfs_ssh { ## needs rootfs

    if [ -z "$rootfs" ]
    then
        err "No rootfs for setup_rootfs_ssh "
    else
        ## make root's key access
        mkdir -p -m 600 $rootfs/root/.ssh
        cat /root/.ssh/id_rsa.pub > $rootfs/root/.ssh/authorized_keys
        cat /root/.ssh/authorized_keys >> $rootfs/root/.ssh/authorized_keys
        chmod 600 $rootfs/root/.ssh/authorized_keys
        
        ## disable password authentication on ssh
        sed_file $rootfs/etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
    fi
}

function setup_srvctl_ve_dirs { ## needs rootfs

        ## srvctl 2.x installation dir
        mkdir -p $rootfs/var/srvctl
        mkdir -p $rootfs/etc/srvctl
        mkdir -p $rootfs/$install_dir
        rm -rf $rootfs/var/cache/dnf/*

}

function setup_index_html { ## needs rootfs and some name as argument
    
        ## set default index page 
        local _index=$rootfs/var/www/html/index.html
        local _name=$1
        
        save_file $_index '<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>'$_name'</title>
  </head>
<body style="background-color:#333;">
    <div id="header" style="background-color:#222;">
        <p align="center">
            '"$(cat $LOGO_SVG)"'
        </p>
    </div>
        <p align="center">
                <font style="margin-left: auto; margin-right: auto; color: #AAA" size="6px" face="Arial">
                '"$_name @ $HOSTNAME"'
            </font>
        </p>
</body>
</html>
'
        
        cp $LOGO_ICO $rootfs/var/www/html
    
    }

function setup_varwwwhtml_error { ## type, text 
        local _name=$1
        local _text=$2
        local _index=/var/www/html/$_name.html
        
             save_file $_index '<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>ERROR '$_name'</title>
    <style type="text/css"> html, body {overflow: hidden;} </style>
  </head>
<body style="background-color:#333;">
    <div id="header" style="background-color:#222;">
        <p align="center">
            '"$(cat $LOGO_SVG)"'
        </p>
    </div>
        <p align="center">
                <font style="margin-left: auto; margin-right: auto; color: #FFF" size="6px" face="Arial">
                Error '"$_name @ $HOSTNAME"'<br>
                '"$_text"'
                <br>
                <br>
                </font>
                <font style="margin-left: auto; margin-right: auto; color: #555" size="5px" face="Arial">
                ERROR!<br>HIBA!<br>FEHLER!<br>ERREUR!<br>POGREŠKA!<br>ERRORE!<br>FEJL!<br>FOUT!<br>NAPAKA!<br>HATA!<br>
                ERRO!<br>BŁĄD!<br>CHYBA!<br>ПОМИЛКА!<br>EROARE!<br>エラー!<br>VILLA!<br>FEL!<br>LỖI!<br>GRESKA!<br>
                ОШИБКА!<br>错误<br>ข้อผิดพลาด!<br>त्रुटि!<br>កំហុស!<br>ΛΆΘΟΣ!<br>දෝෂය !<br>ХАТО!<br>VIRHE!<br>Kikowaena!<br>IPHUTHA!
            </font>
        </p>
</body>
</html>
'   
        
}


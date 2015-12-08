
msg "User tools"

## maintenance system tools
if [ -z "$(dnf list installed | grep dnf-plugins-system-upgrade)" ]
then
    dnf -y install dnf-plugin-system-upgrade
fi

## vncserver
pmc tigervnc-server vncserver

## hg
pmc mercurial hg

## fdupes   
pmc fdupes
        
## mail
pmc mailx mail

## ratposion
pmc ratpoison

## firefox
pmc firefox



Fedora srvctl v2
==============

## Archive of the deprecated srvctl v2
## srvctl v3 is a complete rewrite that uses systemd-containers

My implementation of a virtual serverfarm manager, controlling the host(s) and some VE's.

srvctl can manage LXC containers on Fedora
- Webserver-farm configuration
- Mailserver-farm configuration
- User access configuration
- CMS installation on containers
.. and so on.

On the serverfarm-host
```
[root@localhost.localdomain /root]# /usr/bin/sc 
# srvctl version 2.2.3
list of currently active commands:
  version                               Display what srvctl version we are using.       
  SERVICE OP | OP SERVICE               start|stop|restart|status a service via systemctl.  +|-|!|?
  reset-install                         This is a developer command - only in debug mode - that will remove all srvctl data including configuration files.
  scan                                  Run scan or phpscan and clamscan to diagnose infections even while the container is offline.
  diagnose                              Run a set of diagnostic commands.               
  add VE [USERNAME(s)]                  Add new LXC container. use the dev. subdomain prefix to create a developer container. 
  backup [VE]                           Backup VE data                                  
  restore VE                            Restore VE based on backup data                 
  exec-all 'CMD [..]'                   Execute a command on all running containers.    
  exec-all-backup-db                    Execute a db backup on all running containers.  
  top                                   Show table of processes on all running containers.
  show-csr VE                           Show the certificate signing request, (CSR) for secure https connections of the VE.
  import-crt [CRT]                      Import a signed certificate for secure https connections of the VE.
  import-ca CRT                         Import a pem format root-certificate file issued from a trusted certificate authority.
  kill VE                               Force a container to stop.                      
  kill-all                              Force all containers to stop.                   
  reboot VE                             Restart a container.                            
  reboot-all                            Restart all containers.                         
  regenerate [all]                      Regenerate configuration files, and restart affected services. (!)
  remove VE                             Remove a container.                             
  start VE                              Start a container.                              
  start-all                             Start all containers and services.              
  status                                Report status of containers.                    
  status-all                            Detailed container status report.               
  usage                                 Container usage status report.                  
  list                                  List containers and their internal IP information.
  stop VE                               Stop a container.                               
  disable VE                            Stop and disable container.                     
  stop-all                              Stop all containers.                            
  update-install [all]                  This will update the current OS to be a srvctl-configured containerfarm host installation.
  add-publickey [keyfile]               Add an ssh-rsa public key.                      
  add-user USERNAME [VE]                Add a new user to the system. Optionally, grant the user access to VE.
  new-password [USERNAME]               Set a new password for user.                    
  update-password [USERNAME]            Update password based on .password file         
  help                                  see more detailed descriptions about commands.  

```

On the guest, the VE
```
[root@test.me /root/srvctl]# /usr/bin/sc
# srvctl version 2.2.3
list of currently active commands:
  version                               Display what srvctl version we are using.       
  SERVICE OP | OP SERVICE               start|stop|restart|status a service via systemctl.  +|-|!|?
  secure-mariadb                        Add a root password, remove test database.      
  mysql [CMD..]                         Enter mariadb/mysql as root, or execute SQL command.
  import-db DATABASE                    Import a mysql database.                        
  add-db DATABASE                       Add a new database.                             
  reset-db-root-passwd                  Reset Database root password.                   
  backup-db [clean]                     Create a backup of the Mysql/MariaDB database, Optionally clean older backups.
  add-phpmyadmin                        Set up phpmyadmin.                              
  update-install [all]                  This will update the current OS to be a srvctl-configured containerfarm host installation.
  add-user USERNAME                     Add a new user to the system.                   
  new-password [USERNAME]               Set a new password for user.                    
  update-password [USERNAME]            Update password based on .password file         
  add-joomla [path]                     Install the latest Joomla!                      
  add-wordpress [path]                  Install Wordpress. Optionally to a folder (URI).
  setup-codepad [apache|node]           Install etherpad and codepad and start a new project. The command setup-codepad-release will use the latest etherpad release instead of git.
  setup-logio                           Install log.io, a web-browser based realtime log monitoring tool.                       
  help                                  see more detailed descriptions about commands.  

```
Hosts can work together to form a cloud-like hosting enviroment.

All bash scripts are made for, and tested on Fedora based systems. Some scripts might eventually work on other distros, with slight modifications, however there are a lot of fodora-specific workarounds and bugfixes in these scripts.

There is an option now to include commands in a plugin-like design. 
Simply create a shell script based on the template.sh and place in the ```/root/srvctl-includes``` directory.

As the software packages under it change, this script is always under construction.
Recommended only for administrators / experts, who know what they do! Use it on your own risk!
If you use or plan to use this script you should contact me for support.

[current srvctl documentation](http://srvctl.d250.hu/)

Installation
```
cd /usr/share
git clone https://github.com/LaKing/srvctl.git
cd /usr/share/srvctl
bash srvctl.sh update-install all
```

Made on codepad. Made in hungary.
    



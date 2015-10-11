Fedora srvctl
==============

My implementation of a virtual serverfarm manager, controlling the host and some VE's.

srvctl can manage LXC containers on Fedora
- Webserver-farm configuration
- Mailserver-farm configuration
- User access configuration
- CMS installation on containers
.. and so on.


As of version 2.0.0 - fedora 21

On the host:
```
[root@localhost.localdomain /root]# /usr/bin/sc 
# srvctl version 2.0.0
list of currently active commands:
  version                               Display what srvctl version we are using.       
  SERVICE OP                            start|stop|restart|status a service via systemctl.  +|-|!|?
  diagnose                              Run a set of diagnostic commands.               
  add VE [USERNAME]                     Add new container.                              
  exec-all 'CMD [..]'                   Execute a command on all running containers.    
  kill VE                               Force all containers to stop.                   
  kill-all                              Force all containers to stop.                   
  reboot VE                             Restart a container.                            
  reboot-all                            Restart all containers.                         
  regenerate [all]                      Regenerate configuration files, and restart affected services.
  remove VE                             Remove a container.                             
  start VE                              Start a container.                              
  start-all                             Start all containers and services.              
  status                                Report status of containers.                    
  status-all                            Detailed container and system health status report.
  stop VE                               Stop a container.                               
  disable VE                            Stop and diable container.                      
  stop-all                              Stop all containers.                            
  update-install [all]                  This will update the srvctl host installation.  
  sec-dns                               Set up as a secondary DNS server                
  add-user USERNAME                     Add a new user to the system.                   
  new-password [USERNAME]               Set a new password for user.                    
  update-password [USERNAME]            Update password based on .password file    
```

On the guest, the VE
```
[root@test.me /root/srvctl]# /usr/bin/sc
# srvctl version 2.0.0
list of currently active commands:
  version                               Display what srvctl version we are using.       
  SERVICE OP                            start|stop|restart|status a service via systemctl.  +|-|!|?
  install-mariadb                       install MariaDB (mysql) database.               
  diagnose                              Run a set of diagnostic commands.               
  sec-dns                               Set up as a secondary DNS server                
  add-user USERNAME                     Add a new user to the system.                   
  new-password [USERNAME]               Set a new password for user.                    
  update-password [USERNAME]            Update password based on .password file         
  add-joomla [path]                     Install the latest Joomla!                      
  add-wordpress [path]                  Install Wordpress. Optionally to a folder (URI).
  setup-codepad [apache|node]           Install ep_codepad, an Etherpad based collaborative code editor, and start a new project.
  setup-logio                           Install log.io, a web-browser based realtime log monitoring tool.

```

All bash scripts are for Fedora based systems.

As the software packages under it change, this script is always under construction.
Recommended only for administrators / experts, who know what they do! Use it on your own risk!
If you use or plan to use this script you should contact me for support.

[current srvctl documentation](http://srvctl.d250.hu/)


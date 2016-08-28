if $onHS && $isROOT
then ## no identation.

## regenerate configs 
hint "restart-services" "Restart all srvctl-managed services. "

if [ "$CMD" == "restart-services" ] || [ "$CMD" == "!!" ]
then        
    restart_services
    ok  
fi          
               
fi ## regenerate

man '
    Srvctl keeps track of important services of the system. 
    This command restarts all of them, and displays if they are active, enabled, or not.
'


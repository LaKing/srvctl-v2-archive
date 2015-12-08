## srvctl command template

if $onVE && $isROOT
then ## no identation.

        hint "do-something [what]" "Dev an empty plugin! "
        if [ "$CMD" == "do-something" ]
        then
            msg "Doing Something!"
            log "Find out what to do."
            err "Nothing to do!"
            msg "Done with nothing!"
        ok
        fi ## do something

fi

man '
    DO something! an empty plugin-like demo.
'


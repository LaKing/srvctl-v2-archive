## phpscan 1.0 - by István Király - LaKing@D250.hu
## detect suspicious files that might have infected PHP based websites

## This script is an independent from srvctl, it can help to detect hacked PHP scripts.
## use the following function to invoke programatically
## source this file, then call phpscan [path] [logfile]
function phpscan {
        
        ## arguments should not contain spaces
        scanpath=$1
        scanlog=$2
        
        if [ -z "$scanpath" ]
        then
            scanpath=/var/www/html
        fi
        
        if [ -z "$scanlog" ]
        then
            scanlog=/var/log/phpscan.log
        fi
        
        if [ -z "$TMP" ]
        then
            TMP=/tmp
        fi

        mkdir -p $TMP
        scanfile=$TMP/srvctl-scan
        
        echo $(date +%Y.%m.%d-%H:%M:%S) > $scanlog
        echo "Scanning $scanpath" >> $scanlog
        

        find $scanpath -type f -name '*.php' > $scanfile 
        
        echo "Scanning PHP files in $scanpath.."
        
        top_file=''
        declare -i top_score=0
        
        declare -i score=0
        declare -i value=0
        declare -i count=0

        ## syntax: test $file $expression $weight
        function test {
            value=0
            value=$(grep -o "$2" "$1" | wc -l)
            score=$(( $score + $value * $3 ))
            if (( $value > 0 )) && (( $3 > 9 ))
            then
                echo -n '!'
                echo "   $value x $2  -- $f" >> $scanlog
            fi
        }
        
        while read f
        do
            if [ ! -f "$f" ]
            then
                continue;
            fi
        
            echo -n "."
            score=0
            
            #test $f 'mail' 1
            #test $f 'fsockopen' 6
            #test $f 'pfsockopen' 6
            #test $f 'stream_socket_client' 6
            #test $f 'exec' 4
            #test $f 'system' 4
            #test $f 'passthru' 4
            #test $f 'preg_replace' 2
            #test $f 'x29' 8
            #test $f 'x3B' 8
            #test $f 'gzinflate' 8             
            #test $f 'root' 1
            #test $f 'iframe' 1            
            
            test "$f" 'eval' 10
            test "$f" 'str_rot13' 10
            test "$f" 'base64_decode' 10
            
            test "$f" 'eval *( *base64_decode *(' 1000
            test "$f" 'eval *( *str_rot13 *( *base64_decode *(' 1000
        
            #echo "score: $score file: $f"
            if (( $score > 100 ))
            then
                echo ''
                echo " ~ $score @ $f "
                
                if (( $score > 1000 ))
                then
                    echo -e "\e[41m HIGH SCORE! @ $f \e[0m"
                    echo "!! $score @ $f" >> $scanlog
                    $(( count++ ))
                else
                    echo " ! $score @ $f" >> $scanlog
                fi                
            fi
            
            if (( $score > $top_score ))
            then
                top_score=$score
                top_file="$f"
            fi
            
        done < $scanfile
        
        if (( $top_score > 0 ))
        then
            echo ''
            echo "->  $top_score @ $top_file" 
        fi
        
        if (( $top_score > 1000 ))
        then
            echo -e "\e[41mDONE. $count SUSPICIOUS PHP FILE(s) FOUND! \e[0m"
        fi
}


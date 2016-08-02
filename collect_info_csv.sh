#! /bin/bash

# PRP Collect_Info CSV v0.2
# Written by Josh Sonstroem on 22 June 2016 for the NSF PRP
# This version outputs to CSV (single line) format

args=0
count=0

while getopts 'm' flag; do
    case "${flag}" in
        m) args='1' ;;
        *) error "Unexpected option ${flag}" ;;
    esac
done

if [ "$#" -gt 0 ]; then
    echo "\"" #--> whoami"
    whoami && date
    echo "\", \"" #--> Server and OS"
    uname -a
    echo "\", \"" #--> CPU Type"
    lscpu
    echo "\", \"" #--> IRQ Balance?"
    service irqbalance status
    echo "\", \"" #--> SYSCTL Settings?"
    sysctl -a | egrep 'wmem|rmem|netdev_max_backlog|cong|timest|somaxconn' | egrep -v 'min|lowmem' 
    echo "\", \"" #--> RC.local?"
    if [ -f /etc/rc.local ]; then
    	cat /etc/rc.local | grep -v \# | egrep -v ^$
    fi
    echo "\", \"" #--> What test suites are running?"
    netstat -anp | egrep '4823|5000|5001|5201' | awk '{print $7 " (" $4 ")" }' | cut -d/ -f2 | grep -v ^-

    for iface in "$@"; do
        count=$(expr $count + 1)
        echo "\", \"--> Interface $count: $iface"
       	ifconfig $iface | egrep -v ^$
       	echo "\", \"" #Interface info for $iface?"
        ethtool -i $iface
        drv=$(ethtool -i $iface | grep driver | awk '{print $2}' | cut -d_ -f1)
        if [[ "$drv" == *"mlx"* ]]; then
            echo "\", \" * --> Detected a Mellanox at $iface!"
            #echo "IRQ Affinity for $iface?"
            show_irq_affinity.sh $iface
            if [ "$args" -eq 1 ]; then
       	        mlnx_tune
            fi
        else
            echo "\", \" * --> Did not detect a Mellanox ($drv) at $iface!"
        fi
        echo "\", \"" #Interrupts for $iface?"
        cat /proc/interrupts | head -1
        drvs=$(cat /proc/interrupts | egrep "$drv" | head -$count | tail -1)
        echo "$drvs"
        cat /proc/interrupts | egrep "$iface"
        echo "\", \""
        ethtool -a $iface | grep -v $iface | egrep -v ^$
        echo "\", \""
        ethtool -c $iface | grep -v $iface | egrep -v ^$
        echo "\", \""
        ethtool -g $iface | grep -v $iface | egrep -v ^$
        echo "\", \""
        ethtool -k $iface | grep -v fixed | grep -v $iface | egrep -v ^$
        echo "\", \""
        ethtool --show-priv-flags $iface | grep -v $iface | egrep -v ^$
    done
echo "\""
else
    ifconfig -a
    echo ""
    echo "--> Choose from the list of available interfaces above..."
    echo ""
    echo "Usage: ./collect_info_csv.sh [-m] IF1 IF2 ... IFn > outfile.csv "
    echo "  -m = run the mlnx_tune script if a mellanox is detected at any interface"
    echo ""
fi

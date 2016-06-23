#! /bin/bash
args=0
count=0

echo "--> Server and OS"
uname -a
echo ""

echo "--> CPU Type"
lscpu
echo ""

echo "--> IRQ Balance?"
service irqbalance status
echo ""

echo "--> SYSCTL Settings?"
sysctl -a | egrep 'wmem|rmem|netdev_max_backlog|cong|timest|somaxconn' | egrep -v 'min|lowmem' 
echo ""

echo "--> RC.local?"
if [ -f /etc/rc.local ]; then
    cat /etc/rc.local | grep -v \#
fi
echo ""

echo "--> What test suites are running?"
netstat -anp | egrep '4823|5000|5001|5201' | awk '{print $7 " (" $4 ")" }' | cut -d/ -f2
echo ""

if [ "$#" -gt 0 ]; then
   for iface in "$@"; do
    count=$(expr $count + 1)
    echo "--> Interface $count: $iface"
    ifconfig $iface
    echo "Interface info for $iface:"
    ethtool -i $iface
    echo ""
    drv=$(ethtool -i $iface | grep driver | awk '{print $2}' | cut -d_ -f1)
    if [[ "$drv" == *"mlx"* ]]; then
        echo " * --> Detected a Mellanox at $iface!"
        echo ""
        echo "IRQ Affinity for $iface:"
        show_irq_affinity.sh $iface
        if [ "$args" -eq 1 ]; then
            mlnx_tune
        fi
    fi
    echo ""
    echo "Interrupts for $iface:"
    cat /proc/interrupts | head -1
    drvs=$(cat /proc/interrupts | egrep "$drv" | head -$count | tail -1)
    echo "$drvs"
    cat /proc/interrupts | egrep "$iface"
    echo ""
    ethtool -a $iface
    ethtool -c $iface
    ethtool -g $iface
    ethtool -k $iface | grep -v fixed
    echo ""
    ethtool --show-priv-flags $iface
    echo ""
    done
else
    echo "--> Choose from available interfaces?"
    ifconfig -a
    echo ""
    echo "Usage: ./collect_info.sh IF1 IF2 ... IFn"
fi

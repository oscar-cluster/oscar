#!/bin/bash
#contributed by Andrei Chevel 
#contributed by Fredrik Steen
#contributed by Gonéri Le Bouder <goneri@free.fr>


TOP=/usr/bin/top
AWK=/bin/awk
GMETRIC=/usr/bin/gmetric
RM=/bin/rm

$TOP -ibn 1 | $AWK /COMMAND/,/++++++++++/ | head -2 | tail -1 > /tmp/t$$

$GMETRIC --name UserTime  --value `$AWK '{print($11)}' /tmp/t$$`  --type string  --units 'min:sec'
$GMETRIC --name UserProg  --value `$AWK '{print($12)}' /tmp/t$$`  --type string  --units 'name'
$GMETRIC --name UserCPU   --value `$AWK '{print($9)}'  /tmp/t$$`  --type float   --units '%'
$GMETRIC --name UserTime  --value `$AWK '{print($11)}' /tmp/t$$`  --type string  --units 'min:sec'

$RM -f /tmp/t$$

NBRE=1
# For each network interface
for i in `cat /proc/net/dev | grep eth | wc -l`
do
        NBRE=`expr $NBRE - 1`
INTERFACE=eth$NBRE

OUT=`grep $INTERFACE /proc/net/dev | awk -F\: '{print($2)}' | awk '{print($9)}'`
IN=`grep $INTERFACE /proc/net/dev | awk -F\: '{print($2)}' | awk '{print($1)}'`

sleep 1

let OUT=(`grep $INTERFACE /proc/net/dev | awk -F\: '{print($2)}' | awk '{print($9)}'`-$OUT)
let IN=(`grep $INTERFACE /proc/net/dev | awk -F\: '{print($2)}' | awk '{print($1)}'`-$IN)

$GMETRIC --name "$INTERFACE out"  --value $OUT --type uint32 --units 'b/s'

$GMETRIC --name "$INTERFACE in"  --value $IN --type uint32 --units 'b/s'


$GMETRIC -t uint16 -n TCP_ESTABLISHED -v `/bin/netstat -t -n|egrep "ESTABLISHED"|wc -l`

done

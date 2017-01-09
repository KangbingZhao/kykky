#!/bin/bash
BASEDIR=/mnt/us/extensions/metrics
YOUNGEST=`cat /var/local/log/metrics_generic_youngest`
OLDEST=`cat /var/local/log/metrics_generic_oldest`

if [ -e $BASEDIR/etc/metrics_generic_current ]; then
	CURRENT=`cat $BASEDIR/etc/metrics_generic_current`
	if [ $CURRENT -lt $OLDEST ]; then
		date >>  $BASEDIR/log/log.txt
		echo WARNNING: Data maybe lost:cur $CURRENT old $OLDEST >> $BASEDIR/log/log.txt
		CURRENT=$OLDEST
	fi
	if [ $CURRENT -gt $YOUNGEST ]; then
		exit 0
	fi
else
	date >> $BASEDIR/log/log.txt
	echo INFO: Create metrics_generic_current >> $BASEDIR/log/log.txt
	CURRENT=$OLDEST
fi

while [ $CURRENT -le $YOUNGEST ]
do
	FILE=`echo $CURRENT | awk '{printf "/var/local/log/metrics_generic_%08d*", $1}'`
	zcat $FILE | grep reader.activeDuration | awk 'BEGIN{FS=","}{print $2,$7}' \
	>> $BASEDIR/log/metrics_generic_result
	CURRENT=`expr $CURRENT + 1 |awk '{printf "%08d", $1}'`
done
	                                        
echo $CURRENT > $BASEDIR/etc/metrics_generic_current

exit 0

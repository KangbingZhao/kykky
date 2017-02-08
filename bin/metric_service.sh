#!/bin/bash
BASEDIR=/mnt/us/extensions/kykky
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
	# here add the book opening and closing message to \
	# metric_generic_result_open(opening msg) and
	# metric_generic_result_close(closing msg)
	# first column: time, second column: ASIN=***
	zcat $FILE |grep EndActions,BookClose,HasNetwork |awk 'BEGIN{FS=","}{print $2,$9}' \
	>> $BASEDIR/log/metrics_generic_result_close
	zcat $FILE |grep EndActions,BookOpen,HasNetwork |awk 'BEGIN{FS=","}{print $2,$9}' \
	>> $BASEDIR/log/metrics_generic_result_open
 

	CURRENT=`expr $CURRENT + 1 |awk '{printf "%08d", $1}'`
done
	                                        
echo $CURRENT > $BASEDIR/etc/metrics_generic_current


# here start collecting the book opening and closing msg from /var/log/messages 
# and /var/local/messages
# the process seems just the same as above 
YOUNGEST_M=`cat /var/local/log/messages_youngest`
OLDEST_M=`cat /var/local/log/messages_oldest`
if [ -e $BASEDIR/etc/metrics_generic_current_M ]; then
	CURRENT_M=`cat $BASEDIR/etc/metrics_generic_current_M`
	if [ $CURRENT_M -lt $OLDEST_M ]; then
		date >>  $BASEDIR/log/log_M.txt
		echo WARNNING: Data maybe lost:cur $CURRENT_M old $OLDEST_M >> $BASEDIR/log/log_M.txt
		CURRENT_M=$OLDEST_M
	fi
	if [ $CURRENT_M -gt $YOUNGEST_M ]; then
		exit 0
	fi
else
	date >> $BASEDIR/log/log_M.txt
	echo INFO: Create metrics_generic_current_M >> $BASEDIR/log/log_M.txt
	CURRENT_M=$OLDEST_M
fi
while [ $CURRENT_M -le $YOUNGEST_M ]
do
	FILE=`echo $CURRENT_M | awk '{printf "/var/local/log/messages_%08d*", $1}'`
	zcat $FILE | grep ReaderInfo | awk 'BEGIN{FS=","}{print $1,$3,$6,$7,$8}' \
	>> $BASEDIR/log/metrics_generic_result_M
	# $1,$3,$6,$7,$8
	# asin,modified time(created time),length,last time,last positiom
	# asin,size,modified time,type,lang,length,access time,last position,
	CURRENT_M=`expr $CURRENT_M + 1 |awk '{printf "%08d", $1}'`
done
echo $CURRENT_M > $BASEDIR/etc/metrics_generic_current_M


exit 0

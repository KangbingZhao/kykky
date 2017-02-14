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

while [ $CURRENT -lt $YOUNGEST ]
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
#由于metrics_generic不断被压缩并追加到YOUNGEST中，
#每次把以YOUNGEST内容覆盖temp
if [ $CURRENT -eq $YOUNGEST ]; then
	FILE=`echo $CURRENT | awk '{printf "/var/local/log/metrics_generic_%08d*", $1}'`
	zcat $FILE | grep reader.activeDuration | awk 'BEGIN{FS=","}{print $2,$7}' \
	> $BASEDIR/log/metrics_generic_temp
fi

	                                        
echo $CURRENT > $BASEDIR/etc/metrics_generic_current
exit 0

#!/bin/bash
BASEDIR=/mnt/us/extensions/metrics
TOTAL=0
TODAY=0
TODAYTIME=`date +%s -d 00:00`

mkfifo -m 777 tpipe
cat $BASEDIR/log/metrics_reader_* |
awk 'BEGIN{FS=","}{print $2,$7}' > tpipe

while read ENDTIME DURATION
do
	DURATION=$((DURATION/1000))
	TOTAL=$((TOTAL+DURATION))
	#①...... □ □ □ □ □ □ □ □ □ □ 00:00 ......  today +=  0
	#②...... □ □ □ □ □ 00:00 ■ ■ ■ ■ ■ ......  today +=  5
	#③...... 00:00 ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ......  today += 10	
	if [[ $((ENDTIME-DURATION)) -gt $TODAYTIME ]]; then  #③
		TODAY=$((TODAY+DURATION))
	else
		if [[ $ENDTIME -gt $TODAYTIME ]]; then           #②
			TODAY=$((TODAY+ENDTIME-TODAYTIME))
		fi
	fi
done < tpipe

rm -f tpipe

usleep 150000
eips 13 30 "`printf "Total:%4dH %02dM %02dS" $((TOTAL/3600)) $((TOTAL%3600/60)) $((TOTAL%60))`"
usleep 150000
eips 13 32 "`printf "Today:%4dH %02dM %02dS" $((TODAY/3600)) $((TODAY%3600/60)) $((TODAY%60))`"

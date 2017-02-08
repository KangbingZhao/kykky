#!/bin/bash
BASEDIR=/mnt/us/extensions/kyky
TOTAL=0
TODAY=0
TODAYTIME=`date +%s -d 00:00`

analyze()
{
	while read ENDTIME DURATION TEMP
	do
		STARTTIME=$((ENDTIME-DURATION/1000)) 
		DURATION=$((DURATION/1000))
		TOTAL=$((TOTAL+DURATION))
	
		if [[ $STARTTIME -gt $TODAYTIME ]]; then
			TODAY=$((TODAY+DURATION))
		else
			if [[ $((STARTTIME+DURATION)) -gt $TODAYTIME ]]; then
				TODAY=$((TODAY+STARTTIME+DURATION-TODAYTIME))
			fi
		fi
	done < $1
}

./metric_service.sh

if [ -e $BASEDIR/log/metrics_generic_result ]; then
	analyze $BASEDIR/log/metrics_generic_result
fi

cat /var/log/metrics_generic | grep reader.activeDuration | awk 'BEGIN{FS=","}{print $2,$7}' \
	> $BASEDIR/log/metrics_generic_temp
	
analyze $BASEDIR/log/metrics_generic_temp

usleep 150000
eips 13 30 "`printf "Total:%4dH %02dM %02dS" $((TOTAL/3600)) $((TOTAL%3600/60)) $((TOTAL%60))`"
usleep 150000
eips 13 32 "`printf "Today:%4dH %02dM %02dS" $((TODAY/3600)) $((TODAY%3600/60)) $((TODAY%60))`"

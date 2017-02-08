#!/bin/bash
BASEDIR=/mnt/us/extensions/kyky
TOTAL=0
TODAY=0
WEEK=0
MONTH=0
TODAYTIME=`date +%s -d 00:00`
WEEKTIME=$((TODAYTIME-(`date +%w`-1)*24*60*60)) #星期一零点
MONTHTIME=$((TODAYTIME-(`date +%e` -1)*24*60*60)) #本月1号零点
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
		if [[ $STARTTIME -gt $WEEKTIME ]]; then
			WEEK=$((WEEK+DURATION))
		else
			if [[ $((STARTTIME+DURATION)) -gt $WEEKTIME ]]; then
				WEEK=$((WEEK+STARTTIME+DURATION-WEEKTIME))
			fi
		fi
		if [[ $STARTTIME -gt $MONTHTIME ]]; then
			MONTH=$((MONTH+DURATION))
		else
			if [[ $((STARTTIME+DURATION)) -gt $MONTHTIME ]]; then
				MONTH=$((WEEK+STARTTIME+DURATION-MONTHTIME))
			fi
		fi
	done < $1
}
analyze_reading_progress()
{
	while read line
	do
		asin=$(expr "$line" : '.*asin=\(.*\)\sfile.*')
		length=$(expr "$line" : '.*MobiPosition_\s\(.*\)\saccess')
		last_position=$(expr "$line" : '.*SerializedPosition_\s\(.*\)\s.*')
		last_time=$(expr "$line" : '.*access=\(.*\)\s+')
		last_time=${last_time//./:}
		last=`date -d "$last_time" +%s` #unix时间戳
	done < $1
}

./metric_service.sh

if [ -e $BASEDIR/log/metrics_generic_result ]; then
	analyze $BASEDIR/log/metrics_generic_result
fi

cat /var/log/metrics_generic | grep reader.activeDuration | awk 'BEGIN{FS=","}{print $2,$7}' \
	> $BASEDIR/log/metrics_generic_temp
	
analyze $BASEDIR/log/metrics_generic_temp


#开始统计最近阅读书籍，只保留本月/本周/今天三种

eips 13 34 "`printf "Today:%4dH %02dM %02dS" $((TODAY/3600)) $((TODAY%3600/60)) $((TODAY%60))`"
usleep 150000
eips 13 36 "`printf "Week :%4dH %02dM %02dS" $((WEEK/3600)) $((WEEK%3600/60)) $((WEEK%60))`"
usleep 150000
eips 13 38 "`printf "Month:%4dH %02dM %02dS" $((MONTH/3600)) $((MONTH%3600/60)) $((MONTH%60))`"
usleep 150000
eips 13 40 "`printf "Total:%4dH %02dM %02dS" $((TOTAL/3600)) $((TOTAL%3600/60)) $((TOTAL%60))`"

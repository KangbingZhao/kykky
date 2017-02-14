#!/bin/bash
BASEDIR=/mnt/us/extensions/kykky
TOTAL=0
YESTERDAY=0
TODAY=0
WEEK=0
MONTH=0
TODAYTIME=`date +%s -d 00:00`
YESTERDAYTIME=$((TODAYTIME-24*60*60))
WEEKTIME=$((TODAYTIME-((`date +%w`+6)%7)*24*60*60)) #星期一零点
MONTHTIME=$((TODAYTIME-(`date +%e` -1)*24*60*60)) #本月1号零点


mkfifo -m 777 tpipe
cat $BASEDIR/log/metrics_reader_* |
awk 'BEGIN{FS=","}{print $2,$7}' > tpipe

while read ENDTIME DURATION
do
	DURATION=$((DURATION/1000))
	STARTTIME=$((ENDTIME+DURATION))
	TOTAL=$((TOTAL+DURATION))
	#①...... □ □ □ □ □ □ □ □ □ □ 00:00 ......  today +=  0
	#②...... □ □ □ □ □ 00:00 ■ ■ ■ ■ ■ ......  today +=  5
	#③...... 00:00 ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ......  today += 10	
	if [[ $STARTTIME -gt $TODAYTIME ]]; then  #③
		TODAY=$((TODAY+DURATION))
		#今天开始今天结束
	else #今天之前开始
		if [[ $ENDTIME -gt $TODAYTIME ]]; then           #②
			TODAY=$((TODAY+ENDTIME-TODAYTIME))
			YESTERDAY=$((YESTERDAY+TODAYTIME-STARTTIME))
			#昨天开始今天结束
		fi
		if [[ $STARTTIME -gt $YESTERDAYTIME ]] ; then  #③
			if [[ $ENDTIME -lt $TODAYTIME ]]; then
				YESTERDAY=$((YESTERDAY+DURATION))
			fi
		else
			if [[ $ENDTIME -gt $YESTERDAYTIME ]]; then           #②
				YESTERDAYT=$((YESTERDAY+ENDTIME-YESTERDAYTIME))
			fi
		fi 

	fi
	if [[ $STARTTIME -gt $WEEKTIME ]]; then  #③
		WEEK=$((WEEK+DURATION))
	else
		if [[ $ENDTIME -gt $WEEKTIME ]]; then           #②
			WEEK=$((WEEK+ENDTIME-WEEKTIME))
		fi
	fi
	if [[ $STARTTIME -gt $MONTHTIME ]]; then  #③
		MONTH=$((MONTH+DURATION))
	else
		if [[ $ENDTIME -gt $MONTHTIME ]]; then           #②
			MONTH=$((MONTH+ENDTIME-MONTHTIME))
		fi
	fi

done < tpipe

rm -f tpipe

today_result=`printf "Today :%4dH %02dM %02dS" $((TODAY/3600)) $((TODAY%3600/60)) $((TODAY%60))`
yesterday_result=`printf "Ystday:%4dH %02dM %02dS" $((YESTERDAY/3600)) $((YESTERDAY%3600/60)) $((YESTERDAY%60))`
week_result=`printf "Week  :%4dH %02dM %02dS" $((WEEK/3600)) $((WEEK%3600/60)) $((WEEK%60))`
month_result=`printf "Month :%4dH %02dM %02dS" $((MONTH/3600)) $((MONTH%3600/60)) $((MONTH%60))`
total_result=`printf "Total :%4dH %02dM %02dS" $((TOTAL/3600)) $((TOTAL%3600/60)) $((TOTAL%60))`
eips 13 34 "$today_result"
usleep 150000
eips 13 36 "$yesterday_result"
usleep 150000
eips 13 38 "$week_result"
usleep 150000
eips 13 40 "$month_result"
usleep 150000
eips 13 42 "$total_result"
usleep 150000
echo $total_result,$today_result,`date` >>$BASEDIR/log/debug_total_today.log
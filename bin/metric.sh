#!/bin/bash
BASEDIR=/mnt/us/extensions/kykky
bash $BASEDIR/bin/metric_service.sh

TOTAL=0
YESTERDAY=0
TODAY=0
WEEK=0
MONTH=0
TODAYTIME=`date +%s -d 00:00`
YESTERDAYTIME=$((TODAYTIME-24*60*60))
WEEKTIME=$((TODAYTIME-(`date +%w`-1)*24*60*60)) #星期一零点
MONTHTIME=$((TODAYTIME-(`date +%e` -1)*24*60*60)) #本月1号零点
analyze() # 阅读时间统计
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
			if [[ $STARTTIME -gt $YESTERDAYTIME ]]; then
				YESTERDAY=$((YESTERDAY+DURATION))
			else
				if [[ $((STARTTIME+DURATION)) -gt $YESTERDAYTIME ]]; then
					YESTERDAY=$((YESTERDAY+STARTTIME-YESTERDAYTIME+DURATION))
				fi
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
get_reading_info() #从每行message中提取数据
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
# get_book_info() #获取本地书籍ASIN与中文名对应信息
# {
# }
# analyze_reading_progress()
# {
# }

if [ -e $BASEDIR/log/metrics_generic_result ]; then
	analyze $BASEDIR/log/metrics_generic_result
fi

#把未压缩metrics_generic记录追加到temp，与youngest合并
cat /var/log/metrics_generic | grep reader.activeDuration | awk 'BEGIN{FS=","}{print $2,$7}' \
	>> $BASEDIR/log/metrics_generic_temp
	
analyze $BASEDIR/log/metrics_generic_temp


#开始统计最近阅读书籍，只保留本月/本周/今天三种
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
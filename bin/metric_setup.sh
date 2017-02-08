#!/bin/sh

## enable
metric_enable()
{
	cat /etc/crontab/root |grep metrics_service.sh
	if [ $? -eq 1 ] ; then
		mntroot rw
		echo "*/30 * * * * /mnt/us/extensions/kyky/bin/metric_service.sh " >> /etc/crontab/root
		mntroot ro
	fi
	touch ./etc/enable
}

## disable
metric_disable()
{
	mntroot rw
	sed -i '/metric_service.sh/d' /etc/crontab/root
	mntroot ro
	rm -f ./etc/enable
}


## reset
metric_reset()
{
	rm -f ./log/*
	rm -f ./etc/metrics_generic_current
	rm -f ./etc/metrics_generic_current_M
	usleep 150000
	eips 15 35 "Reset success"
	usleep 1000000
	eips 15 35 "             "
}

## Main
case "$1" in
	"enable" )
		metric_enable
	;;
	"disable" )
		metric_disable
	;;
	"reset" )
		metric_reset
	;;
	* )
	;;
esac

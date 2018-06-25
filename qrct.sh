#！/bin/bash

show_usage()
{
	echo "$0                  Following nothing will stop the application and start using wmi fw"
	echo "$0 revert           This command will revert the fw file and restart the application"
	echo "$0 -h               Show this help message"
}

revert_fw()
{
	cd /lib/firmware
	cp wil6210.fw.back ./wil6210.fw
	killall host_manager_11ad
	rmmod wil6210
	insmod /lib/modules/4.1.35-rt41/extra/wil6210.ko
	echo "host_manager_11ad killed"
	echo "restarting the application"
	echo "======================================"
	restart_appli
}

if [ "$1" = "-h" ];then
	show_usage
	exit 1
fi

if [ "$1" = 'revert' ];then
	revert_fw
	exit 1
fi

start_appli stop

rmmod wil6210.ko
echo "wil6210.ko removed"
cd /data
ls /lib/firmware/wil6210.fw.back > /dev/null 2>&1  #Decide whether we have stored fw.back or not
if [ $? != 0 ];then
    cp /lib/firmware/wil6210.fw /lib/firmware/wil6210.fw.back
    echo "operating fw saved as wil6210.fw.back"
fi
cp wil6210_sparrow_plus_ftm.fw /lib/firmware/wil6210.fw
insmod /lib/modules/4.1.35-rt41/extra/wil6210.ko
killall host_manager_11ad
host_manager_11ad &
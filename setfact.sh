#!/bin/bash
#a shortcut tool made by Hyy

check_debug()
{
        while [ 1 ] 
        do
                echo "show debug $1 in every 2 seconds"
                echo "============================================="
                d $1
                sleep 2
                clear
        done
}

check_integer()
{
        expr $1 + 0&>/dev/null
        [ $? -ne 0 ] && { echo "Domain must be integer!";exit 1; }
}

restart_application()
{
        echo "#########################################"
        echo "Restarting the application as requested"
        restart_appli
}
show_HWID()
{
        echo "##########################################"
        echo "#HWID 0 = AP  1 = HoU  2 = ExtensionAP   #"
        echo "##########################################"
        cat /config/HWID
        echo "##########################################"
        echo "Reset As Factory Load ($1) Successful"
}

ap_working()
{
        check_integer $1
        reset_config
        echo DOMAIN=$1 >> /config/headap-1
        echo DL_LIST=relayap-1 hou-1 >> /config/headap-1
        echo BB_FW=wil6210.fw >> /config/headap-1
        echo BB1_BRDFILE=SWL14R3_2x1_Hpole.brd >> /config/headap-1
        echo BB2_BRDFILE=SWL-W14_Diversity_3x1_XIF_4_5_6_10E14736.brd >> /config/headap-1
        echo BB3_BRDFILE=SWL14R3_2x1_Hpole.brd >> /config/headap-1
        echo BB1_AUTORECOVERY=disable >> /config/headap-1
        echo BB2_AUTORECOVERY=disable >> /config/headap-1
        echo BB3_AUTORECOVERY=disable >> /config/headap-1
        echo BLUETOOTH=enable >> /config/headap-1
}
relay_working()
{
        check_integer $1
        reset_config
        echo DOMAIN=$1 >> /config/relayap-1
        echo UL_DEV=headap-1 >> /config/relayap-1
        echo UL_BB=wlan0 >> /config/relayap-1
        echo DHCPSERVER_IP=10.1.3.1 >> /config/relayap-1
        echo BB_FW=wil6210.fw >> /config/relayap-1
        echo BB1_BRDFILE=wil6210_SWL-W14_1x1_102F1004.brd >> /config/relayap-1
        echo BB2_BRDFILE=W14_diversity_3x1_10E14732.brd >> /config/relayap-1
        echo BB3_BRDFILE=wil6210_SWL-W14_1x1_102F1004.brd >> /config/relayap-1
        echo BB1_AUTORECOVERY=enable >> /config/relayap-1
        echo BB2_AUTORECOVERY=enable >> /config/relayap-1
        echo BB3_AUTORECOVERY=enable >> /config/relayap-1
        echo BLUETOOTH=enable >> /config/relayap-1
}

hou_working()
{
        check_integer $1
        reset_config
        echo DOMAIN=$1 >> /config/hou-1
        echo UL_DEV=headap-1 >> /config/hou-1
        echo BB_FW=wil6210.fw >> /config/hou-1
        echo BB1_BRDFILE=wil6210.brd >> /config/hou-1
        echo BB1_AUTORECOVERY=enable >> /config/hou-1
        echo BLUETOOTH=enable >> /config/hou-1
}

enable_sfp()
{
        echo "##############enabling sfp############"
        wpontest sfp enable > /dev/null
        wpontest sfp switch > /dev/null
}

write_serialN()
{
        echo "######################################"
        echo "Writing serial number to device"
        wpontest ri w 601=##$1####
        echo "serial number is written"
        echo "######################################"
        wpontest ri r 601
}

sys_command()
{
        $1
        if [ "$?" -ne "0" ];then
                echo "failed... exiting"
                exit 1
        fi
}

set_factory_load()
{
        reset_config
        env_appli set APPLI_FACTORY_PRECONFIG YES  #set hardware to factory mode
        sys_command env_appli
        echo HWID=$1 >/config/HWID  #SET HWID
}

show_help()
{
        echo "Usage: $0 HoU [restart]"
        echo "       $0 HeadAP/RelayAP [restart]"
        echo "       $0 ExtensionAP [restart]"
        echo "       $0 serialnumber <serialnumber> [restart]"
        echo "       $0 WorkHeadAP [restart]"
        echo "       $0 WorkHoU domain [restart]"
        echo "       $0 WorkRelayAP domain [restart]"
        echo "       $0 cl (checklog)"
        echo "       $0 read certname"
        echo "       $0 d number  ex: tool d 3 "
        exit 1
}

reset_config()
{
        cd /config
        mv -f /config/etc /data
        mv -f /config/cert /data
        mv /config/ca.pem /data
        mv /config/client.key /data
        mv /config/client.pem /data
        rm -rf *
        mv -f /data/etc /config
        mv -f /data/cert /config
        mv /data/ca.pem /config
        mv /data/client.key /config
        mv /data/client.pem /config
        ls -l /config/etc > /dev/null
        if [ $? -ne 0 ];then
                echo "clear conf failed, exiting"
        fi
        echo "#####################################################"
        echo "# Successfully removed configuration in the /config #"
        echo "#####################################################"
}

#############main##################
########SET ENVIRON###########
if [ "$0" = "./tool" ] || [ "$0" = "/data/tool" ];then
        cp /data/tool /usr/bin
fi

if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 3 ] || [ "$1" = "-h" ];then
        show_help
fi

if [ "$1" = "read" ];then
        openssl x509 -in $2 -inform pem -noout -text
        exit 1
fi

if [ "$1" = "d" ];then
        check_debug $2
        exit 1
fi

if [ "$1" = "serialnumber" ];then
        write_serialN $2
        if [ "$3" = "restart" ];then
        echo "#########################################"
        echo "Restarting the application as requested"
        sys_command restart_appli
        exit 1
        fi
        exit 1
fi
if [ "$1" = "cl" ];then
        cd /rmem
        optf_read messages | grep CallH > log ; tail -n 50 log
        exit 1
fi

if [ "$1" = "reset" ];then
        exit 1
fi

if [ "$1" = "HoU" ];then
        set_factory_load 1
        show_HWID $1
elif [ "$1" = "HeadAP" ];then
        set_factory_load 0
        show_HWID $1
elif [ "$1" = "RelayAP" ]; then
        set_factory_load 0
        show_HWID $1
elif [[ "$1" = "ExtensionAP" ]]; then
        set_factory_load 2
        show_HWID $1
elif [[ "$1" = "WorkHeadAP" ]]; then
        ap_working $2
        echo "Successfully set as $1"
elif [[ "$1" = "WorkRelayAP" ]]; then
        relay_working $2
        echo "Successfully set as $1"       
elif [[ "$1" = "WorkHoU" ]]; then
        hou_working $2
        echo "Successfully set as $1"       
else
        show_help
fi

if [ "${!#}" = "restart" ];then
        restart_application
fi

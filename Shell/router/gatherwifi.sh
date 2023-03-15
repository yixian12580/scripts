#!/bin/sh
#####################################################################
####      Notice: This script is used to gather wifi hosts.      ####
####                      By Jazz Chen                           ####
#####################################################################

###路由命令
CURLCMD="/usr/sbin/curl"
EGREPCMD="/bin/egrep"
AWKCMD="/usr/bin/awk"
DIFFCMD="/usr/bin/diff"
PINGCMD="/bin/ping"
WCCMD="/usr/bin/wc"
ECHOCMD="/bin/echo"
MVCMD="/bin/mv"
SERVICECMD="/sbin/service"
MKDIRCMD="/bin/mkdir"

###环境变量
HOST="172.31.0.117"

###DNS服务路径
BASEDIR="/jffs/configs"
DNSFILE="${BASEDIR}/dnsmasq.d/dnsmasq.conf.add"
TEMPDIR="${BASEDIR}/temp"
TIME=`date +%Y%m%d%H%M` 
TODAY=`date +%Y%m%d`
LOGFILE="${TEMPDIR}/log.${TODAY}"

#1.测试能否连接wiki
pingtest(){
    $PINGCMD -c 2 -w 2 $HOST >/dev/null 
	if [ $? -eq 0 ];then
		PINGREV=1
	else
		PINGREV=0
	fi
}

#2.获取对应的URL
geturl(){
    case $1 in
	    jingyu-test)
		     URL="http://172.31.0.117:4300/host-test.txt"
			 ;;
	    jingyu-yufa)
		     URL="http://172.31.0.117:4300/host-yufa.txt"
			 ;;
	    jingyu-test2)
		     URL="http://172.31.0.117:4300/host-test2.txt"
			 ;;
		dreame-test)
		     URL="http://172.31.0.117:4300/host-dreame-test.txt"
			 ;;
		oversea-test)
		     URL="http://172.31.0.117:4300/host-oversea-test.txt"
			 ;;
	    oversea-yufa)
		     URL="http://172.31.0.117:4300/host-oversea-yufa.txt"
			 ;;
		*)
		     usage
			 ;;
	esac		

}

#3.尝试获取hosts
gethosts(){
    if [ ! -d ${TEMPDIR}/${TODAY} ];then
	    $MKDIRCMD -p ${TEMPDIR}/${TODAY}
	fi
	HOSTSNUM=`$CURLCMD -s $URL | $EGREPCMD -v "^(#|$)" | $AWKCMD '{printf "address=/%s/%s\n", $2, $1}'| $WCCMD -l `
	if [ $HOSTSNUM -gt 0 ];then
		$CURLCMD -s $URL | $EGREPCMD -v "^(#|$)" | $AWKCMD '{printf "address=/%s/%s\n", $2, $1}' > ${TEMPDIR}/${TODAY}/hosts.${TIME}
	fi
}


usage(){
    echo "Usage: $0 [jingyu|dreame|oversea] [test|yufa|test2]."
}


#主程序
echo "============Exec script on: `date +'%Y%m%d %H:%M:%S'`============" >> ${LOGFILE} 
if [ $# -eq 2 ];then
    pingtest
	if [ $PINGREV == 1 ];then
	    case $1 in 
		    jingyu)
			    env="jingyu-$2"
				;;
		    dreame)
			    env="dreame-$2"
				;;
			oversea)
			    env="oversea-$2"
				;;
			*)
			    usage
				;;
		esac
		
		geturl $env 
		gethosts
		
		if [ -f ${TEMPDIR}/${TODAY}/hosts.${TIME} ];then
		    $DIFFCMD $DNSFILE ${TEMPDIR}/${TODAY}/hosts.${TIME} >/dev/null
			if [ $? -eq 0 ];then
			    echo "Hosts didn't change, exit now." >> ${LOGFILE}
				exit 10
			else
			    $MVCMD $DNSFILE ${TEMPDIR}/${TODAY}/hosts.bak.${TIME}
				$MVCMD ${TEMPDIR}/${TODAY}/hosts.${TIME} ${DNSFILE}
				if [ -f ${DNSFILE} ];then
				    echo "Prepare to restart dnsmasq.d on $TIME." >> ${LOGFILE}
				    $SERVICECMD restart_dnsmasq 
					if [ $? -eq 0 ];then
					    echo "Restart dnsmasq.d successful." >> ${LOGFILE}
						exit 0
				    fi
				else
				    echo "Cannot find dns file, exit now." >> ${LOGFILE}
					exit 9
				fi
		    fi
		fi
	else
	    echo "Cannot communicate with $HOST, check your network first." >> ${LOGFILE}
		exit 8
	fi
else
    usage
    exit 7
fi	



#!/bin/bash
#

LogDir="/usr/local/nginx/logs"
DateDir=`date +%Y%m%d`
FileName="collect_ficfun_com.log collect_dreame_com.log"
PidFile="${LogDir}/nginx.pid"
OldDate=`date -d '30 days ago' +%Y%m%d`

for filename in ${FileName};do

	LogFile="${LogDir}/${filename}"
	LogName=`echo "${filename%.*}"`


	if [ "`date +%H`" = "00" ];then
	    DateDir=`date -d 'yesterday' +%Y%m%d`
	fi

	logtime=`date +%Y%m%d%H --date="-1 hour"`
	/bin/mkdir -p ${LogDir}/${DateDir}
	/bin/mv ${LogFile} ${LogDir}/${DateDir}/${LogName}_${logtime}.log
	kill -USR1 `cat ${PidFile}`
done

cd $LogDir && rm -rf ${OldDate}
#!/bin/bash
############################################
# Description: This script is used to cut  #
#              nginx logs.                 #
# Author: Jazz Chen                        #
############################################

LogsPath=/usr/local/nginx/logs
BakDir=/data/backup/nginx_logs
PidFile=/usr/local/nginx/logs/nginx.pid
Yesterday=`date -d 'yesterday' +%F`
OLDDATE=`date -d '15 days ago' +%F`


#[ ! -d ${BakDir} ] && mkdir -p ${BakDir}

[ ! -d ${BakDir}/${Yesterday} ] && mkdir -p ${BakDir}/${Yesterday} || rm -rf ${BakDir}/${Yesterday}/* 
if [ ! -d ${LogsPath} ];then
     echo "Cannot find nginx log path."
     exit 1
else 
     cd ${LogsPath}
	     for log in `ls *.log`;do
		 mv ${LogsPath}/${log} ${BakDir}/${Yesterday}/
	         kill -USR1 `cat $PidFile`
	         sleep 1
	         cd ${BakDir}/${Yesterday}/
                 tar -zcf ${log}.tar.gz $log
                 rm -rf $log
             done
     chown -R nginx.nginx ${LogsPath}

     # 检查并删除过期的日志文件
     cd ${BakDir} && rm -rf ${OLDDATE}
fi

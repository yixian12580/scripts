#!/bin/bash
############################################
# Description: This script is used to cut  #
#              php error log.              #
# Author: Jerry Zhao                       #
# Date: 2017-03-27 15:24:46                #
############################################


LogsPath=/usr/local/php/var/log
BakDir=/data/backup/php_logs
PidFile=/usr/local/php/var/run/php-fpm.pid
Yesterday=`date -d 'yesterday' +%F`
OLDDATE=`date -d '7 days ago' +%F`


[ ! -d ${BakDir}/${Yesterday} ] && mkdir -p ${BakDir}/${Yesterday} || rm -rf ${BakDir}/${Yesterday}/* 
if [ ! -d ${LogsPath} ];then
     echo "Cannot find php log path."
     exit 1
else
    cd ${LogsPath}
         for i in `ls *.log`
	     do 
		     mv ${LogsPath}/$i ${BakDir}/${Yesterday}
             kill -USR1 `cat ${PidFile}`
			 sleep 1
			 cd ${BakDir}/${Yesterday}
			 tar -zcf $i.tar.gz $i 
			 rm -rf $i
	     done
 		 
     cd ${BakDir} && rm -rf ${OLDDATE}
fi

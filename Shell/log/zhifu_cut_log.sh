#!/bin/bash
############################################
# Description: This script is used to cut  #
#              zhifu logs.                 #
# Author: Jazz Chen                        #
############################################

LogsPath=/home/q/system/vmoney/logs
BakDir=/data/backup/zhifu/logs
Yesterday=`date -d 'yesterday' +%Y%m%d`
OLDDATE=`date -d '30 days ago' +%Y%m%d`

[ -d ${BakDir}/${Yesterday} ] && rm -rf ${BakDir}/${Yesterday}
mkdir -p ${BakDir}/${Yesterday}

if [ ! -d ${LogsPath} ];then
     echo "Cannot find zhifu log path."
     exit 1
else
     cd ${LogsPath}
	     find ${LogsPath} -type f -name "*${Yesterday}*" -a -name '*log*'  > target_list
		 ListLines=`cat target_list |wc -l`
		 if [ ${ListLines} -eq 0 ];then
		     echo "no log files found match your selection. Quit now."
			 exit 9
		 else 
             for i in `cat target_list`
                do
                   mv $i ${BakDir}/${Yesterday}/
             done
	         cd ${BakDir}/${Yesterday}/
                 tar -zcf ${Yesterday}.tar.gz *
		     #find . -type f ! -name *.tar.gz |xargs rm -rf
         fi	    
     cd ${BakDir} && rm -rf ${OLDDATE}
fi

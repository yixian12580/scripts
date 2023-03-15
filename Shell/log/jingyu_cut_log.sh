#!/bin/bash
############################################
# Description: This script is used to cut  #
#              jingyu_front php logs.      #
# Author: Jazz Chen                       #
############################################

LogsPath=/home/q/system/jingyu/front/logs/pc
BakDir=/data/backup/jingyu_front/logs
Yesterday=`date -d 'yesterday' +%Y%m%d`
OLDDATE=`date -d '15 days ago' +%Y%m%d`

[ -d ${BakDir}/${Yesterday} ] && rm -rf ${BakDir}/${Yesterday}
mkdir -p ${BakDir}/${Yesterday}

if [ ! -d ${LogsPath} ];then
     echo "Cannot find jingyu_front log path."
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
		     find . -type f ! -name *.tar.gz |xargs rm -rf
         fi	    
     cd ${BakDir} && rm -rf ${OLDDATE}
fi

#!/bin/bash
#

RemoteSrv="ec2-54-208-212-64.compute-1.amazonaws.com"
Port=22
User=fetch
RemoteDir="/usr/local/nginx/logs"
DateDir=`date -u +%Y%m%d`
CMD="/usr/bin/scp"
tag=`date -u +%Y%m%d%H --date="-1 hour"`

###定义要拉取日志的项目名称，如果有新项目加入，添加到这个数组即可
ProjectName="ficfun dreame"

###定义一个执行scp拉取的function
scpExec(){

	if [ "`date -u +%H`" = "00" ];then
	    DateDir=`date -u -d 'yesterday' +%Y%m%d`
	fi

	if [ ! -d ${LocalDir}/${DateDir} ];then
	    mkdir -p ${LocalDir}/${DateDir}
	fi


	FileCheck=`/usr/bin/ssh -p 22 ${User}@${RemoteSrv} "[ -f ${RemoteDir}/${DateDir}/${File} ] && echo yes || echo no"`
	if [ "${FileCheck}" == "yes" ];then

	    $CMD -P ${Port} ${User}@${RemoteSrv}:${RemoteDir}/${DateDir}/${File} ${LocalDir}/${DateDir}/

	        if [ -f ${LocalDir}/${DateDir}/${File} ];then
	            echo "Scp collect log successful."
	        else
	            echo "Scp collect log failed."
	        fi

	else

	    echo "Cannot find log file to handle on remote server."

	fi

}




for proj in ${ProjectName};do
	FileAttr="collect_${proj}_com"
	File="${FileAttr}_${tag}.log"
    LocalDir="/data/collect/oversea/${proj}"

    if [ ! -d ${LocalDir} ];then
    	mkdir -p ${LocalDir}
    fi

    scpExec

done



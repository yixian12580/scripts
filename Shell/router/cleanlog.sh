#!/bin/sh
#####################################################################
####  Notice: This script is used to clean wifi hosts temp file. ####
####                      By Jazz Chen                           ####
#####################################################################

###DNS服务路径
BASEDIR="/jffs/configs"
TEMPDIR="${BASEDIR}/temp"
TIME=`date +%Y%m%d%H%M`
TODAY=`date +%Y%m%d`
let YESTERDAY=TODAY-1
LOGFILE="${TEMPDIR}/clean.log"

if [ -d ${TEMPDIR} ];then
    echo "================`date +'%Y%m%d %H:%M:%S'` :Begin to clean logs================"
    cd ${TEMPDIR}
        /bin/rm -rf ${YESTERDAY}
        /bin/rm -f log.${YESTERDAY}
        echo "================`date +'%Y%m%d %H:%M:%S'` :Clean logs ended.==============="
fi
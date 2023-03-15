#!/bin/bash
#This script is used to back up ldap replication log.
#Only need to run on ldap master node
#Created by Jazz Chen

YESTERDAY=`date -d yesterday +%F`
BAK_DIR=/storage/backup/ldap_log
LOG_FILE=/var/log/ldap.log
OLDDATE=`date -d '15 days ago' +%F`


[ ! -d $BAK_DIR ] && mkdir -p $BAK_DIR
[ -d $BAK_DIR/${YESTERDAY} ] && rm -rf $BAK_DIR/${YESTERDAY}
mkdir -p $BAK_DIR/${YESTERDAY}

echo "========================================="
echo "LDAP log backup start on $(date +%F' '%T)"
cat ${LOG_FILE} > $BAK_DIR/${YESTERDAY}/ldap_rep.log 
if [ $? -eq 0 ];then
     > ${LOG_FILE}
	 echo "Backup ldap replication log successful."
else
     echo "Backup ldap replication log failed."
	 exit 1
fi

cd $BAK_DIR && rm -rf ${OLDDATE}

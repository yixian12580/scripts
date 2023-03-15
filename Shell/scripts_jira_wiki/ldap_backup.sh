#!/bin/bash
#This script is used to back up ldap data
#Created by Jazz Chen

YESTERDAY=`date -d yesterday +%F`
BAK_DIR=/storage/backup/ldap
OLDDATE=`date -d '7 days ago' +%F`


[ ! -d $BAK_DIR ] && mkdir -p $BAK_DIR
[ -d $BAK_DIR/${YESTERDAY} ] && rm -rf $BAK_DIR/${YESTERDAY}
mkdir -p $BAK_DIR/${YESTERDAY}

echo "========================================="
echo "LDAP backup start on $(date +%F)"
/usr/bin/ldapsearch -x -b "dc=chuangyue,dc=com" > $BAK_DIR/${YESTERDAY}/ldap.bak_${YESTERDAY}
[ $? -eq 0 ] && echo "Backup ldap data successful." || echo "Backup ldap data failed."

cd $BAK_DIR && rm -rf ${OLDDATE}

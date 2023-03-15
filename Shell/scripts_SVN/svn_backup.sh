#!/bin/bash
#This script is used to back up svn data
#Created by Jazz Chen

YESTERDAY=`date -d yesterday +%F`
BAK_DIR=/storage/backup/svn
OLDDATE=`date -d '7 days ago' +%F`
SVN_DATA_DIR=/storage/svndata


[ ! -d $BAK_DIR ] && mkdir -p $BAK_DIR
[ -d $BAK_DIR/${YESTERDAY} ] && rm -rf $BAK_DIR/${YESTERDAY}
mkdir -p $BAK_DIR/${YESTERDAY}
cd $SVN_DATA_DIR
echo "SVN data backup start on $(date +%F' '%T)"
echo "========================================="
for i in `ls`
   do 
       tar -zcf $i.tar.gz $i
       mv $i.tar.gz $BAK_DIR/${YESTERDAY}/
       [ $? -eq 0 ] && echo "Repo $i backup successful." || echo "Repo $i backup failed."
done

cd $BAK_DIR && rm -rf ${OLDDATE}
echo "========================================="
echo "SVN data backup ended on $(date +%F' '%T)."	   
echo "#########################################"

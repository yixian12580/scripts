#!/bin/bash
#This script is used to back up confluence data
#Created by Jazz Chen

YESTERDAY=`date -d yesterday +%F`
BAK_DIR=/storage/backup/confluence_bak
OLDDATE=`date -d '7 days ago' +%F`
SOURCE_DIR=/storage


[ ! -d $BAK_DIR ] && mkdir -p $BAK_DIR
[ -d $BAK_DIR/${YESTERDAY} ] && rm -rf $BAK_DIR/${YESTERDAY}
mkdir -p $BAK_DIR/${YESTERDAY}
cd $SOURCE_DIR
echo "Confluence data backup start on `date +%F' '%T`"
echo "========================================="
for i in `ls |grep confluence`
   do 
       tar -zcf $i.tar.gz $i
       mv $i.tar.gz $BAK_DIR/${YESTERDAY}/
       [ $? -eq 0 ] && echo "$i backup successful." || echo "$i backup failed."
done

cd $BAK_DIR && rm -rf ${OLDDATE}
echo "========================================="
echo "Confluence data backup ended on `date +%F' '%T`."	   
echo "#########################################"

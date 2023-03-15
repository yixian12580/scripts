#!/bin/bash
#

MYSQL_ROOT_DIR=/usr/local/mysql
MYSQL_EXEC=$MYSQL_ROOT_DIR/bin/mysql
MYSQLDUMP_EXEC=$MYSQL_ROOT_DIR/bin/mysqldump 
MYSQL_USER=dbbackup
MYSQL_PASSWD=backup
DBNAMES=`${MYSQL_EXEC} -h 127.0.0.1 -u${MYSQL_USER} -p${MYSQL_PASSWD} -e "show databases;"|grep -Ev "^Database|information_schema|performance_schema|test"`
YESTERDAY=`date -d yesterday +%F`
OLDDATE=`date -d '7 days ago' +%F`
BAK_DIR=/storage/backup/mysql


[ ! -d $BAK_DIR ] && mkdir -p $BAK_DIR
[ -d $BAK_DIR/$YESTERDAY ] && rm -rf $BAK_DIR/$YESTERDAY
mkdir -p $BAK_DIR/$YESTERDAY


echo "MySQL database backup start on $(date +%F' '%T)"
echo "========================================="

for i in ${DBNAMES} 
   do 
       ${MYSQLDUMP_EXEC} --opt -h 127.0.0.1 -u${MYSQL_USER} -p${MYSQL_PASSWD} $i | gzip > ${BAK_DIR}/${YESTERDAY}/$i.sql.gz
	   [ $? -eq 0 ] && echo "Backup database $i successful." || echo "Backup database $i failed."
       sleep 5
done


	${MYSQLDUMP_EXEC} --opt -h 127.0.0.1 -u${MYSQL_USER} -p${MYSQL_PASSWD} --all-databases  | gzip > ${BAK_DIR}/${YESTERDAY}/alldatabase_${YESTERDAY}.sql.gz   
    [ $? -eq 0 ] && echo "Backup all databases successful." || echo "Backup all databases failed."

cd $BAK_DIR && rm -rf ${OLDDATE}

echo "========================================="
echo "MySQL database backup ended on $(date +%F' '%T)."	   
echo "#########################################"

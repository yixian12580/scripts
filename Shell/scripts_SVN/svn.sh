#!/bin/bash
#####################################
##Created on Sep 1st by Jazz Chen
#####################################
SvnPath=/storage/svndata/
#SvnPort=`netstat -tunlp|grep svnserve|awk '{print $4}'|cut -d: -f2`
start(){
   ps -ef|grep svnserve|grep -v grep >>/dev/null 2>&1
   if [ $? -ne 0 ];then
      svnserve -d -r $SvnPath 
      ps -ef|grep svnserve|grep -v grep >>/dev/null 2>&1
      [ $? -eq 0 ] && echo "SVN server started successful."
   else
      SvnPort=`netstat -tunlp|grep svnserve|awk '{print $4}'|cut -d: -f2`
      echo "SVN server is already running(Port:$SvnPort)..."
      exit 1
   fi 
}
stop(){
   ps -ef|grep svnserve|grep -v grep >>/dev/null 2>&1
   if [ $? -eq 0 ];then
      pkill svnserve >>/dev/null 2>&1
      echo "SVN server stopped successful."
   else
      echo "SVN server is not running."
      exit 127
   fi   
}
status(){
   ps -ef|grep svnserve|grep -v grep >>/dev/null 2>&1
   [ $? -eq 0 ] && echo "SVN server is running." ||echo "SVN server is stopped."
}
 
case "$1" in
   start)
      start
   ;;
   stop)
      stop
   ;;
   restart)
      stop
      start
   ;;
   status)
      status
   ;;
   *)
      echo "Usage:$0 {start|stop|restart|status}"
      exit 1
   ;;
esac

#!/bin/bash
#############################################################
#Description: Openldap install script for CentOS 6.x        #
#Tips: You will asked to input a valid domain name and set  #
#      password for the administrator in your domain.       #
#Usage: bash openldap_install.sh                            #
#Author: Jazz Chen                                          #
#############################################################
openldap_install(){
     #检查openldap是否已经安装
     ps -ef|grep slapd |grep -v grep >/dev/null 
 [ $? -eq 0 ] && echo "Service slapd is running, exit now." && exit 1 
 [ -x /etc/init.d/slapd ] && echo "Openldap was installed on this server, nothing will do." && exit 1 
      
     #准备操作
     [ -d /etc/openldap ] && rm -rf /etc/openldap/*
 [ -d /var/lib/ldap ] && rm -rf /var/lib/ldap/*
     echo "*/5 * * * * /usr/sbin/ntpdate  time.nist.gov >/dev/null 2>&1" >>/var/spool/cron/root 
       
  
     #配置yum源
 mkdir -p /etc/yum.repo.d/bak_$(date +%F) 
     mv /etc/yum.repo.d/*.* /etc/yum.repo.d/bak_$(date +%F) 2>/dev/null
     wget -q -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo 
     yum clean all >/dev/null
     yum makecache >/dev/null 
  
  
 #安装openldap软件包
 yum -y install openldap openldap-servers openldap-clients openldap-devel 1>/dev/null 2>/dev/null 
     [ $? -ne 0 ] && echo "Install openldap package failed." && exit 1 || echo "Install openldap package successful."
  
  
 #生成slapd.conf和DB_CONFIG文件
     if [ -d /etc/openldap ];then
     [ ! -f /usr/share/openldap-servers/slapd.conf.obsolete ] && echo "Can't find file /usr/share/openldap-servers/slapd.conf.obsolete." && exit 1 || cp /usr/share/openldap-servers/slapd.conf.obsolete /etc/openldap/slapd.conf
 cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
 chown ldap:ldap /var/lib/ldap/DB_CONFIG
     cp -a /etc/openldap/slapd.d /etc/openldap/slapd.d.bak$(date +%F)
     else
         echo -e "Directory [/etc/openldap] didn't found."
         exit 1
     fi 
  
  
     #检测slapd能否正常启动
 /etc/init.d/slapd start >/dev/null 
 [ $? -ne 0 ] && echo "Service slapd start failed, please check your system." && exit 1 || echo "Service slapd start successful."
 rm -rf /etc/openldap/slapd.d/*
  
   
 #编辑slapd.conf文件     
 while [ "$PassWord" == "" ];do 
 read -p "Please input the password for the administrator in your domain:" PassWord 
 done
 slappasswd -s $PassWord |sed -s 's/^/rootpw                /g' >>/etc/openldap/slapd.conf 
  
 sed -i '/^checkpoint/s/^/#/' /etc/openldap/slapd.conf 
     sed -i 's/Manager/admin/g' /etc/openldap/slapd.conf
     sed -i "s/dc=my-domain,dc=com/$DomainCN/g"/etc/openldap/slapd.conf
     echo -e "# add some settings on $(date +%F)\nloglevel         296\ncheckpoint       2048  10\ncachesize        1000\n" >>/etc/openldap/slapd.conf
  
  
 #配置rsyslog记录ldap日志
 [ -f /etc/rsyslog.conf ] && cp /etc/rsyslog.conf /etc/rsyslog.conf.bak$(date +%F)
 echo 'local4.*             /var/log/ldap.log' >>/etc/rsyslog.conf
 /etc/init.d/rsyslog restart >/dev/null 
 [ $? -ne 0 ] && echo "Change settings of rsyslog failed." && exit 1 || echo "Change settings of rsyslog successful."
  
  
 #启动slapd服务
 slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d  >/dev/null
 [ $? -ne 0 ] && echo "Slaptest with configure file failed." && exit 1 || echo "Slaptest with configure file successful."
 chown -R ldap:ldap /etc/openldap/slapd.d 
     chmod -R 700 /etc/openldap/slapd.d
 chkconfig slapd on 
 /etc/init.d/slapd restart >/dev/null 
 lsof -i :389 >/dev/null
 [ $? -ne 0 ] && echo "Start slapd service failed." && exit 1 || echo "Start slapd service successful." && exit 0
}
while true; do
     read -p "Please input your domain name:"  DomainName 
 #检测用户输入的域名格式，如果为空则重新输入
     if [ "$DomainName" != "" ];then
     PotNum=`echo $DomainName |awk -v RS=. 'END{print --NR}'`
 #检测用户输入的域名格式，只能有1个或2个"."，子域名的形式暂不考虑
 case $PotNum in 
                 1|2)
     DomainKey1=`echo $DomainName |awk -F"." '{print $1}'`
 DomainKey2=`echo $DomainName |awk -F"." '{print $NF}'`
 #检测用户输入的域名格式，其中域名不能以.号开头和结尾，其实域名应该
 #也不能以数字结尾，域名中只能包含-而不能包含其他特殊字符，但是这里的
 #判断实在是不能尽善，所以只能简单的作了判断，留待以后再做改善
 if [[ -n $DomainKey1  &&  -n $DomainKey2 ]] ;then
  
                         DomainCN=`echo $DomainName |sed 's/\./,/g'|sed 's/^/dc=/g'|sed 's/,/,dc=/g'`
         openldap_install
 else 
     echo "Invalid domain name, the correct format should be like: a.com, a.com.cn,etc."
 fi
             ;;
             *)
                 echo "Invalid domain name, the correct format should be like: a.com, a.com.cn,etc."
             ;;
         esac  
     else 
     echo -e "DomainName can not be empty, please input again."
     fi 
done

#!/bin/bash 
#############################################
#The script is used to optimize the CentOS 6.x.
#created by Jerry12356 on May 16th, 2016
#############################################

disable_ctrl_alt_delete(){
sed -i '/shutdown/s/^/#/' /etc/init/control-alt-delete.conf 
grep "^exec" /etc/init/control-alt-delete.conf
[ $? -ne 0 ] && echo -e "\033[1;32mDisable Ctrl+Alt+Del to shutdown the server successful.\033[0m"
}

time_sync(){
     
    #time sync
    echo -e  "0 * * * * /usr/sbin/ntpdate   210.72.145.44 64.147.116.229 time.nist.gov" >> /var/spool/cron/root
    echo -e  "/usr/sbin/ntpdate  time.nist.gov 210.72.145.44 64.147.116.229" >> /etc/rc.local
    echo -e "\033[1;32mTime sync successful.\033[0m"
}

yum_install(){
    #安装开发组件、运行库
    yum -y install gcc gcc-c++ gcc-devel gcc-c++-devel wget make cmake curl finger nmap tcp_wrappers expect lrzsz unzip zip ntpdate lsof telnet vim tree > /dev/null 2>&1 
    if [ $? -eq 0 ];then
        echo -e "\033[1;32mInstall softwares successful.\033[0m"
    fi
}

kernel_optimize(){
cat >> /etc/sysctl.conf << EOF
fs.file-max = 262144
fs.nr_open = 262144
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 4096 65000
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 81920
net.ipv4.tcp_max_tw_buckets = 6000
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216 
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2 
net.ipv4.tcp_mem = 94500000 91500000 92700000
net.ipv4.tcp_max_orphans = 3276800
EOF
/sbin/sysctl -p
     
    echo -e "\033[1;32mKernel optimized successful.\033[0m"
}

addusers(){
    #添加普通用户，并设置sudo权限（不建议使用admin作为用户名）
    useradd -u 603 -g users cuser
    echo 'cuser:CYadmin@u7i8o9'|chpasswd
    sed -i '/^root/acuser   ALL=(ALL)       ALL ' /etc/sudoers
     
    #以下为服务用户，如有相关服务，可以一并添加
    useradd -u 605 -M zabbix -s /sbin/nologin
    echo -e "\033[1;32mAdd users successful.\033[0m"
}

history_setting(){
    #设置history历史记录
    sed  -i "/mv/aalias vi='vim'"  /root/.bashrc
 
    sed -i "/HISTSIZE/s/1000/50/g" /etc/profile
    echo -e 'export  HISTTIMEFORMAT="`whoami` : %F %T :"' >> /etc/profile
    source /etc/profile
     
    echo -e "\033[1;32mSetting history successful.\033[0m"
}

ssh_config(){
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak$(date +%F)
sed -i '/#Port 22/aPort 37021' /etc/ssh/sshd_config
sed -i '/PermitRootLogin/s/yes/no/' /etc/ssh/sshd_config
sed -i '/#PermitEmptyPasswords/aPermitEmptyPasswords no' /etc/ssh/sshd_config
grep 37021 /etc/ssh/sshd_config >/dev/null
[ $? -eq 0 ] && echo -e "\033[1;32mConfig ssh service successful.\033[0m"
}
 
hostname_change(){
    OldName=`grep -i hostname /etc/sysconfig/network |cut -d"=" -f2`
    read -p "Please input a new hostname: " NewName
    sed -i "/HOSTNAME/s/$OldName/$NewName/" /etc/sysconfig/network
    hostname $NewName
    echo -e "\033[1;32mChange hostname successful.\033[0m"
}
 
 
 
 
 
disable_ctrl_alt_delete 
time_sync
yum_install
kernel_optimize 
addusers 
history_setting 
ssh_config 
hostname_change 

echo -e "\033[1;32m\nAll of the operations were done, please reboot to make them took effect.\033[0m"

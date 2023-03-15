#!/bin/bash
#

############格式化数据盘#############
PartionNum=`fdisk -l |grep "/dev/vdb" |wc -l`
if [ $PartionNum -eq 1 ];then
     echo -e "n\np\n1\n\n\nw\n" |fdisk /dev/vdb 
	 mkfs.ext4 /dev/vdb1
else
     echo "Can't find the disk to operate."
	 exit 1
fi

mkdir -p /storage
mount /dev/vdb1 /storage 
echo "/dev/vdb1               /storage                ext4    defaults        0 0" >>/etc/fstab
	 

##############创建并挂载swap分区#####################
dd if=/dev/zero of=/storage/swap bs=1024 count=4096000
mkswap /storage/swap
sysctl -w vm.swappiness=60
sed -i '/swappiness/s/0/60/' /etc/sysctl.conf 
sysctl -p
swapon /storage/swap
echo "/storage/swap           swap                    swap    defaults        0 0" >>/etc/fstab 


#####创建/opt/tools目录##################
[ ! -e /storage/tools ] && mkdir -p /storage/tools	
ln -s /storage/tools/ /opt/tools

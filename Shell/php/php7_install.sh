#!/bin/bash
#
# Description: This script is used to install php.
# Created by Jazz Chen.
#

source /etc/profile
PackageDir=/opt/tools

# 安装依赖包
yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel openldap openldap-devel nss_ldap openldap-clients openldap-servers >/dev/null
yum -y install gd-devel libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel curl-devel  >/dev/null



# 创建安装包存放路径
[ ! -d ${PackageDir} ] && mkdir -p ${PackageDir} && cd ${PackageDir}


# 安装libiconv
cd ${PackageDir}
[ -f libiconv-1.14.tar.gz ] && rm -rf libiconv-1.14.tar.gz
[ -d libiconv-1.14 ] && rm -rf libiconv-1.14
wget -q http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar -zxf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local >/dev/null 2>/dev/null 1>/dev/null
if [ $? -eq 0 ]; then
     make && make install >/dev/null 2>/dev/null
	 [ $? -eq 0 ] && echo -e "\033[1;32mInstall libiconv successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install libiconv failed.\033[0m"
else 
     echo -e "\033[1;31mSome errors occured during configure libiconv.\033[0m"
     exit 9
fi

	 
# 安装libmcrypt
cd ${PackageDir}
[ -f libmcrypt-2.5.8.tar.gz ] && rm -rf libmcrypt-2.5.8.tar.gz
[ -d libmcrypt-2.5.8 ] && rm -rf libmcrypt-2.5.8
wget -q http://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
tar -zxf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
     make && make install >/dev/null 2>/dev/null 1>/dev/null
	 [ $? -eq 0 ] && echo -e "\033[1;32mInstall libmcrypt successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install libmcrypt failed.\033[0m"
else
     echo -e "\033[1;31mSome errors occured during configure libmcrypt.\033[0m"
	 exit 8
fi
# 安装libltdl
/sbin/ldconfig 
cd libltdl 
./configure --enable-ltdl-install >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
     make && make install >/dev/null 2>/dev/null 1>/dev/null
	 [ $? -eq 0 ] && echo -e "\033[1;32mInstall libltdl successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install libltdl failed.\033[0m"
else
     echo -e "\033[1;31mSome errors occured during configure libltdl.\033[0m"
	 exit 7
fi


# 安装mhash
cd ${PackageDir}
[ -f mhash-0.9.9.9.tar.gz ] && rm -rf mhash-0.9.9.9.tar.gz
[ -d mhash-0.9.9.9 ] && rm -rf mhash-0.9.9.9
wget -q http://nchc.dl.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
tar -zxf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9
./configure >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
     make && make install >/dev/null 2>/dev/null 1>/dev/null
	 [ $? -eq 0 ] && echo -e "\033[1;32mInstall mhash successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install mhash failed.\033[0m"
else
     echo -e "\033[1;31mSome errors occured during configure mhash.\033[0m"
	 exit 6
fi



# 创建lib库软连接
ln -s /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
ln -s /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
ln -s /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
ln -s /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
ln -s /usr/local/lib/libmhash.a /usr/lib/libmhash.a
ln -s /usr/local/lib/libmhash.la /usr/lib/libmhash.la
ln -s /usr/local/lib/libmhash.so /usr/lib/libmhash.so
ln -s /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
ln -s /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config
/sbin/ldconfig


# 安装mcrypt
cd ${PackageDir}
[ -f mcrypt-2.6.8.tar.gz ] && rm -rf mcrypt-2.6.8.tar.gz
[ -d mcrypt-2.6.8 ] && rm -rf mcrypt-2.6.8
wget -q https://nchc.dl.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
tar -zxf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8
/sbin/ldconfig
./configure >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
     make && make install >/dev/null 2>/dev/null 1>/dev/null
     [ $? -eq 0 ] && echo -e "\033[1;32mInstall mcrypt successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install mcrypt failed.\033[0m"
else
     echo -e "\033[1;31mSome errors occured during configure mcrypt.\033[0m"
	 exit 5
fi

# 安装libzip1.2
cd ${PackageDir}
[ -f libzip-1.2.0.tar.gz ] && rm -rf libzip-1.2.0.tar.gz
[ -d libzip-1.2.0 ] && rm -rf libzip-1.2.0
wget -q https://nih.at/libzip/libzip-1.2.0.tar.gz
tar -zxf libzip-1.2.0.tar.gz
cd libzip-1.2.0
./configure >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
     make && make install >/dev/null 2>/dev/null 1>/dev/null
     [ $? -eq 0 ] && echo -e "\033[1;32mInstall libzip successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install libzip failed.\033[0m"
else
     echo -e "\033[1;31mSome errors occured during configure libzip.\033[0m"
     exit 15
fi

# 指定zipconf声明文件路径
cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h

# 添加搜索路径到配置文件
echo '/usr/local/lib64
/usr/local/lib
/usr/lib
/usr/lib64' >> /etc/ld.so.conf
# 更新配置
/sbin/ldconfig -v



# 创建php用户
useradd -u 607 -s /sbin/nologin www
[ $? -eq 0 ] && echo -e  "\033[1;32mPHP user www added.\033[0m" || echo -e "\033[1;31mAdd php user failed.\033[0m"


# 安装PHP
PVERSION=7.3.4
cd ${PackageDir}
[ -f php-${PVERSION}.tar.gz ] && rm -rf php-${PVERSION}.tar.gz
[ -d php-${PVERSION} ] && rm -rf php-${PVERSION}
#wget -q http://cn2.php.net/distributions/php-${PVERSION}.tar.gz
wget -q http://ftp.ntu.edu.tw/php/distributions/php-7.3.4.tar.gz
tar -zxf php-${PVERSION}.tar.gz 
cd php-${PVERSION}
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-libxml-dir \
--enable-xml \
--enable-fpm \
--with-fpm-user=www \
--with-fpm-group=www \
--enable-bcmath \
--enable-mbstring \
--enable-sockets \
--enable-mysqlnd \
--enable-opcache \
--enable-session \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--enable-mysqlnd-compression-support \
--enable-inline-optimization \
--with-gd \
--with-bz2 \
--with-zlib \
--enable-zip \
--with-mhash \
--with-openssl \
--with-xmlrpc \
--with-iconv-dir \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--without-pear \
--disable-phar \
--with-pcre-regex \
--disable-ipv6 \
--with-gettext \
--disable-debug \
--without-pdo-sqlite \
--disable-rpath \
--enable-shmop \
--enable-sysvsem \
--with-curl \
--enable-mbregex \
--enable-pcntl \
--enable-soap \
--enable-sigchild \
--enable-pdo   

if [ $? -eq 0 ]; then
     make ZEND_EXTRA_LIBS='-liconv' 
	 if [ $? -eq 0 ]; then
	     make install 
		 [ $? -eq 0 ] && echo -e "\033[1;32mInstall php${PVERSION} successful.\033[0m" || echo -e "\033[1;31mSome errors occured, install php${PVERSION} failed.\033[0m"
	 else
	     echo -e "\033[1;31mSome errors occured during make php${PVERSION}.\033[0m"
		 exit 4
	 fi
else
     echo -e "\033[1;31mSome errors occured during configure php${PVERSION}.\033[0m"
	 exit 3
fi
	 

# 添加php到环境变量
echo -e 'PATH=$PATH:/usr/local/php/bin:/usr/local/php/sbin' >> /etc/profile
source /etc/profile


# 创建php-fpm配置文件
cd /usr/local/php/etc/
[  -e php-fpm.conf ] && mv php-fpm.conf php-fpm.conf.bak$(date +%F)
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

# 生成php.ini文件
[ -e /etc/php.ini ] && mv /etc/php.ini /etc/php.ini.bak$(date +%F)
cp ${PackageDir}/php-${PVERSION}/php.ini-production /etc/php.ini


# 配置php-fpm启动脚本并添加开机启动
[ -e /etc/init.d/php-fpm ] && mv /etc/init.d/php-fpm /etc/init.d/php-fpm.bak$(date +%F)
cp ${PackageDir}/php-${PVERSION}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 755 /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig --list|grep php-fpm >/dev/null
if [ $? -eq 0 ]; then
     echo -e "\033[1;32mAdd php-fpm into chkconfig list successful.\033[0m" || echo -e "\033[1;31mAdd php-fpm into chkconfig list failed.\033[0m"
     chkconfig php-fpm on 
     chkconfig --list|grep 3:on|grep php >/dev/null
	 if [ $? -eq 0 ];then
	     echo -e "\033[1;32mChange php-fpm status to on in chkconfig list successful.\033[0m"
	 else
	     echo -e "\033[1;31mChange php-fpm status to on in chkconfig list failed.\033[0m"
	 fi
else
     echo -e "\033[1;31mAdd php-fpm into chkconfig list failed.\033[0m"
fi

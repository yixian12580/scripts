#!/bin/bash
#

Basedir=/usr/local/nginx
prog=/usr/local/nginx/sbin/nginx
Nginx_Version=1.6.3

check_nginx(){
     #nginx_process=`ps -ef|grep nginx|egrep -v grep|wc -l`
     nginx_process=`ps -ef|grep nginx|egrep -v grep|wc -l`
     #echo $nginx_process
	 if [ ${nginx_process} -gt 0 ];then
	     echo "Nginx is running, exit now."
             exit 1
	 else
	     [ -d ${Basedir} -a -x $prog ] && echo "Nginx has been installed on this server." && exit 3
         fi		 
}

libs_install(){
yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb krb5-devel libidn libidn-devel openssl openssl-devel make gcc-c++ cmake bison-devel ncurses-devel  pcre-devel zlib-devel make >/dev/null 
if [ $? -ne 0 ];then
     echo "Some error occured during install necessary libaries, please check."
else 
     echo "Install necessary libaries successful."
fi
}

nginx_install(){
     id nginx >/dev/null
	 [ $? -ne 0 ] && useradd -u 602 nginx  -M -s /sbin/nologin 
	 
	 [ -d ${Basedir}/tmp/ ] && rm -rf ${Basedir}/tmp/
	 mkdir -p /usr/local/nginx/tmp/{client,proxy,fcgi}
	 
	 [ ! -d /opt/tools ] && mkdir -p /opt/tools 
         cd /opt/tools
	 wget -q http://nginx.org/download/nginx-${Nginx_Version}.tar.gz
	 tar -zxf nginx-${Nginx_Version}.tar.gz
     cd nginx-${Nginx_Version}
     ./configure \
         --prefix=/usr/local/nginx \
         --user=nginx \
         --group=nginx \
         --with-http_ssl_module \
         --with-http_gzip_static_module \
         --http-client-body-temp-path=/usr/local/nginx/tmp/client/ \
         --http-proxy-temp-path=/usr/local/nginx/tmp/proxy/ \
         --http-fastcgi-temp-path=/usr/local/nginx/tmp/fcgi/ \
         --with-poll_module \
         --with-file-aio \
         --with-http_realip_module \
         --with-http_addition_module \
         --with-http_random_index_module \
         --with-pcre \
         --with-http_stub_status_module \
         --http-uwsgi-temp-path=/usr/local/nginx/uwsgi_temp \
         --http-scgi-temp-path=/usr/local/nginx/scgi_temp
	 if [ $? -ne 0 ];then
	     echo "Some error occured during the configuration."
		 exit 127
	 else 
	     make && make install
	     [ $? -eq 0 ] && echo "Install Nginx successful." || echo "Install Nginx failed."	 
             chown -R nginx. ${Basedir}
	     exit 0
     fi 
	
}


while true; do
cat << EOF
#############################################################
##      This script is used to install Nginx ${Nginx_Version}.        ##
##           Do you want to continue? (Yes or No)          ##
#############################################################
EOF
     read -p "Please give your choice: "  CHOICE
	 case $CHOICE in
	     Yes|YES|Y|y)
		     check_nginx
			 libs_install
             nginx_install
		 ;;
		 No|NO|N|n)
		     echo "Thanks for using, bye."
			 exit 9
		 ;;
		 *)
		     echo "You should give your choice."
		 ;;
	 esac
done

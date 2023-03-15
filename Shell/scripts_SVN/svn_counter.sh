#! /bin/bash
# 计算有效变更代码量的脚本
#./svnCount -thttps://192.168.1.1/xxx -s1000 -e2000 -uxxx -pxxx
version() {
        OS=`uname -o`
        echo "Source_counter ($OS) 0.0.1"
        echo "  tony bai (http://tonybai.com)"
}

usage() {
        echo "usage: source-counter [-t SVN_REPOSITORY_URL] [-s START_REVISION]"
        echo "                      [-e END_REVISION] [-u USER_NAME]"
        echo "                      [-p PASSWD]"
        echo "       source-counter [-v|-h]"
        echo 
        echo "        -t,                 目标SVN库地址"
        echo "        -s,                 起始修订号"
        echo "        -e,                 结束修订号"
        echo "        -u,                 svn帐号"
        echo "        -p,                 svn密码"
        echo "        -h,                 帮助"
        echo "        -v,                 版本信息"
        echo "        -a,                 提交者"
}

if [ $# -lt 2 ]; then
        usage
        exit 1 
fi

while getopts "t:s:e:u:p:a:vh" opt; do
        case $opt in
                t) target=$OPTARG;;
                s) start_revision=$OPTARG;;
                e) end_revision=$OPTARG;;
                u) user=$OPTARG;;
                p) passwd=$OPTARG;;
                a) author=$OPTARG;;
                v) version; exit 1;;
                h) usage; exit 1;;
        esac
done

if [ -z $target ]; then
        echo "请输入目标SVN库地址!"
        exit 1
fi

if [ -z $start_revision ]; then
        echo "请输入起始修订号!"
        exit 1
fi

if [ -z $end_revision ]; then
        echo "请输入终止修订号!"
        exit 1
fi

TEMPFILE=temp.log
USERNAME=${user:-}
PASSWD=${passwd:-}

if [ -z $author ];then
    svn diff -r$start_revision:$end_revision $target > $TEMPFILE
    #去掉含空格的空行
    add_lines_count=`grep "^+" $TEMPFILE | grep -v "^+++" | sed 's/^.//'| sed s/[[:space:]]//g |sed '/^$/d'|wc -l`
    echo "the actually incremental source code lines = $add_lines_count"
    /bin/rm -rf $TEMPFILE
else
    revs=`svn log -q $target -r $start_revision:$end_revision --username $USERNAME --password $PASSWD |awk '{print \$1,\$3}'|grep ${author}|awk '{print $1}'|sed 's/r//g'`
    for rev in ${revs};do 
        last_rev=$((rev-1))
        svn diff -r ${last_rev}:${rev} $target --username $USERNAME --password $PASSWD > $TEMPFILE 
        count=`grep "^+" $TEMPFILE |grep -v "^+++" |sed 's/^.//'|sed 's/[[:space:]]//g'|sed '/^$/d'|wc -l`
        #count=`grep "^+" $TEMPFILE | grep -v "^+++" | sed 's/^.//'| sed s/[[:space:]]//g |sed '/^$/d'|wc -l`  
	TOTAL=$((TOTAL+count))
    done
        rm -rf $TEMPFILE
    echo "$author added $TOTAL lines."
fi

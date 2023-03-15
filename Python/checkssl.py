# -*- coding:utf-8 -*-

"""
Notice: This script is used to check SSL certificate expire date. Need Python3 env and requests module.
"""

import re
import time
import requests
import json
from datetime import datetime
import subprocess
import traceback


# 定义要检查的域名列表
domains = ['xxx.com', 'yyy.cn', 'zzz.com']
# 定义钉钉告警组
robot_token = {
    'ops': '*********************************************'
}


# 定义一个钉钉告警函数
def alert_by_dingding(grpname, webhook_title, alert_message):
    if grpname in robot_token:
        try:
            token = robot_token[grpname]
            webhook_url = 'https://oapi.dingtalk.com/robot/send?access_token=%s' % token

            webhook_header = {
                "Content-Type": "application/json",
                "charset": "utf-8"
            }
            webhook_message = {
                "msgtype": "markdown",
                "markdown": {
                    "title": webhook_title,
                    "text": alert_message
                }
            }

            sendData = json.dumps(webhook_message, indent=1)
            requests.post(url=webhook_url, headers=webhook_header, data=sendData)
        except Exception as e:
            traceback.print_exc(file=open('/tmp/alert_by_dingding.log', 'w+'))


# 定义一个用来获取ssl证书信息的函数
def get_ssl_info(domain):
    cmd = 'curl -lvs https://{}/'.format(domain)
    sslinfo = subprocess.getstatusoutput(cmd)[1]
    
    try:
        # 使用正则表达获取证书过期时间
        m = re.search('subject:(.*?)\n.*?start date:(.*?)\n.*?expire date:(.*?)\n.*?common name:(.*?)\n.*?issuer:(.*?)\n',
                      sslinfo)
        start_date = m.group(2)
        expire_date = m.group(3)
        cert_name = m.group(4)
    except Exception as e:
        print("Error message: %s", str(e))
    else:
        # time字符串转换为时间数组，跟当前的时间相减得出证书剩余有效天数
        expire_date_format = datetime.strptime(expire_date, " %b %d %H:%M:%S %Y GMT")
        # expire_day仅用来保存过期日期（精确到天）,为了钉钉告警格式美观而设置
        expire_day = datetime.strftime(expire_date_format, '%Y-%m-%d')
        left_days = (expire_date_format - datetime.now()).days

    if left_days <= 90:
        try:
            alert_title = "Warning"
            alert_content = '<font size="12" color="#ff3300">【警告】</font>SSL证书即将过期\n' \
                            '****\n' \
                            '证书：%s  \n' \
                            '证书到期日：%s  \n' \
                            '剩余天数：%s' % (cert_name, expire_day, left_days)
            alert_by_dingding('ops', alert_title, alert_content)
        except Exception as e:
            #print(alert_content)
            print("Error message: %s" % str(e))

    # 睡眠1s
    time.sleep(1)


if __name__ == '__main__':
    if len(domains) >0:
        for domain in domains:
            get_ssl_info(domain)
    else:
        print("Please check domain list first.")

# -*- coding:utf-8 -*-

"""
Notice: This script is used to check SSL certificate expire date. Need Python3 env and requests module.
"""

import re
import time
import requests
import json
from datetime import datetime
import traceback

"""
Notice: This script is used to check domain expire date. 
Env: Python3 + requests module
"""


# 定义用到的whois查询站点URL
whois_site = 'http://whoissoft.com/'

# 定义要检查的域名列表
domains = ['zzz.com', 'xxx.cn', 'yyy.com']

# 定义钉钉告警组
robot_token = {
    'ops': '************************************'
}
left_days = 0

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


# 定义一个用来获取域名信息的函数
def get_domain_info(domain):
    req_url = whois_site + domain
    headers = {'user-agent': 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008071615 Fedora/3.0.1-1.fc9 '
                             'Firefox/3.0.1'}
    r = requests.get(req_url, headers=headers, timeout=30)
    if r.status_code == requests.codes.ok:
        content = r.text
        try:
            # 从返回内容中获取域名到期时间
            info = re.search('Registry Expiry Date: (.*?)\n', content)
            exp_date = re.split('<br />', info.group(1))[0]
            # 将时间字符串转换为时间数组，进而计算出剩余天数
            expire_date = datetime.strptime(exp_date, '%Y-%m-%dT%H:%M:%SZ')
        except AttributeError:
            info = re.search('Expiration Time: (.*?)\n', content)
            exp_date = re.split('<br />', info.group(1))[0]
            # 将时间字符串转换为时间数组，进而计算出剩余天数
            expire_date = datetime.strptime(exp_date, '%Y-%m-%d %H:%M:%S')
        except Exception as e:
            print("Error message: %s" % (str(e)))
        finally:
            left_days = (expire_date - datetime.now()).days
            expire_day = datetime.strftime(expire_date, '%Y-%m-%d')
        

        if left_days <= 90:
            try:
                alert_title = "Domain Expiration!!!"
                alert_content = '<font size="12" color="#ff3300">【警告】</font>域名即将过期\n' \
                                '****\n' \
                                '域名：%s  \n' \
                                '到期日期：%s  \n' \
                                '剩余天数：%s' % (domain, expire_day, left_days)
                alert_by_dingding('ops', alert_title, alert_content)
            except Exception as e:
                traceback.print_exc(file=open('/tmp/alert_by_dingding.log', 'w+'))

    # 睡眠1s
    time.sleep(1)


if __name__ == '__main__':
    if len(domains) > 0:
        for domain in domains:
            get_domain_info(domain)
    else:
        print("Please check domain list first.")

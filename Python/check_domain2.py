# _*_ coding:utf-8 _*_

import requests
import re
import datetime
import json
import traceback


whois_site = 'http://whois.chinaz.com/'
domains = ['xxx.com', 'yyy.cn', 'zzz.com']
robot_token = {
    'ops': '**************************************'
}

# 获取当前日期
today = datetime.date.today()
# 将当前日期转换为datetime类型
tdate = datetime.datetime.strptime(str(today), '%Y-%m-%d')


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


def get_domain_expiration(domain):
    req_url = whois_site + domain
    headers = {'user-agent': 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008071615 Fedora/3.0.1-1.fc9 '
                             'Firefox/3.0.1'}
    r = requests.get(req_url, headers=headers, timeout=30)
    if r.status_code == requests.codes.ok:
        content = r.text
        info = re.search('<div class="fl WhLeList-left">过期时间</div><div class="fr WhLeList-right"><span>(\w)+</span>'
                         , content).group()
        res = re.split('<span>|</span>', info)[1]
        res2 = re.sub('(\D)', '-', res).strip('-')

        # 将到期日期转换为datetime类型
        ddate = datetime.datetime.strptime(res2, '%Y-%m-%d')
        # 获取剩余天数
        leftdays = (ddate - tdate).days

        if leftdays <= 90:
            try:
                alert_title = "Domain Expiration!!!"
                alert_content = '<font size="12" color="#ff3300">【警告】</font>域名即将过期\n' \
                                '****\n' \
                                '域名：%s  \n' \
                                '到期日期：%s  \n' \
                                '剩余天数：%s' % (domain, ddate, leftdays)
                alert_by_dingding('ops', alert_title, alert_content)
            except Exception as e:
                print(alert_content)


if __name__ == '__main__':
    for domain in domains:
        get_domain_expiration(domain)

# -*- coding:utf-8 -*-

import requests
import json
from datetime import datetime,timedelta
import time,os,csv
import pymysql
from time import sleep

class Zabbix:

    def __init__(self, username=None, password=None):
        self.headers = {
            'Content-Type': 'application/json-rpc'
        }
        self.url = 'http://zbx.dreame.com/api_jsonrpc.php' #替换为具体的zabbix地址
        if username and password:
            self.username = username
            self.password = password

    def _token(self): #获取token
        data = {
            "jsonrpc": "2.0",
            "method": "user.login",
            "params": {
                "user": self.username,
                "password": self.password
            },
            "id": 1,
            "auth": None
        }
        r = requests.post(url=self.url, headers=self.headers, data=json.dumps(data))
        token = json.loads(r.content).get("result")
        return token

    def all_hostid(self): #获取所有主机的hostid
        data = {
            "jsonrpc": "2.0",
            "method": "host.get",
            "params": {
                "output": [
                    "hostid",
                    "host",
                ],
                "selectInterfaces": [
                    "interfaceid",
                    "ip"
                ],
                "filter": {
                    "status": 0
                },
                # "limit": 2
            },
            "id": 2,
            "auth": self._token()
        }
        r = requests.post(url=self.url, headers=self.headers, data=json.dumps(data))
        hosts = json.loads(r.content)
        for i in hosts['result']:
            yield i

    def get_itemid_by_hostid(self,item,hostid,application=None):
        data = {
            "jsonrpc": "2.0",
            "method": "item.get",
            "params": {
                # "output": ["itemid","keys_"],
                "output": "extend",
                "hostids": hostid,
                "application": application,
                "search": {
                    "key_": item
                },
            },
            "id": 0,
            "auth": self._token()
        }
        r = requests.post(url=self.url, headers=self.headers, data=json.dumps(data))
        res = json.loads(r.content)
        # print(res)
        return res[u'result'][0][u'lastvalue']

    def get_hostid_by_ip(self, ip=None): #通过ip地址获取主机的hostid
        hostid = ""
        if ip is None:
            print("ip address is None")
            return hostid
        for i in self.all_hostid():
            if i["interfaces"][0]["ip"] == ip:
                hostid = i['hostid']
                break
        return hostid


def get_cpu_mem_avg(hostname,hostid,start_date,end_date):
    conn = pymysql.connect(host='127.0.0.1', port=int(3306),
                           user='zbxuser', password='zbx@HY2o18', database='zabbix')
    cursor = conn.cursor()
    # 先查询机器的总内存,，获取一个值即可
    sql_mem_total = """
select value from history_uint
where itemid in (select  itemid from  items  where  hostid={hostid}  and  key_= "vm.memory.size[total]")
and from_unixtime(clock) >= '{start_date}'
    and from_unixtime(clock) < '{end_date}'
limit 1;
""".format(hostid=hostid,start_date=start_date,end_date=end_date)
    #print(sql_mem_total)
    cursor.execute(sql_mem_total)
    mem_total = cursor.fetchone()
    mem_total = mem_total[0]
    print(mem_total)
    #print(type(mem_total))

    # 获取内存平均值
    sql_mem_avg = """
    select 
avg(({mem_total} - value) / {mem_total})*100 as value
from history_uint
where itemid in (select  itemid from  items  where  hostid={hostid}  and  key_= "vm.memory.size[available]")
    and from_unixtime(clock) >= '{start_date}'
    and from_unixtime(clock) < '{end_date}';
    """.format(mem_total=mem_total,hostid=hostid,start_date=start_date,end_date=end_date)
    #print(sql_mem_avg)
    cursor = conn.cursor()
    cursor.execute(sql_mem_avg)
    mem_avg = cursor.fetchone()
    print(mem_avg[0])
    # 获取cpu使用平均值
    sql_cpu_avg = """
    select 
avg(value_min) as value
from trends
where itemid in (select  itemid from  items  where  hostid={hostid}  and  key_= "system.cpu.util[,idle]")
    and from_unixtime(clock) >= '{start_date}'
    and from_unixtime(clock) < '{end_date}';
    """.format(hostid=hostid,start_date=start_date,end_date=end_date)
    #print(sql_cpu_avg)
    cursor.execute(sql_cpu_avg)
    cpu_avg = cursor.fetchone()
    print(cpu_avg[0])
    return (hostname,round(100-float(cpu_avg[0]),2),round(mem_avg[0],2))


def test_get_all_host():
    
    # 通过Zabbix API获取所有主机信息，{hostid,hostname}
    user = 'Admin'
    passwd = '*********'
    zabbix =Zabbix(user,passwd)
    ips = zabbix.all_hostid()
    #ips = [{'hostid':10112,"host":"web01"}]

    # 遍历主机信息，获取cpu和内存使用率信息，保存到 item_list 列表中
    count = 0
    item_dict = {}
    item_list = []
    count = 0
    for i in ips:
        count += 1
        hostid = i['hostid']
        hostname = i['host']

        # 通过sql查询获取到对应主机的内存和cpu信息,这里需要更改起始和结束时间
        item_dict=get_cpu_mem_avg(hostname,hostid,'2021-06-01','2021-06-30')
        item_list.append(item_dict)
        sleep(0.1)
    
    # 全部主机的cpu和内存信息获取完成后，写入到文件中保存，直接下载该文件即可
    with open('common'+str(datetime.datetime.now().month)+'.csv', 'w') as result:
        writer = csv.writer(result, dialect='excel')
        header = ['主机名称','CPU平均占用率','内存平均占用率']
        writer.writerow(header)
        writer.writerows(item_list)
        


if __name__ == "__main__":
    print(time.strftime('%Y-%m-%d %H:%M:%S'))
    test_get_all_host()
    print(time.strftime('%Y-%m-%d %H:%M:%S'))

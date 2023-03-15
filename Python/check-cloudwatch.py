import boto3
import json
import datetime
import logging
import requests
import traceback

robot_token = {
    'ops': '****************************************************',
    'g_ops': '****************************************************',
    'aws-ops': '9ac479b5ac5ce4901fac58f0b4a95978e0f9823cd1d053724db8faeffe24358b'
}

def get_alarms(client,alarm_type,state,alarmname='None'):
    response = client.describe_alarms(
        # AlarmNames=[
        # alarmname,
        # ],
        AlarmTypes = [
            alarm_type,
        ],
        StateValue = state
    )
    # response = json.loads(response)
    return response['MetricAlarms']
# 定义一个发送消息的函数，grpname为告警组名称，webhook_title为告警主题，\
# alert_message为告警信息
def send_message(grpname, webhook_title, alert_message):
    if grpname in robot_token:
        if alert_message and alert_message.strip() != '':
            try:
                token = robot_token[grpname]
                url = 'https://oapi.dingtalk.com/robot/send?access_token=%s' % token

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
                req =requests.post(url, data=sendData, headers=webhook_header)
                print(req)
            except Exception as e:
                traceback.print_exc()
        else:
            try:
                raise ValueError('告警信息不能为空！')
            except ValueError as e:
                traceback.print_exc()
    else:
        try:
            raise ValueError('找不到指定的告警组！')
        except ValueError as e:
            traceback.print_exc()

def getObject(m, f):
    return m.get(f)


def get_ec2_name_from_id(id):
    # 输入实例id
    # 输出实例name,钉钉组
    ec2 = boto3.resource('ec2')
    # 根据id查找实例信息
    instance_info = ec2.instances.filter(
        InstanceIds=[
        id,
        ],
    )
    # print(running_instances)
    for instance in instance_info:
        project = ''
        name = 'NULL'
        for tag in instance.tags:
            if 'Name'in tag['Key']:
                name = tag['Value']
            if tag['Key'].strip() == 'Owner:group':
                project = tag['Value']
        private_ip =  instance.private_ip_address
    grpname = 'aws-ops'
    group = 'flag'
    if project.strip() == 'SYS':
        grpname = 'sys'
    if project.strip() == 'DE':
        grpname = 'sys'
    if project.strip() == 'RD':
        grpname = 'stary_ops'
    return grpname,name,private_ip

# 根据目标组id获取后端服务器组不健康的机器
def get_elb_ec2name_from_id(targetgroup_name):
    alb_client = boto3.client('elbv2')
    # cloudwatch_client = boto3.client('cloudwatch')
    # targetgroup_name = message['Trigger']['Dimensions'][0]['value']

    ToAppendforARN = "arn:aws:elasticloadbalancing:us-east-1:244190738639:"      
    #Replace the region and account number accordingly
    TargetGroup_Arn = ToAppendforARN + targetgroup_name
    alb_response = alb_client.describe_target_health(TargetGroupArn=TargetGroup_Arn)
    print(alb_response)
    
    # sns_message = []
    instances = list()
    instances_ip = list()
    flag = 0
    for i in alb_response['TargetHealthDescriptions']:
        if i['TargetHealth']['State'] == 'unhealthy':
            # 根据id获取不健康机器实例名称
            instance_id = i['Target']['Id']
            grpname_group,instance_name,ip = get_ec2_name_from_id(instance_id)
            print(instance_name)
            instances.append(instance_name)
            instances_ip.append(ip)
            flag = 1
        instance_id = i['Target']['Id']
    
    if flag==1:
        return instances,instances_ip
    else:
        return 'NULL','NULL'
        
# 获取负载均衡器的标签的信息，根据标签信心返回不同的钉钉群组token        
def get_tags_elb_from_id(elb_name):
    alb_client = boto3.client('elbv2')
    # cloudwatch_client = boto3.client('cloudwatch')
    # targetgroup_name = message['Trigger']['Dimensions'][0]['value']

    ToAppendforARN = "arn:aws:elasticloadbalancing:us-east-1:244190738639:loadbalancer/"      
    #Replace the region and account number accordingly
    TargetGroup_Arn = ToAppendforARN + elb_name
    tag_response = alb_client.describe_tags(
    ResourceArns=[
        TargetGroup_Arn,
    ]
    )
    print(tag_response)
    for tag in tag_response['TagDescriptions'][0]['Tags']:
        if tag['Key'].strip() == 'Owner:group':
            group = tag['Value']
    group = 'flag'
    grpname = 'aws-ops'
    if group.strip() == 'SYS':
        grpname = 'sys'
    if group.strip() == 'DE':
        grpname = 'data'
    if group.strip() == 'RD':
        grpname = 'stary_ops'
    return grpname  

# 获取目标组的标签的信息，根据标签信心返回不同的钉钉群组token        
def get_tags_target_from_id(targetgroup_name):
    alb_client = boto3.client('elbv2')
    # cloudwatch_client = boto3.client('cloudwatch')
    # targetgroup_name = message['Trigger']['Dimensions'][0]['value']

    ToAppendforARN = "arn:aws:elasticloadbalancing:us-east-1:244190738639:"      
    #Replace the region and account number accordingly
    TargetGroup_Arn = ToAppendforARN + targetgroup_name
    tag_response = alb_client.describe_tags(
    ResourceArns=[
        TargetGroup_Arn,
    ]
    )
    print(tag_response)
    for tag in tag_response['TagDescriptions'][0]['Tags']:
        if tag['Key'].strip() == 'Owner:group':
            group = tag['Value']
    group = 'flag'
    grpname = 'aws-ops'
    if group.strip() == 'SYS':
        grpname = 'sys'
    if group.strip() == 'DE':
        grpname = 'data'
    if group.strip() == 'RD':
        grpname = 'stary_ops'
    return grpname 


# 通过实例类型获取标签
def get_tags_from_resource_id(id,type):
    if type == 'redis':
        redis_client = boto3.client("elasticache")
        ToAppendforARN = "arn:aws:elasticache:us-east-1:244190738639:cluster:"
        redis_arn= ToAppendforARN + id
        response = redis_client.list_tags_for_resource(
        ResourceName = redis_arn
        )
    if type == 'rds':
        rds_client = boto3.client("rds")
        ToAppendforARN = "arn:aws:rds:us-east-1:244190738639:db:"
        rds_arn= ToAppendforARN + id
        response = rds_client.list_tags_for_resource(
        ResourceName = rds_arn
        )
    group = 'flag'    
    grpname = 'aws-ops'
    for tag in response['TagList']:
        if tag['Key'].strip() == 'Owner:group':
            group = tag['Value']
    if group.strip() == 'SYS':
        grpname = 'sys'
    if group.strip() == 'BP':
        grpname = 'sys'
    if group.strip() == 'DE':
        grpname = 'data'
    if group.strip() == 'RD':
        grpname = 'stary_ops'
    if group.strip() == 'TEST':
        grpname = 'test'
    return grpname  

def run():
    # 日志配置
    logger = logging.getLogger(__name__)
    result_dict = {}
    result_list = []

    client = boto3.client('cloudwatch')

    # 查询所有状态为 ALARM 的警报
    result = get_alarms(client,'MetricAlarm','ALARM')

    # 空列表匹配
    empty = []
    
    if result == empty:
        now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        logger.info("No alarm,bye!!")
        # 所有状态全部为 ok
        print("{datenow} no alarm".format(datenow=now))
    else:
        logger.info("found alarm, sending dingding to opsers.")
        print(result)
        for alarm in result:


            result_dict = {
                "AlarmName": alarm['AlarmName'],
                "AlarmDescription": alarm['AlarmDescription'],
                "StateValue": alarm['StateValue'],
                "StateReason": alarm['StateReason'],
                "InstanceSource": alarm['MetricName'],
                "InstanceType": alarm['Namespace'],
            }
            # result_list.append(result_dict)
            # if result_dict['InstanceType'] == 'AWS/EC2':
                # grpname,InstanceName = get_ec2_name_from_id(InstanceID)
            InstanceID = ""
            if result_dict['InstanceType'] in ['AWS/EC2','AWS/ApplicationELB','AWS/NetworkELB','AWS/ElastiCache','AWS/RDS']:
                metric_name = alarm['Dimensions'][0]['Name']
                metric_value = alarm['Dimensions'][0]['Value']
                InstanceDetailName = metric_name 
            result_dict['InstanceID'] = metric_value
            print("已更新aws警报列表")
            newMessage = '告警名称: ' + result_dict['AlarmName'] + '\n' + '\n' \
                     + '告警描述: ' + result_dict['AlarmDescription'] + '\n' + '\n' \
                     + '当前状态: ' + '<font size="3" color="#ff3300">' + result_dict['StateValue'] + '</font>' + '\n' + '\n' \
                     + '告警原因: ' + result_dict['StateReason'] + '\n' + '\n' \
                     + '监控项目: ' + result_dict['InstanceSource'] + '\n' + '\n' \
                     + '资源类型：' + result_dict['InstanceType'] + '\n' + '\n' \
                     + '资源ID：' + result_dict['InstanceID']
            InstanceName="NULL"

            #如果资源是kafka的话直接发送到海外运维钉钉群组
            if result_dict['InstanceType'].strip() == 'AWS/Kafka':
                grpname = 'stary-ops'
            if result_dict['InstanceType'].strip() == 'AWS/EC2':
                #grpname,InstanceName,InstanceIP = get_ec2_name_from_id(result_dict['InstanceID'])
                # print(grpname,InstanceName)
                grpname,InstanceName,InstanceIP = get_ec2_name_from_id(result_dict['InstanceID'])
                print(grpname,InstanceName)
        
                if InstanceName != 'NULL':
                    newMessage = newMessage + '\n' + '\n' \
                            + '资源名称：' + InstanceName + '\n' + '\n' \
                            + '机器IP: ' + InstanceIP 
        
        # 如果是ELB监控后端服务器健康的报警的话，去查询后端实例信息，返回不健康机器的名称
            if result_dict['InstanceType'].strip() in ['AWS/ApplicationELB','AWS/NetworkELB']:
                if InstanceDetailName == 'LoadBalancer':
                    grpname = get_tags_elb_from_id(result_dict['InstanceID'])
            
                if InstanceDetailName == 'TargetGroup':
                    grpname = get_tags_target_from_id(result_dict['InstanceID'])
                    if '健康' in AlarmName.strip():
                        InstanceName,InstanceIP = get_elb_ec2name_from_id(result_dict['InstanceID'])
                        if InstanceName != 'NULL':
                            ips = ','.join(InstanceIP)
                            names = ','.join(InstanceName)
                            newMessage = newMessage + '\n' + '\n' \
                                + '不健康机器名称：' + names + '\n' + '\n' \
                                + '不健康机器IP：' + ips 
        
            if result_dict['InstanceType'].strip() == 'AWS/ElastiCache':
                grpname = get_tags_from_resource_id(result_dict['InstanceID'],'redis')
        
            if result_dict['InstanceType'].strip() == 'AWS/RDS':
                grpname = get_tags_from_resource_id(result_dict['InstanceID'],'rds')                
                print(newMessage)
            if newMessage != '':
                title = "Alarm from AWS"
                send_message(grpname=grpname, webhook_title=title, alert_message=newMessage)
                send_message(grpname='aws-ops', webhook_title=title, alert_message=newMessage) 
            
if __name__ == '__main__':
    run()
    

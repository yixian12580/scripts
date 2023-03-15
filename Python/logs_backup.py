#!/usr/bin/env python
#coding=utf-8


import json,logging
import os,sys,shutil,glob,tarfile,importlib
from datetime import timedelta,datetime
import time
import queue
import threading
from contextlib import closing   #解决python2.6版本tarfile模块with语句  object has no attribute '__exit__'问题；2.7版本不需要
import boto3
import re

importlib.reload(sys)

class MyThreadPool:
    def __init__(self,maxsize=1):
        self.maxsize = maxsize
        self._pool = queue.Queue(maxsize)  
        for _ in range(maxsize): 
            self._pool.put(threading.Thread)

    def get_thread(self):
        return self._pool.get()

    def add_thread(self):
        self._pool.put(threading.Thread)

#class S3_put_obj(object):
#
#    client = boto3.client('s3')
#
#    def __init__(self,buckt,dir_str):
#        self.bucket = buckt
#        self.dir_str = dir_str + '/'
#
#    def put_obj_dir(self):
#        S3_put_obj.client.put_object(Bucket=self.bucket, Key=self.dir_str)

class S3_file_handle(object):
    client = boto3.resource('s3')

    def __init__(self,pro_key,dir_path,remote_s3=None,abs_files=None):
        self.pro_key = pro_key
        self.dir_path = dir_path
        self.remote_s3 = remote_s3
        self.bucket = remote_s3['BUCKET']
        self.s3_dir_path = remote_s3['PATH']
        self.abs_files = abs_files
        self.base_time_dir = os.path.basename(dir_path)

    def clear_file(self,file):
        os.remove(file)
        return

    def time_str(self,num):
        return (datetime.today() + timedelta(-num)).strftime('%Y%m%d')

    def del_s3_objs(self):
        bk = S3_file_handle.client.Bucket(self.bucket)
        objects_to_delete = []
        for obj in bk.objects.filter(Prefix=os.path.join(self.s3_dir_path, self.time_str(int(self.remote_s3['S3_SAVE_DAYS']))) + '/'):
            objects_to_delete.append({'Key': obj.key})
        try:
            bk.delete_objects(
                Delete={
                    'Objects': objects_to_delete
                }
            )
            logging.info(self.pro_key + "项目清理旧数据成功！")
        except:
            logging.warning(self.pro_key + "项目清理旧数据失败！")
        return

    def uplod_files(self):
        logging.info(self.pro_key + "项目开始上传。。。")
        for file in self.abs_files:
            obj_name = re.sub(r'^'+self.dir_path+'/?','',file)
            try:
                S3_file_handle.client.Bucket(self.bucket).upload_file(file, os.path.join(self.s3_dir_path,os.path.join(self.base_time_dir,obj_name)))
                self.clear_file(file)
            except:
                logging.warning(self.pro_key + "项目的" + file + "同步传入到s3失败，此处跳过，程序继续执行！")
        logging.info(self.pro_key + "项目结束上传。。。")
        if self.remote_s3['S3_SAVE_DAYS']:
            self.del_s3_objs()
        return

class Logs_backpu:
    def __init__(self,key,pro_value):
        self.key = key
        self.pro_value = pro_value
        self.src_base_father_dir = pro_value['SRC_BASE_FATHER_DIR']
        self.back_log_father_dir = pro_value['BACK_LOG_FATHER_DIR']
        self.before_days = pro_value['BEFORE_DAYS']
        self.save_days = pro_value['SAVE_DAYS']
        self.dir_group_list = pro_value['DIR_GROUP']
        self.sync_s3_tag = pro_value['SYNC_TO_S3']
        self.remote_s3 = pro_value['REMOTE_S3']

    def check_dir(self,dirname):
        if not os.path.isdir(dirname):
            return 0
        else:
            return 1

    def time_str(self,num,format,run_day=datetime.today()):
        if format == 'common':
            return (run_day + timedelta(-num)).strftime('%Y%m%d')
        elif format == 'common-':
            return (run_day + timedelta(-num)).strftime('%Y-%m-%d')
        elif not format:
            return ''

    def check_back_dir(self,num,dirname):
        this_time_log_save_dir = os.path.join(dirname, self.time_str(num, 'common'))
        if not os.path.exists(dirname):
            os.makedirs(this_time_log_save_dir)
        if not os.path.exists(this_time_log_save_dir):
            os.makedirs(this_time_log_save_dir)
        #else:
        #    shutil.rmtree(this_time_log_save_dir)
        #    os.makedirs(this_time_log_save_dir)
        return this_time_log_save_dir

    def mv_matched_files(self,files,dir_item,save_dir):
        des_save_path = os.path.join(save_dir, dir_item['SRC_SON_LOG_DIR'])
        if not os.path.exists(des_save_path):
            os.makedirs(des_save_path)
        for file in files:
            file_name = os.path.basename(file)  
            dest_file_path = os.path.join(des_save_path, file_name)
            shutil.move(file, dest_file_path)
        return

    def start_backup(self,src_son_log_abs_path,dir_item,save_dir):
        time_format = dir_item['TIME_FORMAT']
        re_type = dir_item['RE_TYPE']
        if len(dir_item['TARGET_LOG_FILE_FORMAT']):
            old_time_str = self.time_str(int(self.before_days),time_format,self.run_day)
            for file_format in dir_item['TARGET_LOG_FILE_FORMAT']:
                if re_type == 'type_1':
                    matched_files = glob.glob('{0}/{1}log*{2}*'.format(src_son_log_abs_path, file_format,old_time_str))
                elif re_type == 'type_2':
                    matched_files = glob.glob('{0}/{1}log*{2}'.format(src_son_log_abs_path, file_format, old_time_str))
                elif re_type == 'type_3':
                    matched_files = glob.glob('{0}/{1}{2}*'.format(src_son_log_abs_path, file_format, old_time_str))
                elif re_type == 'type_4':
                    matched_files = glob.glob('{0}/{1}{2}*log'.format(src_son_log_abs_path, file_format, old_time_str))
                elif re_type == 'type_5':
                    matched_files = glob.glob('{0}/{1}'.format(src_son_log_abs_path, file_format))
                else:
                    logging.warning(self.key + "项目目录" + src_son_log_abs_path + "传入的类型格式不匹配，请检查配置，此处跳过，程序继续执行！")
                    matched_files = ''
                if matched_files:
                    self.mv_matched_files(matched_files,dir_item,save_dir)
                else:
                    logging.warning(self.key + "项目目录" + src_son_log_abs_path + "中" + file_format + "类型目标log文件未匹配到，请检查配置，此处跳过，程序继续执行！")
                    pass
        else:
            logging.warning(self.key + "项目目录" + src_son_log_abs_path + "对应得需要备份的日志文件列表为空，请检查配置，此处跳过，程序继续执行！")
            pass
        return

    def tar_bak_dir(self,dir):
        try:
            # 将存放备份日志的目录打包压缩成tar.gz文件
            # python2.7版本直接执行不需要用closing方法
            # with tarfile.open(dir + '.tar.gz', "w:gz") as tar:
            # python2.6版本此处要用closing方法，否则抛出异常
            with closing(tarfile.open(dir + '.tar.gz', "w:gz")) as tar:
                tar.add(dir, arcname=os.path.basename(dir))
                shutil.rmtree(dir)
                logging.info(self.key + "项目此次日志备份打包成功！文件为" + dir + '.tar.gz')
                return
        except:
            logging.warning(self.key + "项目此次日志备份打包失败，请检查配置，此处跳过，程序继续执行！")
            if os.path.exists(dir + '.tar.gz'):
                os.remove(dir + '.tar.gz')
            return

    def clear_old_file(self):
        old_dir_path = os.path.join(self.back_log_father_dir, (self.time_str(int(self.save_days) + int(self.before_days) - 1, 'common')))
        old_log_tar_file_abs_path = old_dir_path + '.tar.gz'
        if os.path.exists(old_log_tar_file_abs_path):
            os.remove(old_log_tar_file_abs_path)
        if os.path.exists(old_dir_path):
            shutil.rmtree(old_dir_path)
        return

    def sync_to_s3(self,dir,abs_files):
        S3_file_handle(self.key,dir,self.remote_s3,abs_files).uplod_files()

    def start_all(self):
        if self.check_dir(self.src_base_father_dir):
            if len(self.dir_group_list):
                this_time_log_save_dir = self.check_back_dir(int(self.before_days),self.back_log_father_dir)
                if self.save_days != -1:
                    self.clear_old_file()
                for dir_item in self.dir_group_list:
                    src_son_log_abs_path = os.path.join(self.src_base_father_dir,dir_item['SRC_SON_LOG_DIR'])
                    if self.check_dir(src_son_log_abs_path):
                        self.start_backup(src_son_log_abs_path,dir_item,this_time_log_save_dir)
                    else:
                        logging.warning(self.key + "项目日志目录" + src_son_log_abs_path + "不存在或不为目录，请检查，此处跳过，程序继续执行！")
                        pass
                abs_files = list()
                for dir_path,dir_names,filenames in os.walk(this_time_log_save_dir):
                    for item in filenames:
                        abs_files.append(os.path.join(dir_path,item))
                if abs_files:
                    if self.sync_s3_tag == 'True' and  self.key == 'sa_data':
                        self.sync_to_s3(this_time_log_save_dir,abs_files)
                    else:
                        logging.warning(self.key + "项目此次不进行压缩和上传s3操作！")
                        if self.key == 'crontasks-front' or self.key == 'crontasks-manager':
                            self.tar_bak_dir(this_time_log_save_dir)
                else:
                    shutil.rmtree(this_time_log_save_dir)
                    logging.warning(self.key + "项目此次最终存放备份文件的目录为空，已删除该目录，程序继续执行！")
                    pass
            else:
                logging.warning(self.key + "项目对应需要备份的日志目录列表为空，请检查，此处跳过，程序继续执行！")
                pass
        else:
            logging.warning(self.key + "项目对应的日志父目录" + self.src_base_father_dir + "不存在或不为目录，请检查，此处跳过，程序继续执行！")
            pass
        #pool.add_thread() 
        return

def Logging_conf(logfile):
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    DATE_FORMAT = "%m/%d/%Y %H:%M:%S %p"
    logging.basicConfig(filename=logfile,level=logging.INFO,format=LOG_FORMAT,datefmt=DATE_FORMAT)
    return

def Prepare(file_name):
    with open(file_name, "r") as f:
        return json.load(f)

def main():
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    settings_file_name = os.path.join(script_dir, 'settings.json')
    logging_log_file = os.path.join(script_dir, 'my.log')
    Logging_conf(logging_log_file)
    data_dic = Prepare(settings_file_name)
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument("-r",dest="run_day",help='the day you want run the scripts')
    args = parser.parse_args()
    run_day = datetime.now()
    if args.run_day:
        run_day = datetime.strptime(args.run_day,"%Y%m%d")
    logging.info("程序执行开始。。。")
    #pool = MyThreadPool(1)
    for key in data_dic.keys():
        logs_bak_main = Logs_backpu(key, data_dic[key])
        if run_day:
            logs_bak_main.run_day = run_day
        logs_bak_main.start_all()
        #t = pool.get_thread()
        #t(target=Logs_backpu(key, data_dic[key]).start_all, args=(pool,)).start()
    #while True:
    #    if threading.active_count() == 1:
    #        break
        time.sleep(5)
    logging.info("程序执行完成。。。")
    with open(logging_log_file, 'a') as f:
        f.write('\n\n')

if __name__ == '__main__':
    main()

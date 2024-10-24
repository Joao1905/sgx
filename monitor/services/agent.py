import os
import sys
import time
import libnacl.secret
import base64

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from models.metric import Metric
from errors.errors import InsufficientDelay

class Agent:
    def __init__(self, agent_id, encryption_key, encryption_nonce, monitor_delay_secs = 10, metrics_file_path = False):
        self.__monitor_delay_secs = int(monitor_delay_secs)

        insufficient_time_delay = self.__monitor_delay_secs < 1
        if (insufficient_time_delay):
            raise InsufficientDelay('collect interval must be of at least 1 second')

        self.__metrics_file_path = metrics_file_path
        if not metrics_file_path:
            self.__metrics_file_path = os.path.join('/metrics', 'metrics.txt')

        self.__agent_id = str(agent_id)
        self.__cpu_info = { "initial_total": 0, "initial_idle": 0, "end_total": 0, "end_idle": 0 }

        encryption_key = base64.b64decode(encryption_key)
        self.__encryption_nonce = base64.b64decode(encryption_nonce)
        self.__box = libnacl.secret.SecretBox(encryption_key)



    def start(self):
        self.__update_cpu_info()
        while True:
            time.sleep(self.__monitor_delay_secs)
            self.__collect_and_persist_data()


    def __collect_and_persist_data(self):
        self.__update_cpu_info()
        cpu_usage_percent = self.__calculate_cpu_usage_pct()
        mem_usage_gb = self.__get_memory_info()
        metric = Metric(self.__agent_id, cpu_usage_percent, mem_usage_gb)
        token = self.__box.encrypt(bytes(metric.to_output(), "utf-8"), self.__encryption_nonce)

        with open(self.__metrics_file_path, "a+") as metrics_file:
            metrics_file.write(str(token)+ '\n')


    def __get_memory_info(self):
        meminfo = {}
        
        with open('/host/proc/meminfo', 'r') as f:
            for line in f:
                parts = line.split()
                key = parts[0].strip(':')
                value = int(parts[1])
                meminfo[key] = value

        total_memory = meminfo['MemTotal'] / 1024**2
        available_memory = meminfo['MemAvailable'] / 1024**2
        return total_memory - available_memory
    

    def __update_cpu_info(self):
        with open('/host/proc/stat', 'r') as f:
            cpu_times = f.readline().strip().split()

        times = [float(x) for x in cpu_times[1:]]
        total_time = sum(times)
        idle_time = times[3] + times[4]
        
        self.__cpu_info["initial_total"] = self.__cpu_info["end_total"]
        self.__cpu_info["initial_idle"] = self.__cpu_info["end_idle"]

        self.__cpu_info["end_total"] = total_time
        self.__cpu_info["end_idle"] = idle_time
    

    def __calculate_cpu_usage_pct(self):
        total_delta = self.__cpu_info["end_total"] - self.__cpu_info["initial_total"]
        idle_delta = self.__cpu_info["end_idle"] - self.__cpu_info["initial_idle"]

        return ((total_delta - idle_delta) / total_delta) * 100
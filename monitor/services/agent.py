import psutil
import os
import sys
import time
import threading

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from models.metric import Metric
from errors.errors import InsufficientDelay

class Agent:
    def __init__(self, agent_id, monitor_delay_secs = 10, metrics_file_path = False):
        self.__monitor_delay_secs = int(monitor_delay_secs)

        insufficient_time_delay = self.__monitor_delay_secs < 1
        if (insufficient_time_delay):
            raise InsufficientDelay('collect interval must be of at least 1 second')

        self.__metrics_file_path = metrics_file_path
        if not metrics_file_path:
            executing_dir, _ = os.path.split(os.path.abspath(__file__))
            self.__metrics_file_path = os.path.join(executing_dir, '..', 'metrics.txt')

        self.__agent_id = str(agent_id)
        

    def get_metrics_file_path(self):
        return self.__persist_path


    def start(self):
        psutil.cpu_percent(interval=None)   # required
        while True:
            time.sleep(self.__monitor_delay_secs)
            self.__collect_and_persist_data()


    def __collect_and_persist_data(self):
        cpu_usage_percent = psutil.cpu_percent(interval=None)
        mem_usage_gb = self.__get_memory_info()
        metric = Metric(self.__agent_id, cpu_usage_percent, mem_usage_gb)
        with open(self.__metrics_file_path, "a+") as metrics_file:
            metrics_file.write(metric.to_output() + '\n')


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
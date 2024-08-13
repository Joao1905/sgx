import threading
import psutil
import os
import uuid

from models.metric import Metric
from errors.errors import InsufficientDelay

class Agent:
    __is_running = False

    def __init__(self, monitor_delay_secs = 10, collect_interval_secs = 3, metrics_file_path = False):
        self.__cpu_collect_interval = int(collect_interval_secs)
        self.__monitor_delay_secs = int(monitor_delay_secs)

        insufficient_time_delay = self.__cpu_collect_interval * 3 > self.__monitor_delay_secs
        if (insufficient_time_delay):
            raise InsufficientDelay('collect interval must be at least 3 times lower than monitor delay')

        self.__metrics_file_path = metrics_file_path
        if not metrics_file_path:
            executing_dir, _ = os.path.split(os.path.abspath(__file__))
            self.__metrics_file_path = os.path.join(executing_dir, '..', 'metrics.txt')

        self.__agent_id = str(uuid.uuid4())
        

    def get_metrics_file_path(self):
        return self.__persist_path

    def start(self):
        if not self.__is_running:
            self.__monitor_thread = threading.Timer(self.__monitor_delay_secs, self.__collect_and_persist_data)
            self.__monitor_thread.start()
            self.__is_running = True
    
    def stop(self):
        self.__monitor_thread.cancel()
        self.__is_running = False


    def __collect_and_persist_data(self):
        self.__is_running = False
        self.start()

        cpu_usage_percent = psutil.cpu_percent(self.__cpu_collect_interval)
        mem_usage_gb = psutil.virtual_memory()[3]/1000000000
        metric = Metric(self.__agent_id, cpu_usage_percent, mem_usage_gb)

        with open(self.__metrics_file_path, "a+") as metrics_file:
            metrics_file.write(metric.to_output() + '\n')
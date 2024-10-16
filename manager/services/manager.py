import os
import sys
import threading
import requests
import json
from ast import literal_eval

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from models.metric import MetricRegister

class Manager:
    __is_running = False

    def __init__(self, metrics_api_addresses_str, metrics_api_endpoint, x_api_key, redis_db, metrics_quantity = 12, fetch_metrics_interval = 10):
        quantity_query_param = '?quantity='

        metrics_api_addresses = literal_eval(metrics_api_addresses_str)
        full_metrics_api_endpoint = metrics_api_endpoint + quantity_query_param + str(metrics_quantity)

        self.__api_metadata = []
        for address in metrics_api_addresses:
            self.__api_metadata.append({
                'url': address+full_metrics_api_endpoint,
                'headers': {"X-Api-Key": x_api_key}
            })

        self.__fetch_metrics_interval = int(fetch_metrics_interval)
        self.__redis = redis_db

    def start(self):
        if not self.__is_running:
            self.__monitor_thread = threading.Timer(self.__fetch_metrics_interval, self.__fetch_and_upsert_data)
            self.__monitor_thread.start()
            self.__is_running = True
    
    def stop(self):
        self.__monitor_thread.cancel()
        self.__is_running = False

    def __fetch_and_upsert_data(self):
        self.__is_running = False
        self.start()

        for target_machine in self.__api_metadata:
            try:
                response = requests.get(target_machine['url'], headers=target_machine['headers'])
                
                if response.status_code != 200:
                    return
                
                all_metrics = json.loads(response.content)

                for metric_dict in all_metrics['metrics']:
                    metric = MetricRegister(metric_dict)
                    self.__redis.upsert_metric(metric)

            except Exception as e:
                print("warn: unable to upsert metric for host ", target_machine['url'], ". error: ", e)
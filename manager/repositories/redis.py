import os
import sys
import redis

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from errors.errors import EnvVariableMissing

class RedisClient:

    def __init__(self):
        host = os.getenv('REDIS_HOST')
        port = os.getenv('REDIS_PORT')
        password = os.getenv('REDIS_PASSWORD')

        variable_missing = not host or not port or not password
        if variable_missing:
            raise EnvVariableMissing('a required redis configuration environment variable is missing')

        self.__client = redis.Redis(
            host        = host,
            port        = port,
            db          = 0,
            password    = password
        )

    def flush(self):
        self.__client.flushdb()

    def upsert_metric(self, metric):
        self.__client.set(metric.get_id(), metric.get_register())

    def get_metric(self, metric_id):
        return self.__client.get(metric_id)
    
    def get_all_metrics(self):
        return self.__client.keys()

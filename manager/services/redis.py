import os
import redis
import json

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
        stringfied_metric = json.dumps(metric)
        self.__client.set(metric['id'], stringfied_metric)

    def get_metric(self, metric_id):
        return self.__client.get(metric_id)

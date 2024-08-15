import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from errors.errors import EnvVariableMissing
from services.manager import Manager
from repositories.redis import RedisClient

def main():
    metricts_quantity = os.getenv('METRICS_QUANTITY')
    fetch_metrics_interval = os.getenv('FETCH_METRICS_INTERVAL')
    flush_redis = os.getenv('FLUSH_REDIS')

    metrics_api_addresses = os.getenv('METRICS_API_ADRESSES')
    metrics_api_endpoint = os.getenv('METRICS_API_ENDPOINT')
    x_api_key = os.getenv('X_API_KEY')

    variable_missing = not metrics_api_addresses or not metrics_api_endpoint or not x_api_key 
    if variable_missing:
        raise EnvVariableMissing('a required environment variable is missing')

    redis = RedisClient()
    if flush_redis == 'yes':
        redis.flush()

    manager = Manager(metrics_api_addresses, metrics_api_endpoint, x_api_key, redis)
    if metricts_quantity and fetch_metrics_interval:
        manager = Manager(metrics_api_addresses, metrics_api_endpoint, x_api_key, redis, metricts_quantity, fetch_metrics_interval)
    
    manager.start()

main()
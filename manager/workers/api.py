import os
import sys
import json
from flask import Flask, request

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from repositories.redis import RedisClient

app = Flask(__name__)

API_KEY = os.getenv('X_API_KEY')
redis = RedisClient()

@app.route("/manager/metrics", methods=['GET'])
def get_host_metrics():
    try:
        received_api_key = request.headers.get('X-Api-Key')
        if received_api_key != API_KEY:
            return {'error': 'unauthorized'}, 401

        redis_response = redis.get_all_metrics()

        metrics = []
        for key in redis_response:
            try:
                metric = redis.get_metric(key)
                metrics.append(json.loads(metric))
            except:
                print('warn: unable to fetch and convert metric to json. metric id: ', str(key))

        return {'metrics': metrics}, 200

    except:
        return {'error': 'internal server error'}, 500
import os
import ast
from flask import Flask, request

app = Flask(__name__)
METRICS_PATH = os.getenv('METRICS_PATH')
API_KEY = os.getenv('X_API_KEY')

@app.route("/metrics", methods=['GET'])
def get_metrics():
    try:
        received_api_key = request.headers.get('X-Api-Key')
        if received_api_key != API_KEY:
            return {'error': 'unauthorized'}, 401

        quantity = int(request.args.get('quantity'))
        if quantity <= 0:
            return {'message': 'quantity must be greater than 0'}, 400

        if not os.path.exists(METRICS_PATH):
            return {'metrics': []}, 200

        metrics = []
        for line in reversed(open(METRICS_PATH).readlines()):
            if len(metrics) == quantity:
                break

            as_dict = ast.literal_eval(line.rstrip())
            metrics.append(as_dict)
        
        return {'metrics': metrics}, 200

    except:
        return {'error': 'internal server error'}, 500
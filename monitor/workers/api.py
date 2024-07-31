import os
import ast
from flask import Flask, request

app = Flask(__name__)
metrics_path = os.environ['METRICS_PATH']

@app.route("/metrics", methods=['GET'])
def get_metrics():
    #try:    
    quantity = int(request.args.get('quantity'))
    if quantity <= 0:
        return 'quantity must be greater than 0', 400

    if not os.path.exists(metrics_path):
        return [], 200

    metrics = []
    for line in reversed(open(metrics_path).readlines()):
        if len(metrics) == quantity:
            break

        as_dict = ast.literal_eval(line.rstrip())
        metrics.append(as_dict)
    
    return metrics, 200

    #except:
    #    return 'internal server error', 500
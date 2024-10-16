import os
import ast
from flask import Flask, request
from cryptography.fernet import Fernet


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

        fernet_key = os.getenv('METRICS_FILE_ENCRYPTION_KEY')
        if not fernet_key:
            return {'message': 'API configuration variable is missing'}, 500

        if not os.path.exists(METRICS_PATH):
            return {'metrics': []}, 204

        metrics = []
        file = open(METRICS_PATH)
        fernet = Fernet(fernet_key)
        for line in reversed(file.readlines()):
            if len(metrics) == quantity:
                break

            message = fernet.decrypt(ast.literal_eval(line)).decode()
            as_dict = ast.literal_eval(message.rstrip())
            metrics.append(as_dict)
        
        file.close()
        
        return {'metrics': metrics}, 200

    except:
        return {'error': 'internal server error'}, 500
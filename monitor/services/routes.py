import os
import ast
from flask import request, Blueprint
import base64
import libnacl.utils
import libnacl.secret

METRICS_PATH = os.getenv('METRICS_PATH')
API_KEY = os.getenv('X_API_KEY')

blueprint = Blueprint("monitor routes", __name__)

@blueprint.route("/metrics", methods=['GET'])
def get_metrics():
    try:
        received_api_key = request.headers.get('X-Api-Key')
        if received_api_key != API_KEY:
            return {'error': 'unauthorized'}, 401

        quantity = int(request.args.get('quantity'))
        if quantity <= 0:
            return {'message': 'quantity must be greater than 0'}, 400

        encryption_key = os.getenv('METRICS_FILE_ENCRYPTION_KEY')
        if not encryption_key:
            return {'message': 'API configuration variable is missing'}, 500
        encryption_key = base64.b64decode(encryption_key)

        if not os.path.exists(METRICS_PATH):
            return {'metrics': []}, 204

        metrics = []
        file = open(METRICS_PATH)
        box = libnacl.secret.SecretBox(encryption_key)
        for line in reversed(file.readlines()):
            if len(metrics) == quantity:
                break

            message = box.decrypt(ast.literal_eval(line)).decode()
            as_dict = ast.literal_eval(message.rstrip())
            metrics.append(as_dict)
        
        file.close()
        
        return {'metrics': metrics}, 200

    except:
        return {'error': 'internal server error'}, 500
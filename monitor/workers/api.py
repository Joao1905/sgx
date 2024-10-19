import sys
import os
import flask

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from services.routes import blueprint


MONITOR_API_PORT = os.getenv('MONITOR_API_LOCAL_PORT')
server = flask.Flask(__name__)
server.register_blueprint(blueprint)

if __name__ == "__main__":
    certificate_path = os.path.join(executing_dir, "..", "certificate", "monitor-api-cert.pem")
    key_path = os.path.join(executing_dir, "..", "certificate", "monitor-api-key.pem")

    server.run(host="0.0.0.0", port=MONITOR_API_PORT, ssl_context=(certificate_path, key_path))
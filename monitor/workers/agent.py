import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from services.agent import Agent
from errors.errors import EnvVariableMissing

def main():
    metrics_path = os.getenv('METRICS_PATH')
    agent_id = os.getenv('AGENT_ID')
    fernet_key = os.getenv('METRICS_FILE_ENCRYPTION_KEY')

    if not agent_id:
        raise EnvVariableMissing('AGENT_ID environment variable is missing')
    
    if not fernet_key:
        raise EnvVariableMissing('METRICS_FILE_ENCRYPTION_KEY environment variable is missing')

    if metrics_path and os.path.exists(metrics_path):
        os.remove(metrics_path)
    
    monitor_delay_secs = os.getenv('MONITOR_DELAY_SECS')

    agent = Agent(agent_id, fernet_key, metrics_file_path=metrics_path)
    if monitor_delay_secs:
        agent = Agent(agent_id, fernet_key, monitor_delay_secs, metrics_file_path=metrics_path)
    
    agent.start()

main()
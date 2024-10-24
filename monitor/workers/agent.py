import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from services.agent import Agent
from errors.errors import EnvVariableMissing

def main():
    metrics_path = os.getenv('METRICS_PATH')
    agent_id = os.getenv('AGENT_ID')
    encryption_key = os.getenv('METRICS_FILE_ENCRYPTION_KEY')
    encryption_nonce = os.getenv('METRICS_FILE_ENCRYPTION_NONCE')

    if not agent_id:
        raise EnvVariableMissing('AGENT_ID environment variable is missing')
    
    if not encryption_key or not encryption_nonce:
        raise EnvVariableMissing('METRICS_FILE_ENCRYPTION_KEY or METRICS_FILE_ENCRYPTION_NONCE environment variable is missing')

    if metrics_path and os.path.exists(metrics_path):
        os.remove(metrics_path)
    
    monitor_delay_secs = os.getenv('MONITOR_DELAY_SECS')

    agent = Agent(agent_id, encryption_key, encryption_nonce, metrics_file_path=metrics_path)
    if monitor_delay_secs:
        agent = Agent(agent_id, encryption_key, encryption_nonce, monitor_delay_secs, metrics_file_path=metrics_path)
    
    agent.start()

main()
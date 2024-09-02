import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from services.agent import Agent
from errors.errors import EnvVariableMissing

def main():
    metrics_path = os.getenv('METRICS_PATH')
    agent_id = os.getenv('AGENT_ID')

    if not agent_id:
        raise EnvVariableMissing('AGENT_ID environment variable is missing')

    if metrics_path and os.path.exists(metrics_path):
        os.remove(metrics_path)
    
    monitor_delay_secs = os.getenv('MONITOR_DELAY_SECS')
    collect_interval_secs = os.getenv('COLLECT_INTERVAL_SECS')

    agent = Agent(agent_id, metrics_file_path=metrics_path)
    if monitor_delay_secs and collect_interval_secs:
        agent = Agent(agent_id, monitor_delay_secs, collect_interval_secs, metrics_file_path=metrics_path)
    
    agent.start()

main()
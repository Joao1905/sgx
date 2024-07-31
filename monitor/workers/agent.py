import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from models.agent import Agent

def main():
    metrics_path = os.environ['METRICS_PATH']
    
    if os.path.exists(metrics_path):
        os.remove(metrics_path)

    agent = Agent(metrics_file_path=metrics_path)
    agent.start()

main()
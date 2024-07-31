import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

from models.agent import Agent

def main():
    agent = Agent()
    agent.start()

main()
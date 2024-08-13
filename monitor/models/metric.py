import sys
import os

executing_dir, _ = os.path.split(os.path.abspath(__file__))
sys.path.append(os.path.join(executing_dir, '..'))

import uuid

from utils.utils import current_ISO_datetime

class Metric:
    def __init__(self, agent_id, cpu, memory):
        self.id = str(uuid.uuid4())
        self.agent_id = agent_id
        self.datetime = current_ISO_datetime()
        self.cpu = "%.2f" % cpu
        self.memory = "%.2f" % memory

    def to_output(self):
        return str({
            'id': self.id,
            'agentId': self.agent_id,
            'datetime': self.datetime,
            'cpu': self.cpu,
            'memory': self.memory,
        })
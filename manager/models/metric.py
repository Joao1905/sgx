import json

class MetricRegister:
    def __init__(self, metric_dict):
        self.__id = metric_dict['id']
        self.__register = json.dumps(metric_dict)

    def get_id(self):
        return self.__id

    def get_register(self):
        return self.__register
from datetime import datetime, timezone
from functools import wraps
import time

def current_ISO_datetime():
    now = datetime.now(timezone.utc).isoformat()
    return now[:-9]+'Z'


def exec_time(func):
    @wraps(func)
    def exec_time_wrapper(*args, **kwargs):
        start_time = time.perf_counter()
        result = func(*args, **kwargs)
        end_time = time.perf_counter()
        total_time = end_time - start_time
        
        with open("/metrics/exec_time.txt", "a+") as exec_time_file:
            exec_time_file.write(f'{func.__name__}: {total_time:.4f}\n')
        
        return result
    return exec_time_wrapper
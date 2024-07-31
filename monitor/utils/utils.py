from datetime import datetime, timezone

def current_ISO_datetime():
    now = datetime.now(timezone.utc).isoformat()
    return now[:-9]+'Z'
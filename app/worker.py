import os
import time

import redis

r = redis.Redis.from_url(os.environ["REDIS_URL"], socket_timeout=10)
print("worker started", flush=True)

while True:
    r.set("worker:heartbeat", int(time.time()), ex=30)
    item = r.blpop("jobs", timeout=5)
    if item:
        print(f"processed job: {item[1].decode()}", flush=True)
        r.incr("jobs:processed")

import os

import psycopg
import redis
from fastapi import FastAPI, Response

app = FastAPI()
r = redis.Redis.from_url(os.environ["REDIS_URL"], socket_connect_timeout=2)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready(response: Response):
    checks = {}
    try:
        checks["redis"] = bool(r.ping())
    except Exception:
        checks["redis"] = False
    try:
        with psycopg.connect(os.environ["DATABASE_URL"], connect_timeout=2) as c:
            c.execute("SELECT 1")
        checks["postgres"] = True
    except Exception:
        checks["postgres"] = False
    if not all(checks.values()):
        response.status_code = 503
    return checks

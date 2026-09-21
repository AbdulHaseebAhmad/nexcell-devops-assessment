#!/usr/bin/env bash
set -u
API_URL="${API_URL:-http://localhost:8000}"
FAILED=0

# usage: check "name" timeout_seconds command...
# retries the command every 2s until it succeeds or the timeout passes
check() {
  local name="$1" timeout="$2"; shift 2
  local end=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$end" ]; do
    if "$@" >/dev/null 2>&1; then
      echo "PASS: $name"
      return 0
    fi
    sleep 2
  done
  echo "FAIL: $name (no success within ${timeout}s)"
  FAILED=1
}

check "liveness (GET /health)" 30 curl -fsS --max-time 3 "$API_URL/health"
check "readiness (GET /ready)" 30 curl -fsS --max-time 3 "$API_URL/ready"

rcli() { docker compose exec -T redis redis-cli "$@" | tr -d '\r'; }

redis_ping() { [ "$(rcli ping)" = "PONG" ]; }

worker_heartbeat() { [ "$(rcli EXISTS worker:heartbeat)" = "1" ]; }

worker_processes_job() {
  local before after end
  before=$(rcli GET jobs:processed); before=${before:-0}
  rcli RPUSH jobs "smoke-$(date +%s)" >/dev/null
  end=$((SECONDS + 10))
  while [ "$SECONDS" -lt "$end" ]; do
    after=$(rcli GET jobs:processed); after=${after:-0}
    [ "$after" -gt "$before" ] && return 0
    sleep 1
  done
  return 1
}

check "redis (PING)" 30 redis_ping
check "worker alive (heartbeat key)" 30 worker_heartbeat
check "worker processes a job" 10 worker_processes_job

if [ "$FAILED" -ne 0 ]; then
  echo "SMOKE TEST FAILED"
  exit 1
fi
echo "SMOKE TEST PASSED"

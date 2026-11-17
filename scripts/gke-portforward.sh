#!/bin/sh
# Port-forward the in-cluster Loki and Prometheus to localhost so a local Grafana
# can query them. No public exposure. Ctrl-C stops both.
set -eu

NS=${NS:-telemetry}

echo "Forwarding:"
echo "  Loki       -> http://localhost:3100"
echo "  Prometheus -> http://localhost:9090"
echo "Start local Grafana with: docker compose -f deploy/local-grafana/compose.yaml up"
echo "Press Ctrl-C to stop."

kubectl -n "$NS" port-forward svc/loki 3100:3100 >/dev/null &
LOKI_PID=$!
kubectl -n "$NS" port-forward svc/prometheus 9090:9090 >/dev/null &
PROM_PID=$!

trap 'kill "$LOKI_PID" "$PROM_PID" 2>/dev/null || true' INT TERM EXIT
wait

📊 Prometheus Monitoring Queries (README)

This file contains commonly used PromQL queries to verify Prometheus, Node Exporter, CPU, Memory, Disk, and Network metrics.
Use these queries in:

Prometheus UI → http://<prometheus-ip>:9090

Grafana UI -> http://<grafana-ip>:3000

Nodeexpoter UI --> http://<node-ip>:9100

Before run the script first paste ur integration key which is create from pagetduty
Grafana panels (Prometheus data source)

✅ 1. Check if Prometheus is Running

Query

up{job="prometheus"}


Expected Result

1 → Prometheus is running ✅

0 → Prometheus is down ❌

✅ 2. Check Node Exporter Status (MOST IMPORTANT)
Generic (all node exporters)
up{job=~".*node.*"}

If job name is ec2-node-exporters
up{job="ec2-node-exporters"}


Expected Result

1 → Node reachable ✅

0 → Node down ❌

✅ 3. CPU Usage (%) per Server


100 - (avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
) * 100)


Description

Shows CPU utilization percentage per instance

Best for dashboards & alerts

✅ 4. Memory Usage (%)


100 * (
  1 - (
    node_memory_MemAvailable_bytes
    / node_memory_MemTotal_bytes
  )
)


Description

Shows memory usage percentage

Works on all Linux systems

✅ 5. Disk Usage (%)


100 * (
  1 - (
    node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}
    /
    node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}
  )
)


Description

Excludes temporary filesystems

Shows real disk usage

✅ 6. Network Receive (MB/sec)
rate(node_network_receive_bytes_total[5m]) / 1024 / 1024


Description

Network incoming traffic per interface

Unit: MB/s


prometheous Query---

100 * (
  1 - (
    node_memory_MemAvailable_bytes
    / node_memory_MemTotal_bytes
  )
)



🧪 Test CPU Load (Optional)
Ubuntu / Amazon Linux

sudo dnf install -y stress-ng


stress-ng --cpu 2 --timeout 300

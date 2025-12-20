✅ 1️⃣ Check if Prometheus is UP

Query

up{job="prometheus"}


Expected

Value = 1 → Prometheus running

✅ 2️⃣ Check Node Exporter status (MOST IMPORTANT)

Query

up{job=~".*node.*"}


or if your job name is ec2-node-exporters:

up{job="ec2-node-exporter"}


Expected

1 = node reachable

0 = node down

✅ 3️⃣ CPU Usage (%) per Server
100 - (avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
) * 100)

✅ 4️⃣ Memory Usage (%)
100 * (
  1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
)

✅ 5️⃣ Disk Usage (%)
100 * (
  1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} 
  / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"})
)

✅ 6️⃣ Network Receive (MB/s)
rate(node_network_receive_bytes_total[5m]) / 1024 / 1024

#!/bin/bash
set -e

echo "=============================="
echo " Installing Prometheus + Grafana + Alertmanager + Node Exporter"
echo " Amazon Linux Compatible"
echo "=============================="

# ============ 1. Update System ============
sudo yum update -y

# ============ 2. Install Prometheus ============
sudo useradd --no-create-home --shell /bin/false prometheus || true
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus

cd /tmp
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.55.1/prometheus-2.55.1.linux-amd64.tar.gz
tar -xvf prometheus-2.55.1.linux-amd64.tar.gz
cd prometheus-2.55.1.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

sudo cp -r consoles console_libraries /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo chown -R prometheus:prometheus /etc/prometheus

sudo tee /etc/systemd/system/prometheus.service >/dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

# ============ 3. Install Grafana ============
sudo tee /etc/yum.repos.d/grafana.repo >/dev/null <<EOF
[grafana]
name=Grafana OSS
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
EOF

sudo yum install -y grafana
sudo systemctl enable --now grafana-server

# ============ 4. Install Alertmanager ============
cd /tmp
curl -LO https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz
cd alertmanager-0.27.0.linux-amd64

sudo cp alertmanager amtool /usr/local/bin/
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo cp alertmanager.yml /etc/alertmanager/
sudo chown -R prometheus:prometheus /etc/alertmanager /var/lib/alertmanager

sudo tee /etc/systemd/system/alertmanager.service >/dev/null <<EOF
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager

# ============ 5. Alert Rules ============
sudo tee /etc/prometheus/alert.rules.yml >/dev/null <<EOF
groups:
- name: example-alerts
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Instance {{ \$labels.instance }} is down"

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 40
    for: 2m
    labels:
      severity: critical
EOF

# ============ 6. PagerDuty ============
sudo tee /etc/alertmanager/alertmanager.yml >/dev/null <<EOF
route:
  receiver: pagerduty

receivers:
- name: pagerduty
  pagerduty_configs:
  - routing_key: "cfb5642a643c4b0cc0e67dd08ad1110f"
    severity: "critical"
EOF

sudo systemctl restart alertmanager

# ============ 7. Node Exporter ============
sudo useradd --no-create-home --shell /bin/false node_exporter || true

cd /tmp
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar -xvf node_exporter-1.8.2.linux-amd64.tar.gz
cd node_exporter-1.8.2.linux-amd64

sudo cp node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# ============ 8. Prometheus Config ============
sudo tee /etc/prometheus/prometheus.yml >/dev/null <<EOF
global:
  scrape_interval: 15s

rule_files:
- alert.rules.yml

alerting:
  alertmanagers:
  - ec2_sd_configs:
    - region: us-east-1
      port: 9093
      filters:
      - name: "tag:Name"
        values: ["node-server"]
    relabel_configs:
    - source_labels: [__meta_ec2_private_ip]
      target_label: __address__
      replacement: "\$1:9093"

scrape_configs:
- job_name: prometheus
  static_configs:
  - targets: ["localhost:9090"]

- job_name: ec2-node-exporters
  ec2_sd_configs:
  - region: us-east-1
    port: 9100
    filters:
    - name: "tag:Name"
      values: ["node-expoter"]
  relabel_configs:
  - source_labels: [__meta_ec2_private_ip]
    target_label: __address__
    replacement: "\$1:9100"
EOF


sudo systemctl restart prometheus

echo "=============================="
echo " Installation Completed ✅"
echo " Prometheus: 9090"
echo " Grafana:    3000"
echo " Alertmanager: 9093"
echo "=============================="

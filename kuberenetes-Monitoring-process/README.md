📊 Grafana & Prometheus Monitoring with PagerDuty (Kubernetes)

This project explains how to install and configure Prometheus, Grafana, and PagerDuty alerting on a Kubernetes cluster using Helm and kube-prometheus-stack.

🧰 Tools & Technologies

Kubernetes

Helm 3

Prometheus

Grafana

kube-prometheus-stack

PagerDuty (Events API v2)

🚀 Installation & Setup
🔹 Install Helm


curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh


Verify Helm:

helm version

📦 Add Helm Repositories
Step 1: Add Stable Helm Repo


helm repo add stable https://charts.helm.sh/stable

Step 2: Add Prometheus Community Repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts


Update repos:

helm repo update

🧱 Create Namespace


kubectl create namespace prometheus

📊 Install kube-Prometheus-Stack


helm install stable prometheus-community/kube-prometheus-stack -n prometheus

🔍 Verify Installation
Check Pods

kubectl get pods -n prometheus

Check Services


kubectl get svc -n prometheus

🌐 Expose Grafana & Prometheus (NodePort)
Edit Prometheus Service


kubectl edit svc stable-kube-prometheus-sta-prometheus -n prometheus


Change:

type: ClusterIP


to:

type: NodePort

Edit Grafana Service


kubectl edit svc stable-grafana -n prometheus


Change:

type: ClusterIP


to:

type: NodePort

Verify Services


kubectl get svc -n prometheus

🔐 Get Grafana Admin Password


kubectl get secret --namespace prometheus stable-grafana \
-o jsonpath="{.data.admin-password}" | base64 --decode ; echo


Grafana URL:


http://<Node-IP>:<Grafana-NodePort>


🚨 PagerDuty Integration


Step 1: Create PagerDuty Service

Go to PagerDuty → Services

Click + New Service

Step 2: Choose Integration Type

Select Events API v2

Step 3: Copy Integration Key

Save the Integration Key (required in Grafana)

🔔 Configure PagerDuty in Grafana


4.1 Add PagerDuty Contact Point

Go to Grafana → Alerting → Contact Points

Click Add Contact Point

Name: PagerDuty Alerts

Type: PagerDuty

Paste Integration Key

Click Save

📈 Create High CPU Usage Alert
Step 1: Create Alert Rule

Go to Alerting → Alert Rules

Click + Create Alert Rule

Step 2: Alert Details

Name: High CPU Usage Alert

Step 3: Add Query
100 - (avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
) * 100)

Step 4: Set Condition

When last value

Is above 90

For 1 minute

Step 5: Notifications

Select PagerDuty Alerts

Step 6: Save Alert Rule
🧪 Test Alerts

Go to Alerting → Alert Rules

Click Test Rule

Generate CPU load on a node

If CPU > 90%:

Alert triggers

PagerDuty incident is created ✅

📌 Access URLs
Service	URL
Prometheus	http://<Node-IP>:<Prometheus-Port>
Grafana	http://<Node-IP>:<Grafana-Port>
Alertmanager	http://<Node-IP>:9093

# Helm Charts Repository

Personal Helm chart repository for deploying Kubernetes stacks focused on security, monitoring, and network analysis.

## Available Charts

### Security & Monitoring
- **wazuh** (v4.7.0) - Threat detection, security monitoring, and compliance platform
- **osquery** - Endpoint visibility and monitoring
- **fleetdm** (v4.9.0) - Open-source device management platform
- **attack-navigator** (v4.9.1) - MITRE ATT&CK Navigator for threat intelligence

### Network Analysis
- **zeek** (v6.0.0) - Network security monitoring framework (formerly Bro)
- **stenographer** - Full packet capture solution
- **strelka** - Real-time file scanning

### ELK Stack
- **elasticsearch** (v8.11.0) - Distributed search and analytics engine
- **kibana** (v8.11.0) - Data visualization for Elasticsearch
- **logstash** - Server-side data processing pipeline
- **filebeat** - Lightweight shipper for log data
- **curator** (v8.0.16) - Elasticsearch index management
- **elastalert** - Alerting framework for Elasticsearch

### Monitoring & Visualization
- **grafana** (v10.2.0) - Metrics dashboard and visualization
- **redis** - In-memory data structure store

### Tools
- **cyberchef** (v10.5.2) - Web app for encryption, encoding, and data analysis
- **salt** - Infrastructure automation and configuration management
- **docker** - Docker-in-Kubernetes deployment

## Installation

### Prerequisites
- Kubernetes cluster (v1.20+)
- Helm 3.x
- kubectl configured to access your cluster

### Installing a Chart

```bash
# Clone the repository
git clone https://github.com/cywf/helm-charts.git
cd helm-charts

# Install a chart (example: elasticsearch)
helm install my-elasticsearch ./elasticsearch/elasticsearch

# Install with custom values
helm install my-elasticsearch ./elasticsearch/elasticsearch -f my-values.yaml

# Install in a specific namespace
helm install my-elasticsearch ./elasticsearch/elasticsearch --namespace monitoring --create-namespace
```

### Upgrading a Chart

```bash
helm upgrade my-elasticsearch ./elasticsearch/elasticsearch
```

### Uninstalling a Chart

```bash
helm uninstall my-elasticsearch
```

## Configuration

Each chart has its own `values.yaml` file with configurable options. Common configurations include:

- **Image tags** - Specify application versions
- **Resources** - CPU and memory limits/requests  
- **Ingress** - Enable external access with custom hostnames
- **Persistence** - Configure persistent storage
- **Network** - ZeroTier network integration (where applicable)

Example custom values file:

```yaml
# my-values.yaml
image:
  tag: "8.11.0"

resources:
  limits:
    memory: "2Gi"
    cpu: "1000m"

ingress:
  enabled: true
  hosts:
    - host: elasticsearch.mydomain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```

## Chart Development

### Linting Charts

```bash
# Lint a specific chart
helm lint ./elasticsearch/elasticsearch

# Lint all charts
for chart in */*/Chart.yaml; do
  helm lint $(dirname $chart)
done
```

### Testing Charts

```bash
# Dry-run install to test rendering
helm install my-test ./elasticsearch/elasticsearch --dry-run --debug

# Template the chart
helm template my-test ./elasticsearch/elasticsearch
```

## Contributing

This is a personal repository, but suggestions and improvements are welcome through issues and pull requests.

## License

See [LICENSE](LICENSE) file for details.

## Notes

- Many charts include ZeroTier network integration for secure networking
- Default configurations use example domains - update for your environment
- Resource limits are conservative - adjust based on your workload
- Some charts may require additional configuration or dependencies

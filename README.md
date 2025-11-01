# helm-charts

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Release Charts](https://github.com/cywf/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/cywf/helm-charts/actions/workflows/release.yml)
[![Lint and Test Charts](https://github.com/cywf/helm-charts/actions/workflows/lint-test.yml/badge.svg)](https://github.com/cywf/helm-charts/actions/workflows/lint-test.yml)

Production-ready Helm charts for deploying a modern SOC/observability/security platform on Kubernetes.

## Overview

This repository provides a curated collection of Helm charts designed for security operations, observability, and platform infrastructure. All charts follow Helm v3 best practices with security hardening by default.

## Features

- **Helm v3 Native**: All charts use `apiVersion: v2` and target Kubernetes 1.28+
- **Security Hardened**: Default security contexts with `runAsNonRoot`, `readOnlyRootFilesystem`, dropped capabilities
- **Standardized Labels**: Kubernetes recommended labels on all resources
- **Schema Validation**: JSON schemas for values validation
- **Observability Ready**: Optional ServiceMonitor/PodMonitor for Prometheus integration
- **Network Policies**: Default-deny policies with explicit egress rules
- **Testing**: Automated linting, unit tests, and installation tests via CI/CD
- **Documentation**: Auto-generated README files with parameter tables

## Quick Start

### Add the Helm Repository

```bash
helm repo add cywf https://cywf.github.io/helm-charts
helm repo update
```

### Install a Chart

```bash
# Example: Install Grafana
helm install my-grafana cywf/grafana

# With custom values
helm install my-grafana cywf/grafana -f values.yaml

# With inline overrides
helm install my-grafana cywf/grafana \
  --set ingress.enabled=true \
  --set monitoring.enabled=true
```

## Available Charts

### Observability & Monitoring
- **grafana** - Visualization and analytics platform
- **kibana** - Elasticsearch data visualization
- **elasticsearch** - Search and analytics engine
- **logstash** - Data processing pipeline

### Security & Threat Detection
- **wazuh** - Security monitoring and SIEM
- **zeek** (bro) - Network security monitor
- **osquery** - Endpoint visibility

### Data Processing & Storage
- **redis** - In-memory data store
- **filebeat** - Log shipper

### Packet Capture & Analysis
- **stenographer** - Packet capture to disk
- **strelka** - File scanning system

### Security Analysis & Intelligence
- **attack-navigator** - ATT&CK Navigator
- **cyberchef** - Cyber operations toolkit
- **fleetdm** - Device management platform

### Utilities
- **curator** - Elasticsearch index management
- **elastalert** - Alerting for Elasticsearch
- **docker** - Docker-in-Kubernetes utilities
- **salt** - Configuration management

## Chart Structure

All charts follow a consistent structure with `Chart.yaml`, `values.yaml`, `values.schema.json`, templates, and tests.

## Security Model

All charts implement security hardening by default:
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- Drop all capabilities

Charts requiring elevated privileges use a `security.escalated` flag that must be explicitly enabled.

## Common Configuration

All charts support standard values: `image`, `serviceAccount`, `resources`, `affinity`, `tolerations`, `nodeSelector`, `ingress`, `monitoring`, `networkPolicy`, `persistence`, `autoscaling`, and `podDisruptionBudget`.

See individual chart READMEs for specific configuration options.

## Development

### Prerequisites
- Helm 3.13+
- Kubernetes 1.28+
- kubectl

### Testing
```bash
helm lint <chart-name>/
helm template test <chart-name>/
helm install test <chart-name>/
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Maintainers

- **cywf** - [GitHub](https://github.com/cywf)

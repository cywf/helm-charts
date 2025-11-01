# lib-common

Common library chart providing shared helpers and templates for cywf/helm-charts repository.

## Overview

This library chart provides reusable templates and helpers that standardize chart development across the repository. It implements Helm v3 and Kubernetes best practices with security hardening by default.

## Features

- **Common Labels**: Standardized Kubernetes recommended labels
- **Security Defaults**: Hardened security contexts (runAsNonRoot, readOnlyRootFilesystem, drop all capabilities)
- **Monitoring**: ServiceMonitor and PodMonitor templates
- **Network Policies**: Default-deny NetworkPolicy templates with DNS/NTP egress
- **Resource Management**: PodDisruptionBudget and HorizontalPodAutoscaler templates
- **Helpers**: Name, fullname, chart, serviceAccount helpers

## Usage

Add this library chart as a dependency in your application chart's `Chart.yaml`:

```yaml
apiVersion: v2
name: my-chart
version: 1.0.0
dependencies:
  - name: lib-common
    version: ~0.1.0
    repository: file://../lib-common
```

Then use the helpers in your templates:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
    spec:
      securityContext:
        {{- include "common.podSecurityContext" . | nindent 8 }}
      containers:
        - name: main
          securityContext:
            {{- include "common.securityContext" . | nindent 12 }}
```

## Available Templates

### Labels and Names
- `common.name` - Chart name
- `common.fullname` - Full resource name
- `common.chart` - Chart name and version
- `common.labels` - Complete label set
- `common.selectorLabels` - Selector labels only
- `common.serviceAccountName` - ServiceAccount name

### Security
- `common.podSecurityContext` - Pod-level security context
- `common.securityContext` - Container-level security context

### Resources
- `common.serviceMonitor` - ServiceMonitor resource
- `common.podMonitor` - PodMonitor resource
- `common.networkPolicy` - NetworkPolicy resource
- `common.pdb` - PodDisruptionBudget resource
- `common.hpa` - HorizontalPodAutoscaler resource

### Capabilities
- `common.capabilities.networkPolicy.apiVersion` - NetworkPolicy API version
- `common.capabilities.ingress.apiVersion` - Ingress API version
- `common.capabilities.pdb.apiVersion` - PDB API version

## Security Defaults

The library chart enforces these security defaults:

```yaml
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

Charts requiring elevated privileges should:
1. Add a `security.escalated` flag in values
2. Conditionally override security settings
3. Document why elevated privileges are needed

## Maintainers

- cywf (https://github.com/cywf)

# Helm Charts Modernization Guide

This guide documents the modernization approach and provides templates for completing the remaining work.

## Completed Work

### Phase 1: Repository Foundation ✅
- Created lib-common library chart with shared helpers
- Added GitHub Actions workflows (lint-test.yml, release.yml)
- Added chart-testing configuration (ct.yaml)
- Added pre-commit hooks and yamllint config
- Updated root README.md with comprehensive documentation
- Added .gitignore for build artifacts

### Phase 2: Chart Structure Normalization ✅
- Flattened all nested chart directories
- Converted security-onion and zerotier from raw manifests to proper Helm charts
- Standardized all Chart.yaml files with complete metadata

## Remaining Work

### Immediate: Fix Broken Charts

8 charts have pre-existing template or values issues that need fixing:

#### 1. grafana - Template truncation
**Issue**: deployment.yaml is incomplete (line 121 cuts off)
**Fix**: Complete the template or regenerate from `helm create`

#### 2. attack-navigator, cyberchef, elasticsearch - Missing serviceAccount values
**Issue**: Templates reference .Values.serviceAccount.create but values.yaml lacks serviceAccount section
**Fix**: Add to values.yaml:
```yaml
serviceAccount:
  create: true
  annotations: {}
  name: ""
```

#### 3. curator - Missing service.port
**Issue**: test-connection.yaml references .Values.service.port but it's not defined
**Fix**: Add to values.yaml:
```yaml
service:
  type: ClusterIP
  port: 9200
```

#### 4. docker - Template syntax error
**Issue**: deployment.yaml has YAML syntax error around line 18
**Fix**: Review and fix YAML indentation/structure

#### 5. filebeat - Template EOF error
**Issue**: deployment.yaml has unexpected EOF at line 108
**Fix**: Complete the template

#### 6. fleetdm - Missing zerotier config
**Issue**: deployment.yaml references .Values.zerotier.networkId
**Fix**: Either add zerotier config to values or remove from template

### Phase 3: Add Schemas and Modern Features

For each chart, add:

#### values.schema.json Template
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "default": 1
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": {
          "type": "string",
          "minLength": 1
        },
        "tag": {
          "type": "string"
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["IfNotPresent", "Always", "Never"],
          "default": "IfNotPresent"
        }
      },
      "required": ["repository"]
    },
    "serviceAccount": {
      "type": "object",
      "properties": {
        "create": {
          "type": "boolean",
          "default": true
        },
        "name": {
          "type": "string"
        },
        "annotations": {
          "type": "object"
        }
      }
    },
    "podSecurityContext": {
      "type": "object"
    },
    "securityContext": {
      "type": "object"
    },
    "service": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["ClusterIP", "NodePort", "LoadBalancer"],
          "default": "ClusterIP"
        },
        "port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535
        }
      }
    },
    "ingress": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "className": {
          "type": "string"
        },
        "hosts": {
          "type": "array",
          "items": {
            "type": "object"
          }
        },
        "tls": {
          "type": "array"
        }
      }
    },
    "resources": {
      "type": "object"
    },
    "nodeSelector": {
      "type": "object"
    },
    "tolerations": {
      "type": "array"
    },
    "affinity": {
      "type": "object"
    },
    "networkPolicy": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "ingress": {
          "type": "array"
        },
        "egress": {
          "type": "array"
        }
      }
    },
    "monitoring": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "labels": {
          "type": "object"
        },
        "portName": {
          "type": "string",
          "default": "metrics"
        },
        "interval": {
          "type": "string"
        },
        "path": {
          "type": "string",
          "default": "/metrics"
        }
      }
    },
    "autoscaling": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "minReplicas": {
          "type": "integer",
          "minimum": 1,
          "default": 1
        },
        "maxReplicas": {
          "type": "integer",
          "minimum": 1,
          "default": 10
        }
      }
    },
    "podDisruptionBudget": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "minAvailable": {
          "type": "integer",
          "minimum": 1
        }
      }
    }
  }
}
```

#### NetworkPolicy Template (templates/networkpolicy.yaml)
```yaml
{{- if .Values.networkPolicy.enabled -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "<chart>.fullname" . }}
  labels:
    {{- include "<chart>.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "<chart>.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  {{- if .Values.networkPolicy.ingress }}
  ingress:
    {{- toYaml .Values.networkPolicy.ingress | nindent 4 }}
  {{- end }}
  egress:
    {{- if .Values.networkPolicy.egress }}
    {{- toYaml .Values.networkPolicy.egress | nindent 4 }}
    {{- else }}
    # Default: Allow DNS
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
    {{- end }}
{{- end }}
```

#### ServiceMonitor Template (templates/servicemonitor.yaml)
```yaml
{{- if .Values.monitoring.enabled -}}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "<chart>.fullname" . }}
  labels:
    {{- include "<chart>.labels" . | nindent 4 }}
    {{- if .Values.monitoring.labels }}
    {{- toYaml .Values.monitoring.labels | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "<chart>.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: {{ .Values.monitoring.portName | default "metrics" }}
      {{- if .Values.monitoring.interval }}
      interval: {{ .Values.monitoring.interval }}
      {{- end }}
      {{- if .Values.monitoring.path }}
      path: {{ .Values.monitoring.path }}
      {{- end }}
{{- end }}
```

#### values.yaml additions
```yaml
# Network Policy
networkPolicy:
  enabled: false
  # ingress: []
  # egress: []

# Monitoring with Prometheus
monitoring:
  enabled: false
  labels: {}
  portName: metrics
  interval: 30s
  path: /metrics

# Pod Disruption Budget
podDisruptionBudget:
  enabled: false
  minAvailable: 1

# Autoscaling
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

#### Security Context Updates

Replace default empty securityContext with hardened defaults:

```yaml
# In values.yaml
podSecurityContext:
  runAsNonRoot: true
  fsGroup: 1000

securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  runAsUser: 1000

# For charts needing elevated privileges, add:
security:
  escalated: false  # Must be explicitly enabled
```

### Phase 4: DaemonSet Conversions

Charts that should be DaemonSets (node agents):
- filebeat
- osquery
- zeek (for full packet capture)
- wazuh (agent mode)

Template pattern:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ include "<chart>.fullname" . }}
  labels:
    {{- include "<chart>.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "<chart>.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "<chart>.selectorLabels" . | nindent 8 }}
    spec:
      {{- if .Values.security.escalated }}
      hostNetwork: true
      hostPID: true
      {{- end }}
      containers:
      - name: {{ .Chart.Name }}
        # ... container spec
        {{- if .Values.security.escalated }}
        securityContext:
          privileged: true
        {{- else }}
        securityContext:
          {{- toYaml .Values.securityContext | nindent 10 }}
        {{- end }}
```

### Phase 5: StatefulSet Conversions

Charts that should be StatefulSets (stateful workloads):
- elasticsearch
- redis

Template pattern:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "<chart>.fullname" . }}
  labels:
    {{- include "<chart>.labels" . | nindent 4 }}
spec:
  serviceName: {{ include "<chart>.fullname" . }}
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "<chart>.selectorLabels" . | nindent 6 }}
  template:
    # ... pod template
  {{- if .Values.persistence.enabled }}
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      {{- if .Values.persistence.storageClass }}
      storageClassName: {{ .Values.persistence.storageClass }}
      {{- end }}
      resources:
        requests:
          storage: {{ .Values.persistence.size }}
  {{- end }}
```

### Phase 6: New Charts

#### Wrapper Chart Pattern

For upstream charts (Grafana, Prometheus, etc.), create wrappers:

```yaml
# Chart.yaml
apiVersion: v2
name: grafana-wrapper
version: 0.1.0
dependencies:
  - name: grafana
    version: ~8.0.0
    repository: https://grafana.github.io/helm-charts
  - name: lib-common
    version: ~0.1.0
    repository: file://../lib-common
```

```yaml
# values.yaml
grafana:
  # Upstream values with our defaults
  securityContext:
    runAsNonRoot: true
    readOnlyRootFilesystem: true
  
  # Our additions
  networkPolicy:
    enabled: true
  
  monitoring:
    enabled: true
```

#### Native Chart Pattern

For charts without good upstream options:

1. `helm create <chart-name>`
2. Update Chart.yaml with proper metadata
3. Add lib-common dependency
4. Use lib-common helpers in templates
5. Add values.schema.json
6. Add NetworkPolicy, ServiceMonitor templates
7. Update security contexts
8. Add NOTES.txt
9. Add tests/

### Phase 7: Testing

#### Unit Tests (helm-unittest)

Install plugin:
```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

Create tests/<chart>_test.yaml:
```yaml
suite: test deployment
templates:
  - deployment.yaml
tests:
  - it: should create a deployment
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: RELEASE-NAME-<chart>

  - it: should use specified image
    set:
      image.repository: custom/image
      image.tag: v1.0.0
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: custom/image:v1.0.0

  - it: should enable ingress
    set:
      ingress.enabled: true
    template: ingress.yaml
    asserts:
      - isKind:
          of: Ingress

  - it: should create networkpolicy when enabled
    set:
      networkPolicy.enabled: true
    template: networkpolicy.yaml
    asserts:
      - isKind:
          of: NetworkPolicy
```

Run tests:
```bash
helm unittest <chart>/
```

#### Integration Tests (chart-testing)

Test locally with KinD:
```bash
# Create KinD cluster
kind create cluster --name ct

# Run chart-testing
ct lint --all
ct install --all

# Cleanup
kind delete cluster --name ct
```

### Phase 8: Documentation

#### Generate README with helm-docs

Install:
```bash
GO111MODULE=on go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
```

Add to each chart's README.md.gotmpl or let helm-docs auto-generate:
```bash
helm-docs
```

This generates a table of values from values.yaml comments.

### Phase 9: Release

After charts are ready:

1. Ensure all charts pass `ct lint`
2. Ensure all charts pass `ct install` on KinD
3. Merge to main branch
4. GitHub Actions will:
   - Package changed charts
   - Update index.yaml
   - Publish to gh-pages

Users can then:
```bash
helm repo add cywf https://cywf.github.io/helm-charts
helm repo update
helm install my-release cywf/<chart>
```

## Quick Reference

### Helm Commands
```bash
# Lint
helm lint <chart>/

# Template (dry-run)
helm template test <chart>/ --debug

# Install locally
helm install test <chart>/ --dry-run --debug
helm install test <chart>/

# Upgrade
helm upgrade test <chart>/

# Uninstall
helm uninstall test
```

### chart-testing Commands
```bash
# Lint all charts
ct lint --all

# Lint changed charts
ct lint

# Install changed charts
ct install

# List changed charts
ct list-changed
```

### Common Patterns

#### Using lib-common Helpers

In templates, replace chart-specific helpers with lib-common:
```yaml
# Instead of:
{{- include "mychart.labels" . | nindent 4 }}

# Use:
{{- include "common.labels" . | nindent 4 }}
```

Update Chart.yaml:
```yaml
dependencies:
  - name: lib-common
    version: ~0.1.0
    repository: file://../lib-common
```

Run:
```bash
helm dependency update <chart>/
```

## Validation Checklist

For each modernized chart:

- [ ] Chart.yaml has complete metadata
- [ ] values.yaml has all standard sections
- [ ] values.schema.json validates values
- [ ] Templates use standardized labels
- [ ] Security contexts are hardened
- [ ] NetworkPolicy template added (opt-in)
- [ ] ServiceMonitor template added (opt-in)
- [ ] NOTES.txt provides useful info
- [ ] README.md generated with helm-docs
- [ ] Unit tests cover main scenarios
- [ ] `helm lint` passes
- [ ] `ct lint` passes
- [ ] `ct install` succeeds on KinD
- [ ] Workload type is appropriate (Deployment/DaemonSet/StatefulSet)
- [ ] If needs privileges, has security.escalated flag

## Support

For questions or issues:
1. Check this guide
2. Review lib-common/README.md
3. Review root README.md
4. Check existing modernized charts as examples
5. Consult Helm documentation: https://helm.sh/docs/

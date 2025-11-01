# Security Hardening Guide

This document explains the security model and hardening practices for all charts in this repository.

## Security Principles

1. **Secure by Default** - All charts use hardened security contexts unless explicitly overridden
2. **Explicit Escalation** - Privileged operations require opt-in via `security.escalated` flag
3. **Least Privilege** - Minimum permissions necessary for functionality
4. **Defense in Depth** - Multiple layers of security (RBAC, NetworkPolicy, PodSecurityContext, etc.)
5. **Transparency** - Clear documentation of security requirements and trade-offs

## Default Security Posture

### Pod Security Context

All charts use this default pod security context:

```yaml
podSecurityContext:
  runAsNonRoot: true
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

### Container Security Context

All containers use this default security context:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### Why These Defaults?

- **runAsNonRoot**: Prevents container from running as root (UID 0)
- **readOnlyRootFilesystem**: Immutable container filesystem prevents tampering
- **allowPrivilegeEscalation**: Prevents processes from gaining more privileges
- **capabilities drop ALL**: Removes all Linux capabilities by default

## Escalated Security Mode

Some workloads require elevated privileges to function:
- Packet capture tools (stenographer, zeek, suricata)
- Network monitoring (zerotier, some wazuh deployments)
- Host-level agents (filebeat with host filesystem access, osquery)

### security.escalated Flag

Charts requiring privileges use this pattern:

```yaml
# values.yaml
security:
  escalated: false  # MUST be explicitly set to true

# In deployment.yaml
{{- if .Values.security.escalated }}
securityContext:
  privileged: true
  capabilities:
    add:
      - NET_ADMIN
      - NET_RAW
{{- else }}
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
{{- end }}
```

### When to Enable security.escalated

Enable only when:
1. Application documentation explicitly requires privileges
2. Functionality requires host network, host PID, or specific capabilities
3. You understand the security implications
4. You have appropriate monitoring and controls in place

### Documentation Requirements

Charts with `security.escalated` support MUST document:

1. **Why it's needed** - In Chart.yaml description and README
2. **What privileges are granted** - List capabilities, host access, etc.
3. **Risks** - Potential security impact
4. **Mitigations** - NetworkPolicy, RBAC, monitoring recommendations

Example NOTES.txt:
```
⚠️  SECURITY WARNING: This chart requires elevated privileges.
   Currently running with security.escalated={{ .Values.security.escalated }}

{{ if .Values.security.escalated }}
   ⚠️  PRIVILEGED MODE ENABLED
   This pod has:
   - Host network access
   - CAP_NET_RAW capability
   - Ability to capture network packets

   Recommended mitigations:
   - Enable NetworkPolicy to restrict traffic
   - Use RBAC to limit ServiceAccount permissions
   - Enable audit logging
   - Monitor pod behavior with Falco or similar
{{ else }}
   ℹ️  Running with restricted security context.
   To enable full functionality, set:
   --set security.escalated=true
{{ end }}
```

## Capability Management

### Common Capabilities and Use Cases

| Capability | Use Case | Charts That May Need It |
|------------|----------|------------------------|
| NET_ADMIN | Network configuration | zerotier |
| NET_RAW | Packet capture | zeek, suricata, stenographer |
| SYS_ADMIN | System administration | Some observability tools |
| DAC_READ_SEARCH | Read all files | filebeat (for log collection) |
| CHOWN | Change file ownership | elasticsearch, redis |

### Adding Specific Capabilities

Instead of `privileged: true`, prefer specific capabilities:

```yaml
securityContext:
  runAsNonRoot: true  # Keep this
  capabilities:
    drop:
      - ALL
    add:
      - NET_RAW      # Only what's needed
      - NET_ADMIN
```

## Network Policies

### Default-Deny Pattern

All charts support optional NetworkPolicy with default-deny approach:

```yaml
# values.yaml
networkPolicy:
  enabled: false
  ingress: []
  egress: []

# When enabled, creates:
# - Default deny all ingress and egress
# - Explicit allow for DNS (to kube-system)
# - Explicit allow for application ports (via ingress rules)
```

### Example NetworkPolicy Configuration

For a web application:
```yaml
networkPolicy:
  enabled: true
  ingress:
    # Allow ingress from ingress controller
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080
  egress:
    # Allow egress to database
    - to:
        - namespaceSelector:
            matchLabels:
              name: database
      ports:
        - protocol: TCP
          port: 5432
    # Allow HTTPS to internet (for API calls)
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
```

For a DaemonSet agent:
```yaml
networkPolicy:
  enabled: true
  ingress:
    # Metrics scraping from Prometheus
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 9090
  egress:
    # Send data to aggregator
    - to:
        - podSelector:
            matchLabels:
              app: log-aggregator
      ports:
        - protocol: TCP
          port: 5044
```

## RBAC

### ServiceAccount

All charts create a ServiceAccount by default:

```yaml
serviceAccount:
  create: true
  annotations: {}
  name: ""  # Auto-generated if not specified
```

### ClusterRole vs Role

**Use ClusterRole** (cluster-wide) for:
- Node-level monitoring (osquery, filebeat on all nodes)
- Cluster-wide security scanning
- Custom resource definitions (CRDs)

**Use Role** (namespace-scoped) for:
- Application-specific permissions
- Most deployments

Example ClusterRole (security-onion):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ include "security-onion.fullname" . }}
rules:
  - apiGroups: [""]
    resources: ["pods", "services"]
    verbs: ["get", "list", "watch"]
```

### Least Privilege RBAC

Only grant necessary permissions:

```yaml
# BAD - Too broad
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]

# GOOD - Specific
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
    resourceNames: ["my-specific-config"]
```

## Pod Security Standards

Charts are designed to comply with Kubernetes Pod Security Standards:

### Restricted (Most Secure)
Most charts should run under Restricted standard:
- No privileged containers
- No host namespaces
- No host paths
- Restricted capabilities
- Must run as non-root
- Read-only root filesystem

### Baseline (Moderate)
Some monitoring/security tools may need Baseline:
- Can use host paths
- Can bind to host ports
- More permissive capabilities

### Privileged (Least Secure)
Only for specific security/network tools:
- Packet capture (stenographer, zeek)
- Network security (suricata)
- System monitoring with host access

Label namespaces appropriately:
```bash
# Restricted
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted

# Baseline for monitoring
kubectl label namespace monitoring pod-security.kubernetes.io/enforce=baseline

# Privileged for security tools (with caution)
kubectl label namespace security pod-security.kubernetes.io/enforce=privileged
```

## Secrets Management

### Never Hardcode Secrets

```yaml
# BAD
env:
  - name: API_KEY
    value: "hardcoded-secret-key"

# GOOD
env:
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: {{ include "app.fullname" . }}-secrets
        key: api-key
```

### Use ExternalSecrets or Sealed Secrets

For production, use:
- **External Secrets Operator** - Sync from Vault, AWS Secrets Manager, etc.
- **Sealed Secrets** - Encrypt secrets for Git storage
- **SOPS** - Encrypt secrets in values files

### Secret Rotation

Design charts to support secret rotation:
```yaml
# Trigger pod restart on secret change
podAnnotations:
  checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
```

## Image Security

### Image Pull Secrets

Support private registries:
```yaml
imagePullSecrets:
  - name: regcred
```

### Image Tags

Always specify tags:
```yaml
# BAD
image: grafana/grafana:latest

# GOOD
image: grafana/grafana:10.2.0
```

### Image Scanning

Before deploying:
1. Scan images with Trivy, Clair, or Anchore
2. Address critical and high vulnerabilities
3. Document known issues in README

## Monitoring Security

### Enable Audit Logging

For sensitive deployments, enable Kubernetes audit logging:
```yaml
# API server flag
--audit-log-path=/var/log/kubernetes/audit.log
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
```

### Runtime Security Monitoring

Deploy Falco for runtime security:
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --set driver.kind=ebpf
```

Falco will alert on:
- Unexpected privileged containers
- Suspicious process execution
- Unauthorized file access
- Network anomalies

### Security Metrics

Expose security-relevant metrics:
```yaml
monitoring:
  enabled: true
  metrics:
    - pod_security_context
    - container_security_context
    - network_policy_enabled
```

## Compliance

### CIS Kubernetes Benchmark

Charts follow CIS Kubernetes Benchmark recommendations:
- 5.2.1: Minimize admission of privileged containers
- 5.2.2: Minimize admission of containers with capabilities
- 5.2.3: Minimize admission of containers with host access
- 5.2.4: Minimize admission of containers with allowPrivilegeEscalation
- 5.2.5: Minimize admission of root containers
- 5.2.6: Minimize admission of containers with NET_RAW

### NIST Compliance

Security controls align with NIST 800-190 (Container Security):
- Image security
- Registry security
- Runtime security
- Host security
- Network security

## Security Checklist

For each chart deployment:

- [ ] Review security.escalated setting (disabled by default)
- [ ] Enable NetworkPolicy if supported by CNI
- [ ] Use specific image tags, not :latest
- [ ] Scan images for vulnerabilities
- [ ] Configure resource limits (prevent DoS)
- [ ] Enable ServiceMonitor for security metrics
- [ ] Review RBAC permissions (least privilege)
- [ ] Use secrets for sensitive data
- [ ] Enable audit logging for sensitive namespaces
- [ ] Deploy runtime security monitoring (Falco)
- [ ] Document security posture in deployment
- [ ] Plan for secret rotation
- [ ] Configure pod disruption budgets
- [ ] Test failure scenarios
- [ ] Review logs for security events

## Incident Response

If security incident occurs:

1. **Isolate** - Apply NetworkPolicy to block traffic
2. **Investigate** - Review logs, audit trail, Falco alerts
3. **Contain** - Scale down or delete affected pods
4. **Remediate** - Patch vulnerabilities, update configs
5. **Document** - Record timeline, root cause, fixes
6. **Improve** - Update charts, add tests, improve monitoring

## Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/security-checklist/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST 800-190 Container Security](https://csrc.nist.gov/publications/detail/sp/800-190/final)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

## Questions?

For security questions or to report vulnerabilities:
- Review this guide
- Check chart-specific security notes in README
- Consult Kubernetes security documentation
- For vulnerabilities, file a private security advisory on GitHub

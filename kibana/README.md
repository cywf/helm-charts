# Kibana Helm Chart

Here's an example values.yaml file for deploying Kibana using Docker and Nginx with a pre-configured Zerotier network:

```yaml
image:
  repository: docker.elastic.co/kibana/kibana
  tag: "7.12.1"
  pullPolicy: IfNotPresent

nameOverride: "kibana"

ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
  path: /
  hosts:
    - kibana.example.com
  tls:
    - secretName: kibana-tls
      hosts:
        - kibana.example.com

config:
  elasticsearch.hosts: http://elasticsearch:9200
  server.host: 0.0.0.0
  server.basePath: /kibana
  xpack.security.enabled: true
  xpack.security.sessionTimeout: 600000
  xpack.reporting.enabled: false
  xpack.encryptedSavedObjects.encryptionKey: "AbcdefghijklmnopqrstuvwxyZ123456"

env:
  ELASTICSEARCH_URL: http://elasticsearch:9200

resources:
  requests:
    cpu: 100m
    memory: 1Gi
  limits:
    cpu: 500m
    memory: 2Gi

zeroTier:
  networkID: "abcdef0123456789"

service:
  type: ClusterIP
  port: 5601

tolerations: []
affinity: {}
nodeSelector: {}
```

- `image`: specifies the Docker image to use for Kibana.
- `nameOverride`: sets a custom name for the Kibana deployment.
- `ingress`: enables and configures an Nginx ingress controller for accessing Kibana externally.
- `config`: sets various Kibana configuration options, such as the Elasticsearch host, server host and base path, X-Pack security options, and encryption key.
-  `env`: sets the ELASTICSEARCH_URL environment variable to the Elasticsearch host URL.
- `resources`: sets CPU and memory resource requests and limits for the Kibana container.
- `zeroTier`: specifies the Zerotier network ID to use for the Kibana deployment.
- `service`: sets the Kubernetes service type and port for accessing Kibana within the cluster.
- `tolerations`, `affinity`, and `nodeSelector`: optional configurations for pod scheduling.

You can save this file as values.yaml and install the chart using the command:

```perl
helm install my-kibana ./kibana --values values.yaml
```

This assumes you have the Kibana Helm chart directory saved in a local directory called `kibana`.
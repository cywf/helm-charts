# ElastAlert Helm Chart

To deploy ElastAlert with Docker, pre-configured with a Zerotier network and accessible via nginx, we can create a Helm chart with the following configuration:

First, create a deployment.yaml file with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elastalert
spec:
  selector:
    matchLabels:
      app: elastalert
  replicas: 1
  template:
    metadata:
      labels:
        app: elastalert
    spec:
      containers:
      - name: elastalert
        image: docker.elastic.co/elastalert/elastalert:0.2.4
        env:
        - name: ELASTICSEARCH_HOST
          value: http://elasticsearch:9200
        - name: ELASTICSEARCH_PORT
          value: "9200"
        - name: RULES_DIRECTORY
          value: /opt/rules
        - name: CONFIG_DIRECTORY
          value: /opt/config
        - name: WRITEBACK_INDEX
          value: elastalert_status
        volumeMounts:
        - name: config
          mountPath: /opt/config
        - name: rules
          mountPath: /opt/rules
      volumes:
      - name: config
        configMap:
          name: elastalert-config
      - name: rules
        configMap:
          name: elastalert-rules
---
apiVersion: v1
kind: Service
metadata:
  name: elastalert
  labels:
    app: elastalert
spec:
  type: ClusterIP
  ports:
  - name: web
    port: 3030
    targetPort: web
  selector:
    app: elastalert
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: elastalert-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - http:
      paths:
      - path: /elastalert(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: elastalert
            port:
              name: web
```

This creates a Deployment for ElastAlert using the official Docker image, sets the necessary environment variables, mounts the configuration and rules files, and exposes the service on port 3030.

Next, create a `configmap.yaml` file with the following content:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: elastalert-config
data:
  elastalert_config.yaml: |
    rules_folder: /opt/rules
    run_every:
      minutes: 5
    buffer_time:
      minutes: 15
    es_host: elasticsearch
    es_port: 9200
    writeback_index: elastalert_status
    use_ssl: false
    verify_certs: true
    rules_loader:
      filesystem:
        path: /opt/rules
    alert:
    - "email"
    email:
      smtp_host: "smtp.gmail.com"
      smtp_port: 587
      smtp_auth_file: /opt/config/smtp_auth_file.yaml
      email_reply_to: "security@example.com"
      email_subject: "ElastAlert"
      from_addr: "security@example.com"
      to_addr: "security@example.com"
      type: "email"
    alert_email:
      - "security@example.com"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: elastalert-rules
data:
  example_rule.yaml: |
    name: Example rule
    type: any
    index: test_index
    filter
```
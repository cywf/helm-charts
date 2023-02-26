# osquery Helm Chart

To create and install a helm chart for deploying osquery, with a pre-configured network using Zerotier, accessible via nginx, you can follow these steps:

1. Create a new directory called osquery and navigate to it:

```shell
mkdir osquery
cd osquery
```

2. Create a file called `Dockerfile` with the following contents:

```dockerfile
FROM osquery/osquery

COPY config/osquery.conf /etc/osquery/osquery.conf
```

This Dockerfile starts from the official osquery image and copies over a pre-configured `osquery.conf` file to the appropriate directory.

3. Create a directory called config and a file called osquery.conf with the desired configuration for osquery. For example:

```ini
[options]
schedule_splay_percent=10
config_refresh=60

[schedule]
file_events={"query": "SELECT * FROM file_events;", "interval": 300}
listening_ports={"query": "SELECT * FROM listening_ports;", "interval": 300}
```

4. Create a new file called `deployment.yaml` and add the following content to it:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: osquery
  labels:
    app: osquery
spec:
  replicas: 1
  selector:
    matchLabels:
      app: osquery
  template:
    metadata:
      labels:
        app: osquery
    spec:
      containers:
        - name: osquery
          image: your-registry/osquery:latest
          imagePullPolicy: Always
          volumeMounts:
            - name: osquery-config
              mountPath: /etc/osquery/
          ports:
            - containerPort: 9000
      volumes:
        - name: osquery-config
          configMap:
            name: osquery-config
```

This file describes a Kubernetes deployment that will run the osquery container, and mount the osquery-config ConfigMap at /etc/osquery inside the container. Note that your-registry should be replaced with your own Docker registry.

5. Create a new file called `service.yaml` and add the following content to it:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: osquery
spec:
  selector:
    app: osquery
  ports:
    - name: http
      port: 80
      targetPort: 9000
```

This file describes a Kubernetes service that will expose the osquery deployment on port 80.

6. Create a new file called `configmap.yaml` and add the following content to it:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: osquery-config
data:
  osquery.conf: |-
    # Paste the contents of your osquery.conf file here
```

This file creates a ConfigMap that stores the contents of the osquery.conf file.

7. Create a new file called values.yaml and add the following content to it:

```yaml
image:
  repository: your-registry/osquery
  tag: latest

zerotier:
  network: your-zerotier-network-id
  secret: your-zerotier-network-secret

nginx:
  enabled: true
```

This file sets the image repository and tag for the osquery container, and enables the nginx ingress.
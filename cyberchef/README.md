# CyberChef

let's create a Helm chart for CyberChef.

First, we need to create a new directory for the chart, let's call it cyberchef:

```shell
$ mkdir cyberchef && cd cyberchef
```

Next, let's create a `Chart.yaml` file with the following content:

```yaml
apiVersion: v2
name: cyberchef
description: A Helm chart for deploying CyberChef
type: application
version: 0.1.0
```

This file specifies the basic information about the chart.

Now let's create a `values.yaml` file to specify the configuration parameters for our CyberChef deployment. Here's an example `values.yaml` file:

```yaml
image:
  repository: cyberchef/cyberchef
  tag: latest
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
  paths:
    - /cyberchef(/|$)(.*)
    - /(.*)\.cc(/|$)(.*)
```

This file specifies the container image to use, as well as the service and ingress configuration. We're using the ClusterIP service type and exposing port 80. We also enable the ingress, which allows us to access CyberChef via a domain name or IP address.

The annotations section in the ingress configuration is used to rewrite the URL path, so that CyberChef is served at the root path (/). The paths section specifies the URL paths that should be routed to CyberChef.

Now let's create a templates directory and add a `deployment.yaml` file to it:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "cyberchef.fullname" . }}
  labels:
    app: {{ include "cyberchef.name" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "cyberchef.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "cyberchef.name" . }}
    spec:
      containers:
      - name: cyberchef
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
        env:
          - name: NODE_ENV
            value: production
```

This file specifies the deployment for CyberChef. We're using a single container with the cyberchef/cyberchef image, exposing port 80. We're also setting the NODE_ENV environment variable to production.

Finally, let's create a `service.yaml` file in the templates directory:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "cyberchef.fullname" . }}
  labels:
    app: {{ include "cyberchef.name" . }}
spec:
  selector:
    app: {{ include "cyberchef.name" . }}
  ports:
    - name: http
      port: 80
      targetPort: 80
  type: {{ .Values.service.type }}
  ```

This file specifies the Kubernetes service for CyberChef, using the selector from the deployment and exposing port 80.

That's it! We now have a Helm chart for deploying CyberChef. To install it, run the helm install command with the chart name and the path to the chart directory:

```shell
$ helm install my-cyberchef ./cyberchef
```

You can customize your variables to match your desired deployment!
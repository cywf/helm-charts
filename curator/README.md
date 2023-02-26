# Chart Details

This chart deploys Curator, a tool for managing Elasticsearch indices. The chart deploys a single Curator pod with a specified number of replicas.

## Chart Parameters

| Parameter          | Description                                     | Default Value     |
|--------------------|-------------------------------------------------|-------------------|
| `image.repository` | The repository for the container image to use   | `nginx`           |
| `image.tag`        | The tag for the container image to use          | `1.21.1-alpine`    |
| `service.port`     | The port to use for the service                  | `80`              |
| `service.type`     | The Kubernetes service type to use               | `ClusterIP`       |
| `zerotier.network` | The Zerotier network ID to use for internal access | N/A             |
| `zerotier.ip`      | The Zerotier IP address to use for the service    | `172.25.0.0`      |
| `domain`           | The domain name to use for the service            | `example.com`     |
| `subdomains`       | The subdomains to use for each internal app       | `graf`, `port`, `prom` |

You can customize the values in this file according to your needs, for example you can change the repository and tag for the container image, or adjust the schedule for running Curator's actions. Once you have customized the values.yaml file, you can install the Helm chart by running the helm install command with the chart name and the path to the chart directory.
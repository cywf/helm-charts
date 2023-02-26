# Logstash Helm Chart

This `values.yaml` file specifies the Docker image to use for Logstash, Logstash configuration files, service and ingress configurations, Zerotier network ID and API token, and resource limits and node affinities.

Note that you will need to replace `<zerotier_network_id>` and `<zerotier_api_token>` with the actual Zerotier network ID and API token, respectively. Also, make sure to replace the hosts field in the ingress section with your desired domain name.
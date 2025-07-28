# phpMyAdmin Helm Chart

This Helm chart deploys phpMyAdmin, a web interface for MySQL and MariaDB, on Kubernetes.

## Overview

phpMyAdmin is a free software tool written in PHP, intended to handle the administration of MySQL over the Web. This chart is fully compatible with the official [phpMyAdmin Docker image](https://hub.docker.com/_/phpmyadmin/).

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `my-phpmyadmin`:

```bash
helm install my-phpmyadmin ./phpmyadmin
```

## Uninstalling the Chart

To uninstall/delete the `my-phpmyadmin` deployment:

```bash
helm delete my-phpmyadmin
```

## Configuration

The following table lists the configurable parameters of the phpMyAdmin chart and their default values.

### Global parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]` |

### Common parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | String to partially override phpmyadmin.fullname template | `""` |
| `fullnameOverride` | String to fully override phpmyadmin.fullname template | `""` |
| `commonLabels` | Labels to add to all deployed objects | `{}` |
| `commonAnnotations` | Annotations to add to all deployed objects | `{}` |

### phpMyAdmin parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.registry` | phpMyAdmin image registry | `docker.io` |
| `image.repository` | phpMyAdmin image repository | `phpmyadmin` |
| `image.tag` | phpMyAdmin image tag | `5.2.1` |
| `image.pullPolicy` | phpMyAdmin image pull policy | `IfNotPresent` |
| `image.pullSecrets` | phpMyAdmin image pull secrets | `[]` |
| `replicaCount` | Number of phpMyAdmin replicas | `1` |

### Database parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `db.allowArbitraryServer` | Allow connection to arbitrary servers | `false` |
| `db.host` | Database host | `website-db-mysql-master` |
| `db.port` | Database port | `3306` |
| `db.user` | Database user | `""` |
| `db.password` | Database password | `""` |
| `db.existingSecret` | Existing secret with database credentials | `""` |

### Service parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.annotations` | Service annotations | `{}` |

### Pod Disruption Budget parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podDisruptionBudget.create` | Create a PodDisruptionBudget | `true` |
| `podDisruptionBudget.minAvailable` | Minimum number of pods available | `""` |
| `podDisruptionBudget.maxUnavailable` | Maximum number of pods unavailable | `1` |

### Ingress parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress controller resource | `true` |
| `ingress.ingressClassName` | IngressClass that will be used | `haproxy-internal` |
| `ingress.hostname` | Default host for the ingress resource | `website-pma.cannes.gw.oxv.fr` |
| `ingress.path` | Default path for the ingress resource | `/` |
| `ingress.pathType` | Ingress path type | `ImplementationSpecific` |
| `ingress.annotations` | Ingress annotations | See values.yaml |
| `ingress.tls` | Enable TLS configuration | `true` |

### Persistence parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistence using PVC | `false` |
| `persistence.storageClass` | PVC Storage Class | `""` |
| `persistence.accessModes` | PVC Access Modes | `[ReadWriteOnce]` |
| `persistence.size` | PVC Storage Request | `8Gi` |

### Extra volumes and volume mounts

| Parameter | Description | Default |
|-----------|-------------|---------|
| `extraVolumes` | Extra volumes to add to the deployment | See values.yaml |
| `extraVolumeMounts` | Extra volume mounts to add to the container | See values.yaml |

### Network Policy parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `networkPolicy.allowExternal` | Allow external connections | `true` |
| `networkPolicy.allowExternalEgress` | Allow external egress | `true` |
| `networkPolicy.ingressNSMatchLabels` | Ingress namespace match labels | `{}` |
| `networkPolicy.ingressNSPodMatchLabels` | Ingress pod match labels | `{}` |
| `networkPolicy.databaseSelector` | Database pod selector for egress | `{}` |
| `networkPolicy.extraEgress` | Extra egress rules | `[]` |
| `networkPolicy.customRules` | Custom network policy rules | `[]` |

## Example Configuration

Here's an example configuration that matches your requirements:

```yaml
db:
  allowArbitraryServer: false
  host: website-db-mysql-master

ingress:
  enabled: true
  hostname: website-pma.cannes.gw.oxv.fr
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-internal
    haproxy.org/allow-list: 82.66.250.240,51.210.177.245
  tls: true
  ingressClassName: haproxy-internal

extraVolumes:
- name: config-inc-php
  configMap:
    name: config-inc-php

extraVolumeMounts:
- name: config-inc-php
  mountPath: /opt/bitnami/phpmyadmin/config.inc.php
  subPath: config.inc.php

# Enable NetworkPolicy for enhanced security
networkPolicy:
  enabled: true
  allowExternal: false
  databaseSelector:
    app: mysql
    component: primary
  ingressNSMatchLabels:
    name: "ingress-system"
```

### NetworkPolicy Example

For enhanced security, you can enable NetworkPolicy to control network traffic:

```yaml
networkPolicy:
  enabled: true
  allowExternal: false
  # Allow ingress from specific namespace
  ingressNSMatchLabels:
    name: "ingress-nginx"
  # Restrict database access to specific pods
  databaseSelector:
    app: mysql
    component: primary
  # Allow specific egress rules
  extraEgress:
    - to:
        - podSelector:
            matchLabels:
              app: "monitoring"
      ports:
        - port: 9090
          protocol: TCP
```

## Using with ConfigMap

To use a custom `config.inc.php` file, create a ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-inc-php
data:
  config.inc.php: |
    <?php
    // Your custom phpMyAdmin configuration
    $cfg['Servers'][1]['auth_type'] = 'config';
    $cfg['Servers'][1]['host'] = 'website-db-mysql-master';
    $cfg['Servers'][1]['compress'] = false;
    $cfg['Servers'][1]['AllowNoPassword'] = false;
    // Add more configuration as needed
```

## Security Considerations

1. **Root User**: The official phpMyAdmin Docker image runs as root user. This chart is configured to accommodate this by setting `runAsUser: 0` and `runAsNonRoot: false` in the security context. Required capabilities (CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID) are added for proper functionality.

2. **Service Account**: The chart sets `automountServiceAccountToken: false` by default for security.

3. **Network Security**: Always use TLS/SSL in production environments

4. **Access Control**: Restrict access using ingress annotations or network policies

5. **Authentication**: Use strong authentication mechanisms

6. **Updates**: Keep the phpMyAdmin image updated to the latest version

7. **Database Privileges**: Consider using a dedicated database user with limited privileges

## Troubleshooting

### Common Issues

1. **Database connection failed**: Check that the database host and port are correct
2. **Ingress not working**: Verify the ingress controller is installed and the hostname resolves
3. **Permission denied**: Check the security context and file permissions

### Useful Commands

```bash
# Check pod logs
kubectl logs -l app.kubernetes.io/name=phpmyadmin

# Check service endpoints
kubectl get endpoints

# Test database connectivity
kubectl exec -it deployment/my-phpmyadmin -- ping website-db-mysql-master
```
phpMyAdmin Helm Chart
========================


This Helm chart deploys phpMyAdmin, a web interface for MySQL and MariaDB, on Kubernetes.

# Bitnami drop-in

This chart was developed to replace the official Bitnami phpMyAdmin chart. You may try to use this one as a drop-in replacement, but be aware that some features may differ or not be implemented.

## Overview

phpMyAdmin is a free software tool written in PHP, intended to handle the administration of MySQL over the Web. This chart is fully compatible with the official [phpMyAdmin Docker image](https://hub.docker.com/_/phpmyadmin/).

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

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
| `containerPorts.http` | Container HTTP port | `8080` |

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


## Custom PMA Configuration

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
    $cfg['Servers'][1]['host'] = 'myhost';
    $cfg['Servers'][1]['compress'] = false;
    $cfg['Servers'][1]['AllowNoPassword'] = false;
    // Add more configuration as needed
```

and add this in yout values.yaml:

```yaml
extraVolumes:
- name: config-inc-php
  configMap:
    name: config-inc-php

extraVolumeMounts:
- name: config-inc-php
  mountPath: /etc/phpmyadmin/conf.d/custom.php
  subPath: config.inc.php
```

## Reverse Proxy Configuration

The `PMA_ABSOLUTE_URI` environment variable is automatically set based on your ingress configuration when both `ingress.enabled` and `ingress.hostname` are configured. The URL is constructed as:

- `https://{{ .Values.ingress.hostname }}{{ .Values.ingress.path }}` if TLS is enabled
- `http://{{ .Values.ingress.hostname }}{{ .Values.ingress.path }}` if TLS is disabled

This ensures phpMyAdmin works correctly behind reverse proxies for:
- Correct generation of absolute URLs
- Proper handling of redirects
- AJAX requests
- File downloads

## Security Considerations

1. **Root User**: The official phpMyAdmin Docker image runs as root user. This chart is configured to accommodate this by setting `runAsUser: 0` and `runAsNonRoot: false` in the security context. Required capabilities (CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID) are added for proper functionality.

2. **Read-Only Root Filesystem**: The container uses `readOnlyRootFilesystem: true` with an emptyDir volume mounted at `/tmp` for temporary files.

3. **Non-Privileged Port**: phpMyAdmin runs on port 8080 instead of the default port 80, which doesn't require root privileges.

4. **Service Account**: The chart sets `automountServiceAccountToken: false` by default for security.

# Unity Store Helm Chart

## Overview

This is a generic Helm chart designed to deploy microservices to a Kubernetes cluster. The chart can install both the `web-server` and `management-api` services, as well as other future services. It provides a flexible and reusable deployment template with support for various Kubernetes resources and auto-scaling capabilities.

## Resources Created

The Helm chart creates the following Kubernetes resources:

### Core Resources

- **Deployment**: Manages the pod replicas for the microservice
- **Service**: Exposes the deployment internally within the cluster (ClusterIP)
- **Ingress**: Provides external access to customer-facing services (optional)

### Optional Resources

- **IAM Role**: Creates an IAM Role that is attached to the Deployment via IRSA (IAM Role for Service Account). This allows pods to assume AWS IAM roles without storing credentials.

  > **Prerequisite**: The cluster must have the [IAM Controller](https://github.com/aws-controllers-k8s/iam-controller) installed for IAM Role creation to work. This is an optional resource.

- **Service Account**: Created automatically when IRSA is enabled, used to bind the IAM Role to the pods.

## Auto-Scaling Support

The chart supports two types of auto-scaling:

### 1. HTTP Request-Based Auto-Scaling

Auto-scales based on HTTP request metrics. When enabled:
- The Ingress resource is **required** and must be enabled
- The Ingress is created in the `keda` namespace
- Requests are forwarded to the KEDA interceptor proxy, which then forwards them to the real service
- Scaling is based on request rate thresholds

> **Prerequisite**: The cluster must have [KEDA](https://github.com/kedacore/charts) and the KEDA HTTP Addon installed. This is an optional resource.

### 2. Kafka Lag-Based Auto-Scaling

Auto-scales based on Kafka consumer lag:
- Monitors the specified Kafka topic and consumer group
- Scales pods based on message lag thresholds
- Supports SASL authentication and TLS encryption
- Requires pre-created secrets for Kafka credentials

> **Prerequisite**: The cluster must have [KEDA](https://github.com/kedacore/charts) installed. This is an optional resource.

## Kubernetes Cluster

The deployment targets a Kubernetes cluster that was created prior to this project:

- **Cluster Management**: Operated by [kOps](https://kops.sigs.k8s.io/)
- **Cloud Provider**: AWS
- **AWS Account ID**: `882709358319`
- **Region**: `eu-central-1`

### Ingress Controller

The cluster uses:
- **Ingress Controller**: NGINX
- **Exposure Method**: AWS Network Load Balancer (NLB)

## Deployment

The Helm charts are deployed to the cluster using **ArgoCD**:

- **ArgoCD URL**: https://argocd.k8s.stav-devops.eu-central-1.pre-prod.stavco9.com/
- **Authentication**: Login with Google (public read access)

ArgoCD continuously monitors the Helm chart repositories and automatically syncs changes to the cluster.

## Secrets Management

The chart supports mounting secrets into pods. Secrets must be created **before** running the chart.

### Creating Secrets

Secrets can be created using `kubectl`:

```bash
kubectl create secret generic <secret-name> \
  --from-file=<file-path> \
  --namespace <namespace>
```

### Configuring Secrets in Values

Secrets are configured in the `values.yaml` file under the `secrets` section:

```yaml
secrets:
  - name: <secret-name>
    mountPath: <mount-path>
    subPath: <sub-path>
```

### Kafka Auto-Scaling Secrets

When using Kafka-based auto-scaling, a specific secret must be created for Kafka credentials. The secret name is specified in `autoscaling.kafka.credentialsSecretName`.

The secret should contain:
- `authMode`: Authentication mode (e.g., `sasl_ssl_plain`)
- `username`: Kafka username
- `password`: Kafka password

Example secret structure:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <credentials-secret-name>
  namespace: <namespace>
data:
  authMode: <base64-encoded-auth-mode>
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

## Example Deployments

### Web Server

The web server is deployed with:
- Ingress enabled for external access
- HTTP-based auto-scaling
- IAM Role via IRSA

**URL**: https://unity-store-dev-web-server.k8s.stav-devops.eu-central-1.pre-prod.stavco9.com/

### Management API

The management API is deployed with:
- No ingress (internal service only)
- Kafka lag-based auto-scaling
- IAM Role via IRSA

## Configuration

The chart is highly configurable through values files. See the example values files:
- `web-server-values/values-dev.yaml` - Web server configuration
- `management-api-values/values-dev.yaml` - Management API configuration

Key configuration areas:
- Microservice settings (name, tag, environment, port, etc.)
- Resource limits and requests
- Auto-scaling configuration
- Ingress settings
- IRSA/IAM Role settings
- Secrets mounting

## Prerequisites Checklist

Before deploying, ensure:

- [ ] Kubernetes cluster is accessible
- [ ] IAM Controller is installed (if using IRSA)
- [ ] KEDA is installed (if using auto-scaling)
- [ ] KEDA HTTP Addon is installed (if using HTTP-based auto-scaling)
- [ ] Required secrets are pre-created in the target namespace
- [ ] Kafka credentials secret is created (if using Kafka auto-scaling)
- [ ] ArgoCD has access to the Helm chart repository

## Additional Resources

- [IAM Controller Documentation](https://github.com/aws-controllers-k8s/iam-controller)
- [KEDA Documentation](https://github.com/kedacore/charts)
- [kOps Documentation](https://kops.sigs.k8s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

# wakeboarduk-helm

Helm chart repo for the Wakeboard UK family of websites running on Kubernetes.

This repo contains one reusable application chart, [`wuk/`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk), plus environment-specific values files for four deployed environments:

| Environment | Website | Values file | Namespace convention |
| --- | --- | --- | --- |
| `wuk_prod` | `www.wakeboard.co.uk` | [`values/wuk_prod_values.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/values/wuk_prod_values.yaml) | `wuk-prod` |
| `wuk_test` | `test.wakeboard.co.uk` | [`values/wuk_test_values.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/values/wuk_test_values.yaml) | `wuk-test` |
| `wsf_prod` | `www.wakesurfuk.com` | [`values/wsf_prod_values.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/values/wsf_prod_values.yaml) | `wsf-prod` |
| `wdc_prod` | `www.wakeboard.com` | [`values/wdc_prod_values.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/values/wdc_prod_values.yaml) | `wdc-prod` |

## Repo layout

- [`wuk/`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk): shared Helm chart used for all sites/environments.
- [`values/`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/values): per-environment overrides such as hostname, site code, image tag, and environment name.
- [`update-ghcr-secrets.sh`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/update-ghcr-secrets.sh): helper script to recreate the GHCR image pull secret across all namespaces.

## How the chart works

The chart is a single web-app deployment template. Each environment changes behavior through values rather than through separate charts.

Core behavior:

- Deploys one Kubernetes `Deployment`, `Service`, optional `Ingress`, optional `HorizontalPodAutoscaler`, `ServiceAccount`, and a Helm test pod.
- Pulls the container image from GHCR using `image.repository` and `image.tag`.
- Exposes the app on container port `80` with `/` used for liveness and readiness probes.
- Mounts a Kubernetes secret at `/app/secrets`.
- Names the app settings secret using this convention:
  - `<site>-<environment>-appsettings-secret`
  - Example: `wuk-prod-appsettings-secret`
- Names TLS and ingress resources using the same `<site>-<environment>` pattern.

The `site` and `environment` values are important because they drive naming for supporting resources:

- `site: wuk` = Wakeboard UK
- `site: wsf` = Wakesurf UK
- `site: wdc` = Wakeboard.com
- `environment: prod` or `environment: test`

## Environment differences

Each values file mainly sets:

- `site`
- `environment`
- `ingress.host`
- `image.tag`
- `imagePullSecrets`
- `replicaCount`

Current host mappings:

- `wuk_prod` -> `www.wakeboard.co.uk`
- `wuk_test` -> `test.wakeboard.co.uk`
- `wsf_prod` -> `www.wakesurfuk.com`
- `wdc_prod` -> `www.wakeboard.com`

All current environments use the same GHCR repository:

- `ghcr.io/jeremynevill/wakeboarduk`

The deployed image version is controlled independently per values file via `image.tag`.

## Required Kubernetes prerequisites

Before deploying an environment, the target namespace should already have:

1. A GHCR pull secret named `ghcr-login-secret`
2. An application settings secret named `<site>-<environment>-appsettings-secret`
3. A TLS secret named `<site>-<environment>-tls-secret` if ingress is enabled

The chart references these secrets but does not create them.

## GHCR pull secret management

Use [`update-ghcr-secrets.sh`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/update-ghcr-secrets.sh) to recreate `ghcr-login-secret` in:

- `wuk-prod`
- `wuk-test`
- `wsf-prod`
- `wdc-prod`

Usage:

```bash
./update-ghcr-secrets.sh <github-token>
```

Example:

```bash
./update-ghcr-secrets.sh ghp_xxxxxxxxxxxx
```

This script:

- checks whether each namespace exists
- deletes any existing `ghcr-login-secret`
- recreates the secret as a Docker registry secret for `ghcr.io`

## Helm usage

Typical pattern:

```bash
helm upgrade --install <release-name> ./wuk \
  --namespace <namespace> \
  --create-namespace \
  -f <values-file>
```

Examples:

```bash
helm upgrade --install wuk-prod ./wuk \
  --namespace wuk-prod \
  --create-namespace \
  -f values/wuk_prod_values.yaml
```

```bash
helm upgrade --install wuk-test ./wuk \
  --namespace wuk-test \
  --create-namespace \
  -f values/wuk_test_values.yaml
```

```bash
helm upgrade --install wsf-prod ./wuk \
  --namespace wsf-prod \
  --create-namespace \
  -f values/wsf_prod_values.yaml
```

```bash
helm upgrade --install wdc-prod ./wuk \
  --namespace wdc-prod \
  --create-namespace \
  -f values/wdc_prod_values.yaml
```

## What gets rendered

From the chart templates in [`wuk/templates/`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates):

- [`deployment.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates/deployment.yaml): main app deployment, image pull secrets, probes, and mounted app settings secret.
- [`service.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates/service.yaml): ClusterIP service on port `80`.
- [`ingress.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates/ingress.yaml): nginx ingress with TLS using `ingress.host`.
- [`hpa.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates/hpa.yaml): optional autoscaling resource when `autoscaling.enabled=true`.
- [`serviceaccount.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates/serviceaccount.yaml): service account for the workload.
- [`tests/test-connection.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/templates/tests/test-connection.yaml): simple Helm connectivity test.

## Notes

- The chart defaults live in [`wuk/values.yaml`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/wuk/values.yaml), and the files under [`values/`](/Users/jeremy/Documents/GitHub/wakeboarduk-helm/values) override them per environment.
- Autoscaling is currently disabled by default.
- Release naming should follow the same namespace pattern where possible, because generated object names are based on the Helm release name plus the chart name.

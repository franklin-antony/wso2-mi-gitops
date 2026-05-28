# WSO2 MI GitOps CD Repository

**Continuous Deployment (CD)** infrastructure for WSO2 Micro Integrator 4.3.x deployments to Kubernetes via ArgoCD.

## 🏗️ Architecture

This repository is part of a three-component GitOps architecture:

```
┌──────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│   Base Image             │      │  Integration CI         │      │   This GitOps CD Repo   │
│   (Built Here)           │      │  (External Repo)        │      │   (Deployment)          │
├──────────────────────────┤      ├─────────────────────────┤      ├─────────────────────────┤
│ • Hardened WSO2 MI 4.3.x │      │ • Integration source    │      │ • Download CARs from CI │
│ • Weekly security scans  │      │ • Maven builds          │      │ • Use pre-built base    │
│ • Push to ghcr.io        │      │ • Build .car files      │      │ • Build runtime image   │
│                          │      │ • Store in /carbonapps  │      │ • Run smoke tests       │
│ wso2-mi-base             │      │ • Trigger CD workflow   │      │ • Helm charts           │
└──────────────────────────┘      └─────────────────────────┘      │ • ArgoCD manifests      │
          │                                     │                    │                         │
          │ Published Once (weekly updates)    │ Triggers on       │ Runtime:                │
          │                                     │ every CAR change   │ wso2-mi-runtime         │
          └─────────────────────────────────────┴────────────────────> (base + CARs)          │
                                                                     └─────────────────────────┘
                                                                               │
                                                                               │ GitOps Sync
                                                                               ▼
                                                                     ┌─────────────────────────┐
                                                                     │   ArgoCD                │
                                                                     │   ├── Dev (auto-sync)   │
                                                                     │   ├── Staging (auto)    │
                                                                     │   └── Prod (manual)     │
                                                                     └─────────────────────────┘
```

### Component Responsibilities

1. **Base Image (This Repo):**
   - Builds security-hardened WSO2 MI 4.3.x base image
   - Weekly automated security scans with Trivy
   - Published to `ghcr.io/franklin-antony/wso2-mi-base:4.3.0-hardened-latest`
   - **Updated rarely** (weekly security patches only)

2. **Integration CI (External Repo):**
   - Contains WSO2 integration project source code
   - Builds CAR files using Maven
   - Stores built CARs in `/carbonapps/*.car`
   - Triggers this CD repo via `repository_dispatch` webhook
   - **Updates frequently** (on every integration change)

3. **This CD Repo (Deployment):**
   - Downloads pre-built CARs from Integration CI repo
   - Builds runtime Docker image (base + CARs)
   - Runs smoke tests and security scans
   - Publishes to `ghcr.io/franklin-antony/wso2-mi-runtime:{env}-{version}`
   - Manages Helm charts and ArgoCD configurations
   - **Orchestrates deployment** to Kubernetes clusters

## 🚀 Quick Start

### Prerequisites

- **Docker** - For local image builds
- **kubectl** - Kubernetes CLI
- **Helm 3+** - Kubernetes package manager
- **ArgoCD** - GitOps continuous delivery tool
- **GitHub CLI (`gh`)** - For triggering workflows

### 1. Build Base Image

The base image should be built once initially, then weekly automatically:

```bash
# Trigger base image build manually
gh workflow run build-base-image.yml

# Monitor progress
gh run watch

# Verify image is available
docker pull ghcr.io/franklin-antony/wso2-mi-base:4.3.0-hardened-latest
```

### 2. Trigger Runtime Build

Once the base image is ready, you can build runtime images:

```bash
# Manual trigger (for testing)
./scripts/trigger-runtime-build.sh \
  https://github.com/franklin-antony/wso2-integrations \
  main \
  dev
```

**Normal Flow:** Integration CI repo automatically triggers builds via webhook when CARs change.

### 3. Deploy to Kubernetes

#### Local Testing (Minikube/Kind)

```bash
# Install Helm chart
helm install wso2-mi-dev ./helm/wso2-mi \
  -f ./helm/wso2-mi/values-dev.yaml \
  --namespace wso2-mi-dev \
  --create-namespace

# Check deployment
kubectl get pods -n wso2-mi-dev

# Port-forward to test
kubectl port-forward -n wso2-mi-dev svc/wso2-mi 8290:8290
curl http://localhost:8290/services
```

#### Production (ArgoCD)

```bash
# Setup ArgoCD Applications
kubectl apply -f argocd/appproject.yaml
kubectl apply -f argocd/application-dev.yaml
kubectl apply -f argocd/application-prod.yaml

# Monitor sync status
argocd app get wso2-mi-dev
```

## 📁 Repository Structure

```
wso2-MI-GitOps/
├── .github/workflows/           # GitHub Actions pipelines
│   ├── build-base-image.yml     # Weekly base image build + scan
│   └── build-runtime-image.yml  # Runtime build (triggered by Integration CI)
├── docker/
│   ├── base/                    # Hardened WSO2 MI base image
│   │   ├── Dockerfile
│   │   ├── hardening-scripts/
│   │   └── .trivyignore
│   └── runtime/                 # Runtime image (base + CARs)
│       ├── Dockerfile
│       ├── download-cars.sh
│       ├── smoke-test.sh
│       └── entrypoint.sh
├── helm/wso2-mi/                # Kubernetes Helm chart
│   ├── Chart.yaml
│   ├── values.yaml              # Base configuration
│   ├── values-dev.yaml          # Dev overrides (auto-sync)
│   ├── values-prod.yaml         # Prod overrides (manual sync)
│   ├── templates/               # K8s resource templates
│   └── configs/                 # MI configuration files
├── argocd/                      # ArgoCD Application definitions
│   ├── appproject.yaml          # Project with RBAC
│   ├── application-dev.yaml     # Dev environment
│   └── application-prod.yaml    # Prod environment
├── scripts/                     # Helper automation scripts
│   ├── trigger-base-build.sh
│   ├── trigger-runtime-build.sh
│   ├── validate-helm.sh
│   └── local-test.sh
└── docs/                        # Detailed documentation
    ├── 01-architecture.md
    ├── 02-base-image.md
    ├── 03-deployment-workflow.md
    ├── 04-argocd-setup.md
    └── 05-troubleshooting.md
```

## 🔐 Security Scanning

Every image build includes Trivy security scanning:

- **Base Image:** Scanned weekly, must pass (no CRITICAL/HIGH vulnerabilities)
- **Runtime Image:** Scanned on every build before pushing to registry
- **Results:** Uploaded to GitHub Security tab (SARIF format)

View scan results:
```bash
# In GitHub UI: Security → Code scanning alerts
# Or via CLI
gh api repos/{owner}/{repo}/code-scanning/alerts
```

## 🔄 Deployment Workflow

### How Integration CI Triggers Deployment

The Integration CI repo sends a `repository_dispatch` webhook:

```bash
curl -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/repos/franklin-antony/wso2-MI-GitOps/dispatches \
  -d '{
    "event_type": "new-integration-build",
    "client_payload": {
      "repo_url": "https://github.com/franklin-antony/wso2-integrations",
      "ref": "main",
      "environment": "dev"
    }
  }'
```

### Full Deployment Flow

1. **Integration CI** builds new CAR files
2. **Webhook triggers** this CD repo's `build-runtime-image.yml` workflow
3. **CD downloads** CARs from Integration CI repo (sparse Git checkout)
4. **Docker builds** runtime image using pre-built base + downloaded CARs
5. **Smoke tests** validate MI starts and CARs deploy correctly
6. **Trivy scans** runtime image for vulnerabilities
7. **Image pushed** to ghcr.io with versioned tag
8. **Helm values updated** (auto for dev/staging, manual PR for prod)
9. **ArgoCD syncs** new image to Kubernetes cluster
10. **Rolling update** deploys new pods with zero downtime

## 🛠️ Development & Testing

### Local Docker Build

```bash
# Build runtime image locally
./scripts/local-test.sh https://github.com/franklin-antony/wso2-integrations main

# This will:
# - Download CARs from the Integration CI repo
# - Build the Docker image
# - Run smoke tests
```

### Validate Helm Templates

```bash
# Dry-run template rendering
./scripts/validate-helm.sh

# Test installation (doesn't deploy)
helm install wso2-mi-dev ./helm/wso2-mi \
  -f ./helm/wso2-mi/values-dev.yaml \
  --dry-run --debug
```

## 📚 Documentation

- **[Architecture](docs/01-architecture.md)** - Detailed three-repo architecture
- **[Base Image](docs/02-base-image.md)** - Hardening process and security
- **[Deployment Workflow](docs/03-deployment-workflow.md)** - Step-by-step CD pipeline
- **[ArgoCD Setup](docs/04-argocd-setup.md)** - GitOps configuration
- **[Troubleshooting](docs/05-troubleshooting.md)** - Common issues and solutions

## 🤝 Contributing

### Making Changes

1. **Base image changes:** Edit `docker/base/`, test locally, then trigger build
2. **Runtime changes:** Edit `docker/runtime/`, test with local-test.sh
3. **Helm changes:** Edit `helm/wso2-mi/`, validate with validate-helm.sh
4. **ArgoCD changes:** Edit `argocd/`, apply to test cluster first

### Testing Checklist

- [ ] Base image builds without errors
- [ ] Base image passes Trivy scan (no CRITICAL/HIGH)
- [ ] Runtime image builds with test CARs
- [ ] Smoke tests pass
- [ ] Helm templates render correctly
- [ ] Local K8s deployment succeeds
- [ ] ArgoCD can sync the application

## 📋 Related Repositories

- **Integration CI Repo:** [Link to integration source code repo]
- **Base Image Security Reports:** Check GitHub Security tab

## 📄 License

[Your License Here]

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/franklin-antony/wso2-MI-GitOps/issues)
- **Documentation:** See `docs/` folder
- **Team Contact:** platform-team@example.com

# Testing Guide

## Pre-Push Checklist ✅

- [x] GitHub owner/org updated: `franklin-antony`
- [x] Dockerfiles updated with correct repository references
- [x] README.md placeholders replaced

## Step 1: Push to GitHub

```bash
# Stage all files
git add .

# Commit
git commit -m "feat: Initial CD infrastructure for WSO2 MI

- Base image with security hardening (Trivy scanning)
- Runtime image with CAR download from Integration CI
- GitHub Actions workflows for automated builds
- Helper scripts for local testing
- Comprehensive documentation"

# Push to main branch
git push origin main
```

## Step 2: Enable GitHub Actions

1. Go to your repository: https://github.com/franklin-antony/wso2-mi-gitops
2. Click **Actions** tab
3. Enable workflows if prompted

## Step 3: Configure GitHub Packages Permissions

For images to push to `ghcr.io`, you need to ensure the repository has proper permissions:

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Select: **Read and write permissions**
4. Check: **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

## Step 4: Test Base Image Build

### Option A: Automatic Trigger (on push)
The workflow should trigger automatically since we're pushing changes to `docker/base/**`.

### Option B: Manual Trigger
```bash
# Using GitHub CLI
gh workflow run build-base-image.yml

# Monitor the run
gh run watch
```

### Option C: GitHub UI
1. Go to **Actions** tab
2. Click **Build Hardened Base Image** workflow
3. Click **Run workflow** button
4. Select branch: `main`
5. Click **Run workflow**

## Expected Results for Base Image Build

✅ **Success Indicators:**
- Workflow completes without errors (green checkmark)
- Trivy scan passes (no CRITICAL/HIGH vulnerabilities)
- Image pushed to: `ghcr.io/franklin-antony/wso2-mi-base:4.3.0-hardened-latest`
- Security scan results uploaded to **Security** tab

❌ **Common Issues:**

1. **Trivy scan fails with vulnerabilities**
   - Check the scan report in job logs
   - Add acceptable CVEs to `docker/base/.trivyignore` if justified
   - Wait for WSO2 to release patched version

2. **Docker build fails**
   - Check if WSO2 official image is accessible: `wso2/wso2mi:4.3.0`
   - Verify Dockerfile syntax
   - Check hardening scripts execute without errors

3. **Permission denied pushing to ghcr.io**
   - Verify workflow permissions are set to "Read and write"
   - Check GITHUB_TOKEN has `packages: write` permission

## Step 5: Verify Base Image

Once the base image build succeeds:

```bash
# Pull the image locally (requires GitHub authentication)
echo $GITHUB_TOKEN | docker login ghcr.io -u franklin-antony --password-stdin

# Pull the image
docker pull ghcr.io/franklin-antony/wso2-mi-base:4.3.0-hardened-latest

# Verify it runs
docker run --rm ghcr.io/franklin-antony/wso2-mi-base:4.3.0-hardened-latest \
  /home/wso2carbon/wso2mi-4.3.0/bin/version.sh

# Should output WSO2 MI version information
```

## Step 6: Test Runtime Image Build (After Base Image Success)

**Note:** Runtime image build requires an Integration CI repository with CARs.
For initial testing, we'll need to either:

### Option A: Create a Test Integration Repository

Create a minimal test repository with structure:
```
test-integrations/
├── carbonapps/
│   └── TestHelloWorld_1.0.0.car  (sample CAR file)
└── README.md
```

Then trigger:
```bash
gh workflow run build-runtime-image.yml \
  -f integration_repo_url="https://github.com/franklin-antony/test-integrations" \
  -f integration_repo_ref="main" \
  -f environment="dev"
```

### Option B: Skip Runtime Build for Now

Focus on verifying the base image works, then create Integration CI repository before testing runtime builds.

## Troubleshooting

### Check Workflow Logs
```bash
# List recent runs
gh run list --limit 5

# View logs for a specific run
gh run view <run-id> --log
```

### Check Image in GitHub Packages
1. Go to your repository
2. Click **Packages** (right sidebar)
3. You should see `wso2-mi-base` listed
4. Click on it to view tags and download instructions

### Test Locally Before Push
```bash
# Build base image locally
cd docker/base
docker build -t wso2-mi-base:local .

# Run locally
docker run --rm -p 8290:8290 -p 9201:9201 wso2-mi-base:local
```

## Success Criteria

- [x] Files pushed to GitHub successfully
- [ ] GitHub Actions workflows appear in Actions tab
- [ ] Base image workflow triggers (automatically or manually)
- [ ] Base image builds successfully
- [ ] Trivy scan passes
- [ ] Image pushed to ghcr.io/franklin-antony/wso2-mi-base
- [ ] Security scan results visible in Security tab
- [ ] Image can be pulled and run locally

## Next Steps After Successful Test

1. ✅ Base image infrastructure working
2. Create Integration CI test repository
3. Test runtime image build
4. Continue with Helm charts
5. Setup ArgoCD

## Getting Help

If you encounter issues:

1. **Check workflow logs** in GitHub Actions tab
2. **Check Security tab** for Trivy scan results
3. **Verify permissions** in repository Settings → Actions
4. **Test locally** before pushing changes
5. **Share error messages** from workflow logs for debugging

---

**Current Status:** Ready to push and test base image build! 🚀

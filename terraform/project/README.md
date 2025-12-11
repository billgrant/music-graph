# Terraform - Project-Level Resources

This Terraform configuration manages **project-level GCP resources** that are shared across all environments (dev and prod).

## What This Manages

### Google Container Registry Lifecycle Policy

Automatic cleanup policy for Docker images in GCR:

**Development Images** (tagged with `dev-` prefix):
- Keep last **20 images** for rollback capability
- Delete images older than **30 days**
- Provides recent deployment history without accumulating hundreds of images

**Production Releases** (tagged with `v*`, `production`, `latest`):
- **Keep indefinitely**
- Never auto-deleted
- Maintains complete production deployment history

## Usage

### Initialize Terraform
```bash
cd terraform/project
terraform init
```

### Review Changes
```bash
terraform plan
```

### Apply Changes
```bash
terraform apply
```

## Why Separate from Environments?

The GCR lifecycle policy:
- Affects the **entire container registry** (project-level resource)
- Is **not environment-specific** (applies to both dev and prod images)
- Should **not** be managed with workspace-specific infrastructure

This separation follows Terraform best practices for managing shared resources.

## Cost Impact

**Before lifecycle policy:**
- Images accumulate indefinitely
- After 100 commits: ~$1.60/month
- After 1000 commits: ~$16/month

**After lifecycle policy:**
- ~20 dev images + production releases
- ~$0.35-0.50/month baseline
- **70-90% reduction** in GCR storage costs

## Related

- Part of Phase 7 (CI/CD and DevOps)
- Implements GitHub Issue #8 (CI/CD optimization)

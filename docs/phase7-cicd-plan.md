# Phase 7: CI/CD and DevOps - Implementation Plan

**Status:** Phase 1 & 2 Complete (CI Setup + Dev Environment)
**Date:** December 8, 2025
**Last Updated:** December 8, 2025

## Overview

Phase 7 focuses on implementing automated testing, continuous integration, and continuous deployment with separate dev and production environments. This document tracks progress and outlines remaining steps.

## Phase 7 Goals

- ✅ GitHub Actions for automated testing
- ✅ Separate dev/staging environment
- ⏳ Automated deployment to dev
- ⏳ Manual/automated promotion to production
- ⏳ Database backup strategies
- ⏳ Fix certbot auto-renewal with IP restrictions

## Phase 1: CI Setup ✅ (Complete)

### What We Built

1. **Test Suite Structure**
   - `tests/` directory with pytest configuration
   - `tests/conftest.py` - fixtures for app, client, sample data
   - `tests/test_basic.py` - smoke tests
   - `tests/test_models.py` - database model tests
   - `tests/test_routes.py` - Flask route tests

2. **Testing Infrastructure**
   - Added pytest, pytest-cov, pytest-flask, flake8 to requirements.txt
   - Created `.flake8` configuration for linting
   - Created `pytest.ini` for test configuration with coverage

3. **GitHub Actions CI Workflow**
   - `.github/workflows/ci.yml`
   - Runs on push to main and pull requests
   - Executes linting (flake8) and tests (pytest)
   - Generates code coverage reports
   - Python 3.12 on Ubuntu

### Testing Locally

```bash
# Install test dependencies
pip install -r requirements.txt

# Run tests
pytest

# Run tests with coverage
pytest --cov

# Run linting
flake8 .
```

### Next Steps After CI

Before pushing these changes:
1. Test locally to ensure all tests pass
2. Fix any linting issues that flake8 finds
3. Review test coverage and add tests as needed

## Phase 2: Dev Environment Setup ✅ (Complete)

### What We Built

1. **Separate GCP VM**
   - VM: `dev-music-graph` (e2-micro)
   - IP: 34.139.187.195
   - Zone: us-east1-b
   - Cost: ~$10/month

2. **Terraform Workspaces**
   - `prod` workspace - manages production VM
   - `dev` workspace - manages dev VM
   - Isolated state files prevent accidental infrastructure changes

3. **Dev Environment Configuration**
   - `docker-compose.dev.yml` - Dev stack configuration
   - `.env.dev.example` - Environment variables template
   - Separate PostgreSQL database (`musicgraph`)

4. **Domain and SSL**
   - URL: https://dev.music-graph.billgrant.io
   - Let's Encrypt SSL certificate via certbot
   - Nginx reverse proxy to Flask app

5. **Database Initialization**
   - Fixed `entrypoint.sh` to automatically initialize database
   - Handles both fresh and existing database scenarios
   - Proper error handling and logging

### Issues Encountered and Fixed

1. **Terraform Workspace Confusion**
   - Problem: Initial plan would have replaced prod VM
   - Solution: Implemented Terraform workspaces for state isolation
   - Learning: Always verify workspace before terraform commands

2. **Startup Script Variables**
   - Problem: SSH_USER variable not passed to startup script
   - Attempted: templatefile() solution caused prod replacement risk
   - Resolution: Reverted to simple script, manual docker group setup
   - Created: Issue #7 for Packer/Ansible automation

3. **Database Name Mismatch**
   - Problem: docker-compose created `musicgraph_dev`, entrypoint expected `musicgraph`
   - Solution: Changed docker-compose to use `musicgraph` database name
   - Fixed: Updated .env.dev.example to match

4. **Entrypoint Script Exit on Error**
   - Problem: `set -e` caused script to exit before running init_db.py
   - Solution: Temporarily disable `set -e` during database check
   - Capture exit code, then re-enable strict mode
   - Now properly initializes database on first run

### Current State

**Production:**
- URL: https://music-graph.billgrant.io
- VM: `prod-music-graph`
- Workspace: `prod`
- Status: Running, unaffected by dev setup

**Development:**
- URL: https://dev.music-graph.billgrant.io
- VM: `dev-music-graph`
- IP: 34.139.187.195
- Workspace: `dev`
- Status: Fully operational, database initializing correctly

### Documentation Created

- `docs/dev-environment-setup.md` - Complete deployment guide
- `docs/terraform-workspace-guide.md` - Workspace management reference
- Updated `docker-compose.dev.yml` and `.env.dev.example`

## Phase 3: CD to Dev (Next)

### Infrastructure Requirements

1. **GCP Resources Needed**
   - New Compute Engine VM for dev environment
   - Or: Separate docker-compose stack on existing VM
   - Consider: Cloud SQL instance or separate PostgreSQL container

2. **Configuration Files to Create**
   - `docker-compose.dev.yml` - Dev environment compose file
   - `.env.dev` - Dev environment variables
   - Terraform updates for dev infrastructure (if separate VM)

3. **Domain/Networking**
   - Subdomain: `dev.music-graph.billgrant.io`
   - Nginx configuration for dev
   - SSL certificate for dev subdomain
   - Firewall rules (same IP restrictions as prod)

### Implementation Steps

1. **Option A: Separate VM (Recommended)**
   ```bash
   # Terraform changes needed:
   # - Add dev VM resource
   # - Add firewall rules for dev
   # - Add load balancer if needed

   terraform/
   ├── main.tf           # Add dev VM
   ├── network.tf        # Add dev firewall rules
   └── outputs.tf        # Add dev VM outputs
   ```

2. **Option B: Same VM, Separate Stack**
   ```bash
   # On existing VM, run dev stack on different ports
   # Nginx routes dev.music-graph.billgrant.io to dev stack

   docker-compose.dev.yml:
   ports:
     - "127.0.0.1:5001:5000"  # Different port
   ```

3. **Database Strategy**
   - Dev needs its own PostgreSQL instance
   - Separate database or separate container
   - Consider periodic copy of prod data to dev (anonymized)

## Phase 3: CD to Dev (After Phase 2)

### Workflow Design

Create `.github/workflows/deploy-dev.yml`:

```yaml
name: Deploy to Dev

on:
  push:
    branches: [ main ]
  workflow_dispatch:  # Manual trigger option

jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [test]  # Run after CI passes

    steps:
      - Build Docker image
      - Push to Google Container Registry (GCR)
      - SSH to dev VM
      - Pull latest image
      - Restart containers
      - Run database migrations if needed
      - Health check
```

### Secrets Configuration

GitHub repository secrets needed:
- `GCP_SA_KEY` - Service account for GCR
- `GCP_PROJECT_ID` - Your GCP project
- `DEV_SSH_PRIVATE_KEY` - SSH key for dev VM
- `DEV_HOST` - Dev VM IP or hostname
- `PROD_SSH_PRIVATE_KEY` - SSH key for prod VM
- `PROD_HOST` - Prod VM IP or hostname

### Docker Registry Setup

```bash
# Enable Container Registry in GCP
gcloud services enable containerregistry.googleapis.com

# Configure Docker to use GCR
gcloud auth configure-docker

# Tag and push images
docker tag music-graph:latest gcr.io/YOUR-PROJECT/music-graph:latest
docker push gcr.io/YOUR-PROJECT/music-graph:latest
```

## Phase 4: Production Deployment (Final Step)

### Manual Promotion

Create `.github/workflows/deploy-prod.yml`:
- **Triggered manually** via workflow_dispatch
- Requires approval/confirmation
- Promotes tested dev image to production
- Creates GitHub release/tag
- Rollback capability

### Deployment Process

1. Changes merge to main
2. CI runs automatically
3. If CI passes, auto-deploy to dev
4. Test in dev environment
5. Manually trigger prod deployment when ready
6. Prod deployment uses same Docker image as dev

### Rollback Strategy

```bash
# Tag images with git commit SHA
docker tag music-graph:latest gcr.io/PROJECT/music-graph:${GITHUB_SHA}

# Can rollback to any previous SHA
docker pull gcr.io/PROJECT/music-graph:abc123
```

## Database Backups

### Automated Backup Strategy

1. **Daily Backups**
   ```bash
   # Cron job on VM or GitHub Actions scheduled workflow
   pg_dump -h localhost -U musicgraph -d musicgraph > backup.sql

   # Upload to Google Cloud Storage
   gsutil cp backup.sql gs://music-graph-backups/$(date +%Y%m%d).sql
   ```

2. **Pre-deployment Backups**
   - Automatic backup before each production deployment
   - Stored in GCS with deployment tag/commit

3. **Retention Policy**
   - Daily: Keep 7 days
   - Weekly: Keep 4 weeks
   - Monthly: Keep 12 months

### Restore Procedure

```bash
# Download backup from GCS
gsutil cp gs://music-graph-backups/20251208.sql backup.sql

# Restore to database
psql -h localhost -U musicgraph -d musicgraph < backup.sql
```

## Certbot Auto-renewal Fix

### Current Issue
- IP-restricted firewall blocks certbot challenge
- Need to temporarily open port 80 during renewal

### Solution Options

1. **Firewall automation**
   ```bash
   # Pre-renewal: Open port 80
   # Post-renewal: Close port 80
   # Add to certbot renewal hooks
   ```

2. **DNS-01 challenge** (Better)
   ```bash
   # Use DNS validation instead of HTTP
   # No need to open port 80
   # Requires API access to DNS provider
   certbot certonly --dns-google --dns-google-credentials ~/gcp-dns.json
   ```

3. **Separate renewal VM**
   - Dedicated VM for cert renewal
   - Sync certs to prod/dev VMs
   - More complex but cleaner separation

## Testing Strategy

### What to Test in Dev

- Database migrations
- New features
- UI changes
- API changes
- Performance impact
- Integration with external services

### Smoke Tests for Production

After deployment, run automated checks:
- Homepage loads
- Login works
- Graph renders
- Database queries succeed
- API responds

## Success Criteria for Phase 7

- ✅ CI pipeline runs tests on every PR and push
- ⏳ Dev environment mirrors production
- ⏳ Automatic deployment to dev on merge to main
- ⏳ Manual deployment to prod with one click
- ⏳ Database backups automated and tested
- ⏳ Certbot auto-renewal works without manual intervention
- ⏳ Rollback procedure documented and tested

## Cost Considerations

### Additional GCP Costs

- Dev VM: ~$10-20/month (f1-micro or e2-micro)
- Or: No additional cost if using same VM
- Cloud Storage for backups: ~$1-5/month
- Container Registry: Free tier sufficient for now

### Alternatives to Reduce Cost

- Use same VM for dev and prod (different ports)
- SQLite for dev (simpler but different from prod)
- Skip staging, deploy straight to prod (riskier)

## Open Questions

1. **Dev Environment**: Separate VM or same VM?
2. **Database**: How to handle dev data? Copy from prod?
3. **Certbot**: DNS-01 challenge or firewall automation?
4. **Deployment Trigger**: Auto to prod or always manual approval?
5. **Monitoring**: Add health checks and alerting in Phase 7?

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Container Registry](https://cloud.google.com/container-registry)
- [Certbot DNS Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)
- [PostgreSQL Backup Best Practices](https://www.postgresql.org/docs/current/backup.html)

---

**Next Action**: Test CI locally, then push to trigger first GitHub Actions run.

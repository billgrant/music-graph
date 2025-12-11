# Phase 7: CI/CD and DevOps - Implementation Plan

**Status:** Phase 1, 2, 3 & 4 Complete (CI + Dev + Production Deployment)
**Date:** December 8, 2025
**Last Updated:** December 10, 2025

## Overview

Phase 7 focuses on implementing automated testing, continuous integration, and continuous deployment with separate dev and production environments. This document tracks progress and outlines remaining steps.

## Phase 7 Goals

- ✅ GitHub Actions for automated testing
- ✅ Separate dev/staging environment
- ✅ Automated deployment to dev
- ✅ Manual promotion to production with versioning
- ⏳ Database backup strategies (daily backups, retention policies)
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

## Phase 3: Automated Deployment to Dev ✅ (Complete)

### What We Built

1. **GitHub Actions Deployment Workflow**
   - `.github/workflows/deploy-dev.yml`
   - Triggers on push to main branch or manual trigger
   - Three jobs: test → build-and-push → deploy-to-dev
   - Reuses CI workflow for testing (DRY principle)

2. **Google Container Registry (GCR) Integration**
   - Enabled Artifact Registry API in GCP
   - Created service account with `artifactregistry.writer` permission
   - Configured GitHub Actions authentication via service account key
   - Images tagged with both git SHA and 'latest' for traceability

3. **VM Service Account Configuration**
   - Added `service_account` block to Terraform configuration
   - Attached default compute engine service account to VMs
   - Granted `artifactregistry.reader` permission for pulling images
   - Configured `cloud-platform` scope for full GCP API access

4. **Automated Deployment Process**
   ```
   Push to main → CI tests → Build image → Push to GCR → Deploy to VM
   ```

   On the VM:
   - Pull latest code and configs with `git pull`
   - Authenticate gcloud via metadata service
   - Configure Docker to use gcloud credential helper
   - Pull latest image from GCR
   - Stop and remove old containers
   - Start fresh containers with new image

### Issues Encountered and Fixed

1. **CI Workflow Not Reusable**
   - Problem: deploy-dev.yml tried to call ci.yml but got error
   - Solution: Added `workflow_call:` trigger to ci.yml
   - Learning: Workflows need explicit trigger to be callable

2. **GCR Authentication in GitHub Actions**
   - Problem: gcloud CLI not authenticated in GitHub Actions runner
   - Solution: Use `google-github-actions/auth@v2` before setup-gcloud
   - Learning: Order of operations matters for GCP authentication

3. **Artifact Registry API Not Enabled**
   - Problem: Push to GCR failed with "API has not been used" error
   - Solution: Enabled Artifact Registry API in GCP console
   - Learning: GCR now uses Artifact Registry backend

4. **Service Account Missing Permissions**
   - Problem: Permission denied when pushing to GCR
   - Solution: Granted `artifactregistry.writer` role to service account
   - Learning: Need explicit IAM permissions even with service account

5. **VM Can't Pull from GCR - No Service Account**
   - Problem: Metadata service returned 404 for service account
   - Solution: Added `service_account` block to Terraform VM configuration
   - Learning: VMs don't automatically have service accounts attached
   - Root cause: This was the core issue preventing all authentication

6. **VM Can't Pull from GCR - Missing Reader Permission**
   - Problem: Unauthenticated request errors when pulling
   - Solution: Granted `artifactregistry.reader` to compute service account
   - Learning: VMs need explicit read permissions to GCR

7. **Metadata Service URL Resolution**
   - Problem: `metadata.google.internal` hostname not resolving
   - Solution: Use IP address `169.254.169.254` directly
   - Learning: Link-local metadata IP is more reliable than hostname

8. **Container Using Old Locally-Built Image**
   - Problem: Containers recreated but still used locally-built image
   - Solution: Added `git pull` to sync latest docker-compose.dev.yml
   - Learning: VM had outdated compose file that specified `build: .`
   - Fix: Pull code before deployment to ensure configs are current

### How Automated Deployment Works

**Trigger:** Push to main or manual workflow dispatch

**Job 1: Test**
- Reuses `.github/workflows/ci.yml`
- Runs flake8 linting and pytest tests
- Uploads coverage reports

**Job 2: Build and Push**
- Checks out code
- Authenticates to GCP with service account
- Builds Docker image
- Tags with git SHA and 'latest'
- Pushes both tags to GCR

**Job 3: Deploy to Dev**
- SSHs to dev VM
- Pulls latest code (`git pull origin main`)
- Authenticates gcloud using VM's service account from metadata service
- Configures Docker to use gcloud credential helper
- Pulls latest image from GCR
- Stops and removes old containers (`docker-compose down`)
- Starts fresh containers (`docker-compose up -d`)
- Shows deployment status

### GitHub Secrets Configuration

Required repository secrets:
- `GCP_SA_KEY` - Service account JSON key for GCR access
- `GCP_PROJECT_ID` - GCP project ID (music-graph-479719)
- `DEV_SSH_PRIVATE_KEY` - SSH private key for dev VM
- `DEV_HOST` - Dev VM IP address (34.139.187.195)
- `DEV_USER` - SSH username for dev VM

### Current State

**Automated Deployment:**
- ✅ Fully functional end-to-end deployment
- ✅ Deploys on every push to main
- ✅ Can also be triggered manually
- ✅ Uses GCR images (not locally built)
- ✅ Proper authentication via metadata service
- ✅ Clean container recreation on each deploy

**Verification:**
```bash
# On dev VM, verify containers are using GCR image:
docker-compose -f docker-compose.dev.yml ps

# Should show:
# music-graph-web-1   gcr.io/music-graph-479719/music-graph:latest
```

**URLs:**
- Dev site: https://dev.music-graph.billgrant.io
- GitHub Actions: https://github.com/billgrant/music-graph/actions
- GCR Images: https://console.cloud.google.com/gcr/images/music-graph-479719

## Phase 4: Production Deployment ✅ (Complete)

### What We Built

1. **Production Deployment Workflow**
   - `.github/workflows/deploy-prod.yml`
   - Manual trigger only (workflow_dispatch) for production safety
   - Auto-increment version tagging with manual override
   - Deploys using `docker-compose.prod.yml`

2. **Flask-Migrate for Database Migrations**
   - Added `flask-migrate==4.0.5` to requirements.txt
   - Configured Flask-Migrate in app.py
   - Manual migrations during deployment (Issue #9 for automation)
   - Migration documentation in production-operations.md

3. **Version Management System**
   - Auto-increment: v0.x.0-alpha (e.g., v0.1.0-alpha → v0.2.0-alpha)
   - Manual override for version changes (alpha → beta → release)
   - Multi-tag strategy: version + SHA + production + latest
   - GitHub releases created automatically with deployment notes

4. **Pre-Deployment Backups**
   - Automatic database backup before each deployment
   - Saved to `~/backups/` on production VM
   - Timestamped: `musicgraph-YYYYMMDD-HHMMSS.sql`
   - Used for rollback if needed

5. **Production Docker Compose**
   - `docker-compose.prod.yml` configured for production
   - Uses GCR images (not local builds)
   - Uses `.env.prod` for secrets
   - Restart policies and health checks

6. **Comprehensive Documentation**
   - `docs/production-operations.md` - Complete operations guide
   - Migration procedures (create, run, rollback)
   - Deployment process step-by-step
   - Rollback procedures (quick, full, migration-only)
   - Emergency procedures
   - `.env.prod.example` for production secrets

### How Production Deployment Works

**Trigger:** Manual workflow dispatch from GitHub Actions

**Workflow Steps:**

1. **Run Tests** - Reuses CI workflow
2. **Determine Version**
   - Auto-increment from latest tag, OR
   - Use manually specified version
   - Preserves suffix (alpha/beta) or removes for release

3. **Build and Push**
   - Build Docker image
   - Tag with: version, git SHA, 'production', 'latest'
   - Push all tags to GCR

4. **Pre-Deployment Backup**
   - SSH to prod VM
   - Create timestamped database backup
   - Save to ~/backups/

5. **Deploy to Production**
   - Pull latest code (git pull)
   - **Display migration reminder** (manual step)
   - Authenticate gcloud via metadata service
   - Pull versioned image from GCR
   - Tag as 'latest' locally
   - Stop old containers
   - Start new containers with `docker-compose.prod.yml`

6. **Health Checks**
   - Verify containers are running
   - Test web app response
   - Report status

7. **Create GitHub Release**
   - Create git tag with version
   - Push tag to GitHub
   - Create release with deployment notes
   - Mark as latest release

### Prerequisites for Production Deployment

Before running the production deployment workflow, ensure:

1. **GitHub Secrets Configured**
   - `PROD_HOST` - Production VM hostname (e.g., music-graph.billgrant.io)
   - `PROD_USER` - SSH username for production VM
   - `PROD_SSH_PRIVATE_KEY` - SSH private key for authentication
   - `GCP_SA_KEY` - Service account JSON key (already set up for dev)
   - `GCP_PROJECT_ID` - GCP project ID (already set up for dev)

2. **SSH Key Setup**
   ```bash
   # Copy public key to production VM
   ssh-copy-id -i ~/.ssh/music-graph-deploy.pub user@production-vm
   ```

3. **GitHub Actions Permissions**
   - Go to: Settings → Actions → General → Workflow permissions
   - Select: "Read and write permissions"
   - Required for: Creating git tags and GitHub releases

4. **Production VM Configuration**
   - Service account attached (via Terraform)
   - Docker and docker-compose installed
   - Git repository cloned to ~/music-graph
   - .env.prod configured with production secrets
   - Flask-Migrate initialized (one-time setup)

### Version Examples

```
v0.1.0-alpha  (Phase 1 - CI Setup)
v0.2.0-alpha  (Phase 2 - Dev Environment)
v0.3.0-alpha  (Phase 3 - Dev Deployment)
v0.4.0-alpha  (Phase 4 - Prod Deployment)
...
v0.10.0-beta  (Manual override to switch to beta)
v0.11.0-beta  (Auto-increment continues with beta)
...
v1.0.0        (Manual override for first release)
```

### Manual Migration Process

During deployment, migrations must be run manually:

```bash
# 1. SSH to production VM
ssh user@prod-vm

# 2. Navigate to project
cd ~/music-graph

# 3. Run migrations
docker-compose -f docker-compose.prod.yml exec web flask db upgrade

# 4. Verify success
docker-compose -f docker-compose.prod.yml exec web flask db current
```

**Why manual?**
- Full control and visibility (good for learning)
- Can inspect database changes before proceeding
- Easy to rollback if issues arise
- Automated in future (Issue #9)

### Rollback Procedures

**Quick Rollback (Application Only):**
```bash
# Checkout previous version
git checkout <previous-commit>

# Pull previous image
docker pull gcr.io/music-graph-479719/music-graph:v0.3.0-alpha
docker tag gcr.io/music-graph-479719/music-graph:v0.3.0-alpha \
           gcr.io/music-graph-479719/music-graph:latest

# Restart
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

**Full Rollback (Application + Database):**
```bash
# Stop application
docker-compose -f docker-compose.prod.yml stop web

# Restore database from backup
BACKUP_FILE=$(ls -t ~/backups/musicgraph-*.sql | head -1)
docker-compose -f docker-compose.prod.yml exec -T db \
  psql -U musicgraph musicgraph < "$BACKUP_FILE"

# Rollback code and restart
git checkout <previous-commit>
docker pull gcr.io/music-graph-479719/music-graph:v0.3.0-alpha
docker tag gcr.io/music-graph-479719/music-graph:v0.3.0-alpha \
           gcr.io/music-graph-479719/music-graph:latest
docker-compose -f docker-compose.prod.yml up -d
```

See `docs/production-operations.md` for complete rollback procedures.

### Current State

**Production Deployment:**
- ✅ Manual trigger workflow configured
- ✅ Auto-increment versioning with override
- ✅ Pre-deployment backups automated
- ✅ Flask-Migrate configured
- ✅ Manual migration process documented
- ✅ Rollback procedures documented
- ✅ GitHub releases created automatically
- ✅ Multi-tag image strategy
- ✅ **First production deployment successful!**

**Documentation:**
- ✅ Production operations guide (migrations, deployment, rollback, emergency)
- ✅ .env.prod.example for secrets template
- ✅ Prerequisites documented (SSH setup, GitHub permissions)

**Verification:**
- ✅ Production VM using docker-compose.prod.yml
- ✅ Flask-Migrate initialized (baseline: revision 22564d35cf2d)
- ✅ GitHub Actions workflow tested end-to-end
- ✅ Pre-deployment backup created successfully
- ✅ Health checks passed
- ✅ GitHub release created automatically

**Phase 4 Complete!**

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
- ✅ Dev environment mirrors production
- ✅ Automatic deployment to dev on merge to main
- ✅ Manual deployment to prod with one click
- ✅ Rollback procedure documented and tested
- ⏳ CI/CD optimization: conditional builds and image retention (Issue #8)
- ⏳ Database backups automated and tested (daily backups, retention policies)
- ⏳ Certbot auto-renewal works without manual intervention

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

1. ~~**Dev Environment**: Separate VM or same VM?~~ ✅ Answered: Separate VM
2. **Database**: How to handle dev data? Copy from prod? Anonymize?
3. **Certbot**: DNS-01 challenge or firewall automation?
4. **Deployment Trigger**: Auto to prod or always manual approval?
5. **Monitoring**: Add health checks and alerting in Phase 7?
6. **Image Retention**: See Issue #8 for conditional builds and cleanup policy

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Container Registry](https://cloud.google.com/container-registry)
- [Certbot DNS Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)
- [PostgreSQL Backup Best Practices](https://www.postgresql.org/docs/current/backup.html)

---

**Next Action**: Test CI locally, then push to trigger first GitHub Actions run.

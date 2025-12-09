# Production Operations Guide

## Table of Contents
1. [Database Migrations](#database-migrations)
2. [Deployment Process](#deployment-process)
3. [Rollback Procedures](#rollback-procedures)
4. [Backup and Restore](#backup-and-restore)
5. [Emergency Procedures](#emergency-procedures)

---

## Database Migrations

### First-Time Setup (One-time)

When setting up Flask-Migrate for the first time on a VM:

```bash
# SSH to the VM
ssh user@prod-vm

# Navigate to project directory
cd ~/music-graph

# Initialize Flask-Migrate (creates migrations/ directory)
docker-compose -f docker-compose.prod.yml exec web flask db init

# Create initial migration from current schema
docker-compose -f docker-compose.prod.yml exec web flask db migrate -m "Initial migration"

# Review the generated migration file
docker-compose -f docker-compose.prod.yml exec web cat migrations/versions/*.py

# Apply the migration
docker-compose -f docker-compose.prod.yml exec web flask db upgrade
```

**Note:** The `migrations/` directory should be committed to git so all environments use the same migrations.

---

### Creating a New Migration

When you add/modify models in your code:

```bash
# 1. Update your model code in models.py
# 2. Commit the model changes

# 3. Generate migration
docker-compose -f docker-compose.prod.yml exec web flask db migrate -m "Add profile_picture to users"

# 4. ALWAYS review the generated migration
docker-compose -f docker-compose.prod.yml exec web cat migrations/versions/<timestamp>_add_profile_picture.py

# 5. Test in dev environment first
ssh dev-vm
cd ~/music-graph
docker-compose -f docker-compose.dev.yml exec web flask db upgrade

# 6. If successful, commit the migration file
git add migrations/versions/<timestamp>_add_profile_picture.py
git commit -m "Add migration: profile picture column"
git push

# 7. Deploy to production (migration will be run manually during deployment)
```

---

### Running Migrations in Production

**During deployment, migrations are run MANUALLY for safety.**

The deployment workflow will display this reminder:

```
=== MANUAL MIGRATION REQUIRED ===
Before deployment completes, you must run migrations manually:
  1. SSH to production VM
  2. Run: cd ~/music-graph && docker-compose -f docker-compose.prod.yml exec web flask db upgrade
  3. Verify migrations succeeded
```

**Steps:**

1. **Open a separate terminal and SSH to production:**
   ```bash
   ssh user@prod-vm
   cd ~/music-graph
   ```

2. **Check current migration status:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec web flask db current
   ```

3. **Review pending migrations:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec web flask db history
   ```

4. **Run migrations:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec web flask db upgrade
   ```

5. **Verify migration succeeded:**
   ```bash
   # Check migration status
   docker-compose -f docker-compose.prod.yml exec web flask db current

   # Check application logs
   docker-compose -f docker-compose.prod.yml logs web

   # Test the application
   curl -I https://music-graph.billgrant.io
   ```

6. **If migration failed, rollback immediately** (see Rollback section)

---

### Migration Best Practices

1. **Always backup before migrations** (deployment workflow does this automatically)
2. **Test migrations in dev first** before production
3. **Review generated migrations** - Alembic isn't perfect
4. **Make migrations backward-compatible** when possible:
   - Add columns as nullable first
   - Populate data in separate migration
   - Remove old columns later

5. **Never edit committed migrations** - create new ones to fix issues
6. **Keep migrations small and focused** - one change per migration
7. **Write clear migration messages** that explain what changed

---

## Deployment Process

### Manual Production Deployment

1. **Ensure changes are tested in dev:**
   ```bash
   # Changes should be automatically deployed to dev
   # Test at: https://dev.music-graph.billgrant.io
   ```

2. **Trigger production deployment:**
   - Go to: https://github.com/billgrant/music-graph/actions
   - Select "Deploy to Production" workflow
   - Click "Run workflow"
   - **Optional:** Specify version (e.g., `v0.5.0-beta` or `v1.0.0`)
   - **Default:** Auto-increments (v0.3.0-alpha → v0.4.0-alpha)

3. **Monitor deployment:**
   - Watch GitHub Actions logs
   - Pre-deployment backup will be created
   - Image will be built and pushed to GCR
   - When you see the migration reminder, proceed to step 4

4. **Run migrations manually:**
   ```bash
   ssh user@prod-vm
   cd ~/music-graph
   docker-compose -f docker-compose.prod.yml exec web flask db upgrade
   ```

5. **Verify deployment:**
   ```bash
   # Check containers are running
   docker-compose -f docker-compose.prod.yml ps

   # Check application logs
   docker-compose -f docker-compose.prod.yml logs --tail=50 web

   # Test the site
   curl -I https://music-graph.billgrant.io

   # Check version deployed
   docker-compose -f docker-compose.prod.yml exec web python -c "print('Deployment successful!')"
   ```

6. **If issues arise, rollback immediately** (see Rollback section)

---

## Rollback Procedures

### Quick Rollback (Application Only)

If the new code has issues but database migrations haven't been applied yet:

```bash
# SSH to production VM
ssh user@prod-vm
cd ~/music-graph

# Find the previous version
git log --oneline | head -10

# Checkout previous version
git checkout <previous-commit-hash>

# Pull previous Docker image
# Find version from: https://github.com/billgrant/music-graph/releases
docker pull gcr.io/music-graph-479719/music-graph:v0.3.0-alpha

# Tag as latest
docker tag gcr.io/music-graph-479719/music-graph:v0.3.0-alpha \
           gcr.io/music-graph-479719/music-graph:latest

# Restart containers
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Verify rollback
docker-compose -f docker-compose.prod.yml ps
curl -I https://music-graph.billgrant.io
```

---

### Full Rollback (Application + Database)

If migrations were applied and need to be rolled back:

```bash
# SSH to production VM
ssh user@prod-vm
cd ~/music-graph

# 1. STOP THE APPLICATION FIRST
docker-compose -f docker-compose.prod.yml stop web

# 2. Restore database from pre-deployment backup
BACKUP_FILE=$(ls -t ~/backups/musicgraph-*.sql | head -1)
echo "Restoring from: $BACKUP_FILE"

# Confirm this is the right backup
ls -lh "$BACKUP_FILE"

# Restore database
docker-compose -f docker-compose.prod.yml exec -T db psql -U musicgraph musicgraph < "$BACKUP_FILE"

# 3. Rollback code and image (same as Quick Rollback)
git checkout <previous-commit-hash>
docker pull gcr.io/music-graph-479719/music-graph:v0.3.0-alpha
docker tag gcr.io/music-graph-479719/music-graph:v0.3.0-alpha \
           gcr.io/music-graph-479719/music-graph:latest

# 4. Restart application
docker-compose -f docker-compose.prod.yml up -d

# 5. Verify rollback
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs web
curl -I https://music-graph.billgrant.io
```

---

### Rollback Migration Only

If you need to rollback a specific migration without restoring the entire database:

```bash
# Check current migration
docker-compose -f docker-compose.prod.yml exec web flask db current

# Rollback one migration
docker-compose -f docker-compose.prod.yml exec web flask db downgrade

# Or rollback to specific revision
docker-compose -f docker-compose.prod.yml exec web flask db downgrade <revision-id>

# Verify
docker-compose -f docker-compose.prod.yml exec web flask db current

# Restart application
docker-compose -f docker-compose.prod.yml restart web
```

**Warning:** Not all migrations can be safely rolled back. Always test downgrade() in dev first.

---

## Backup and Restore

### Automated Backups

Pre-deployment backups are created automatically by the deployment workflow:
- Location: `~/backups/` on production VM
- Format: `musicgraph-YYYYMMDD-HHMMSS.sql`
- Created before every deployment

### Manual Backup

```bash
# SSH to production VM
ssh user@prod-vm
cd ~/music-graph

# Create backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE=~/backups/musicgraph-manual-${TIMESTAMP}.sql
mkdir -p ~/backups

docker-compose -f docker-compose.prod.yml exec -T db \
  pg_dump -U musicgraph musicgraph > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"

# Optional: Upload to Google Cloud Storage
gsutil cp "$BACKUP_FILE" gs://music-graph-backups/
```

### Restore from Backup

```bash
# SSH to production VM
ssh user@prod-vm
cd ~/music-graph

# List available backups
ls -lh ~/backups/

# Choose backup to restore
BACKUP_FILE=~/backups/musicgraph-20251209-143022.sql

# STOP APPLICATION FIRST
docker-compose -f docker-compose.prod.yml stop web

# Restore database
docker-compose -f docker-compose.prod.yml exec -T db \
  psql -U musicgraph musicgraph < "$BACKUP_FILE"

# Restart application
docker-compose -f docker-compose.prod.yml start web

# Verify
docker-compose -f docker-compose.prod.yml logs web
```

---

## Emergency Procedures

### Application Won't Start

```bash
# Check container status
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs web
docker-compose -f docker-compose.prod.yml logs db

# Check database connectivity
docker-compose -f docker-compose.prod.yml exec web \
  python -c "from models import db; from app import app; app.app_context().push(); db.engine.connect(); print('DB OK')"

# Restart containers
docker-compose -f docker-compose.prod.yml restart

# If still failing, rollback
# See "Full Rollback" section above
```

### Database Connection Issues

```bash
# Check database container
docker-compose -f docker-compose.prod.yml ps db

# Check database logs
docker-compose -f docker-compose.prod.yml logs db

# Test database connectivity
docker-compose -f docker-compose.prod.yml exec db \
  psql -U musicgraph -d musicgraph -c "SELECT 1;"

# Restart database
docker-compose -f docker-compose.prod.yml restart db
```

### Site is Down

```bash
# Check all containers
docker-compose -f docker-compose.prod.yml ps

# Check nginx
sudo systemctl status nginx
sudo nginx -t

# Check application
curl -I http://localhost:5000/

# Check site
curl -I https://music-graph.billgrant.io

# Recent logs
docker-compose -f docker-compose.prod.yml logs --tail=100 web

# If all else fails, full rollback
# See "Full Rollback" section above
```

### Disk Space Full

```bash
# Check disk space
df -h

# Clean up old Docker images
docker system prune -a

# Clean up old backups (keep last 10)
cd ~/backups
ls -t musicgraph-*.sql | tail -n +11 | xargs rm -f

# Check Docker logs size
du -sh /var/lib/docker/containers/*

# Limit Docker logs (edit /etc/docker/daemon.json)
```

---

## Contact Information

**Primary Contact:** Bill Grant
**GitHub Repository:** https://github.com/billgrant/music-graph
**Production URL:** https://music-graph.billgrant.io
**Dev URL:** https://dev.music-graph.billgrant.io

**Emergency Contacts:**
- GitHub Issues: https://github.com/billgrant/music-graph/issues
- Related: Issue #9 (Automated Migrations)

---

## Automation Roadmap

**Current State:** Manual migrations during deployment
**Future State:** Automated migrations (see Issue #9)

When ready to automate:
- Migrations run automatically in entrypoint.sh
- No manual SSH step required
- Rollback still uses same procedures
- See Issue #9 for implementation plan

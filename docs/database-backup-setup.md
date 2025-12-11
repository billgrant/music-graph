# Database Backup Setup Guide

This guide documents the one-time setup required for automated database backups on each VM.

## Overview

**What gets backed up:** PostgreSQL database from Docker container
**Where:** Google Cloud Storage bucket `gs://music-graph-backups-music-graph-479719/`
**When:** Daily at 3:00 AM (via cron)
**Retention:** 7 days (automatic deletion via GCS lifecycle policy)

## Prerequisites

- ✅ GCS bucket created (via Terraform in `terraform/project/`)
- ✅ Backup script deployed (`backup-database.sh`)
- ✅ VM has service account with GCS write permissions

## One-Time Setup (Per VM)

Perform these steps on **each VM** (dev and prod):

### Step 1: Create Log File

The backup script writes to `/var/log/music-graph-backup.log`. Create it with proper permissions:

```bash
sudo touch /var/log/music-graph-backup.log
sudo chown billgrant:billgrant /var/log/music-graph-backup.log
```

**Alternative:** Use home directory logs (script will auto-adjust)

### Step 2: Verify Docker Group Membership

The script needs to run `docker-compose` commands without sudo.

```bash
# Check if user is in docker group
groups billgrant

# Should output: billgrant ... docker ...
```

If `docker` is **not** in the list:

```bash
sudo usermod -aG docker billgrant
# Then logout and login for it to take effect
```

### Step 3: Setup Cron Job

Add automated backup to user's crontab:

```bash
crontab -e
```

Add this line (**replace `ENV` with `dev` or `prod`**):

```cron
# Daily database backup at 3:00 AM
0 3 * * * /home/billgrant/music-graph/backup-database.sh ENV >> /var/log/music-graph-backup-cron.log 2>&1
```

**Dev VM example:**
```cron
0 3 * * * /home/billgrant/music-graph/backup-database.sh dev >> /var/log/music-graph-backup-cron.log 2>&1
```

**Prod VM example:**
```cron
0 3 * * * /home/billgrant/music-graph/backup-database.sh prod >> /var/log/music-graph-backup-cron.log 2>&1
```

Save and exit the editor.

### Step 4: Verify Configuration

Run the verification script to check everything is configured correctly:

```bash
cd ~/music-graph
./verify-backup-setup.sh dev  # or 'prod'
```

Expected output:
```
=== Database Backup Configuration Verification ===

Checking backup script... ✓ PASS
Checking log file permissions... ✓ PASS
Checking docker group membership... ✓ PASS
Checking docker daemon... ✓ PASS
Checking docker-compose file... ✓ PASS
Checking database container... ✓ PASS
Checking GCS bucket access... ✓ PASS
Checking cron job... ✓ PASS
Checking gsutil availability... ✓ PASS

=== Summary ===
Passed: 9

All checks passed! Backup system is properly configured.
```

### Step 5: Test Manual Backup

Run a manual backup to verify everything works:

```bash
cd ~/music-graph
./backup-database.sh dev  # or 'prod'
```

Expected output:
```
[Date] Starting database backup for dev environment
[Date] Running pg_dump...
[Date] Backup created: 5.2M
[Date] Compressing backup...
[Date] Compressed to: 524K
[Date] Uploading to GCS...
[Date] ✓ Backup uploaded successfully
[Date] Local backup cleaned up
[Date] Recent backups in GCS:
[Date] Backup complete!
```

Verify the backup in GCS:

```bash
gsutil ls gs://music-graph-backups-music-graph-479719/dev/
# or
gsutil ls gs://music-graph-backups-music-graph-479719/prod/
```

---

## Monitoring & Maintenance

### Check Backup Logs

**Main backup log:**
```bash
tail -f /var/log/music-graph-backup.log
```

**Cron output log:**
```bash
tail -f /var/log/music-graph-backup-cron.log
```

### List Available Backups

```bash
# Dev backups
gsutil ls -lh gs://music-graph-backups-music-graph-479719/dev/

# Prod backups
gsutil ls -lh gs://music-graph-backups-music-graph-479719/prod/
```

### Verify Cron Job is Running

```bash
# List current user's cron jobs
crontab -l

# Check recent cron execution in system logs
sudo grep CRON /var/log/syslog | grep backup-database
```

---

## Restore Procedure

If you need to restore from a backup:

### 1. Download Backup from GCS

```bash
# List available backups
gsutil ls gs://music-graph-backups-music-graph-479719/prod/

# Download desired backup
gsutil cp gs://music-graph-backups-music-graph-479719/prod/backup-20251211-030000.sql.gz ~/
```

### 2. Decompress

```bash
gunzip backup-20251211-030000.sql.gz
```

### 3. Restore to Database

**IMPORTANT:** This will **overwrite** the current database!

```bash
cd ~/music-graph

# Stop the application
docker-compose -f docker-compose.prod.yml stop web

# Restore database
docker-compose -f docker-compose.prod.yml exec -T db \
  psql -U musicgraph musicgraph < ~/backup-20251211-030000.sql

# Restart application
docker-compose -f docker-compose.prod.yml start web
```

### 4. Verify Restore

Check that data was restored correctly:

```bash
docker-compose -f docker-compose.prod.yml exec db \
  psql -U musicgraph musicgraph -c "SELECT COUNT(*) FROM genres;"
```

---

## Troubleshooting

### Backup Script Fails

**Check docker permissions:**
```bash
docker ps  # Should work without sudo
```

**Check GCS access:**
```bash
gsutil ls gs://music-graph-backups-music-graph-479719/
```

**Check database container:**
```bash
docker-compose -f docker-compose.dev.yml ps db
```

### Cron Job Not Running

**Check cron service:**
```bash
sudo systemctl status cron
```

**Check crontab:**
```bash
crontab -l | grep backup
```

**Check cron logs:**
```bash
sudo grep CRON /var/log/syslog | tail -20
```

### Backups Not Appearing in GCS

**Check bucket permissions:**
```bash
# Test write permission
echo "test" | gsutil cp - gs://music-graph-backups-music-graph-479719/test.txt
gsutil rm gs://music-graph-backups-music-graph-479719/test.txt
```

**Check service account:**
```bash
gcloud auth list
```

---

## New VM Checklist

When provisioning a new VM, complete these steps:

- [ ] Pull latest code: `git clone` or `git pull`
- [ ] Run verification: `./verify-backup-setup.sh [dev|prod]`
- [ ] Fix any failed checks
- [ ] Create log file (Step 1)
- [ ] Verify docker group (Step 2)
- [ ] Setup cron job (Step 3)
- [ ] Test manual backup (Step 5)
- [ ] Verify backup appears in GCS
- [ ] Wait 24 hours and verify automated backup ran

---

## Related Documentation

- Terraform GCS bucket: `terraform/project/main.tf`
- Backup script: `backup-database.sh`
- Verification script: `verify-backup-setup.sh`
- GCS lifecycle policy: 7-day retention (configured in Terraform)

---

## Future Improvements (Phase 8+)

When implementing immutable infrastructure (Issue #10):

- [ ] Bake backup configuration into Packer image
- [ ] Automate cron setup in startup script
- [ ] Add monitoring/alerting for backup failures
- [ ] Implement point-in-time recovery
- [ ] Consider Cloud SQL managed database

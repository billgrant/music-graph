# Cloud SQL Backup & Restore Guide

This guide documents the backup and restore procedures for the Cloud SQL PostgreSQL database.

## Overview

**Database:** Cloud SQL PostgreSQL 16
**Backup Type:** Automated daily backups (managed by Cloud SQL)
**Retention:** 7 days
**Point-in-Time Recovery:** Enabled for production

## Backup Configuration

Cloud SQL backups are configured via Terraform in `terraform/environments/main.tf`:

```hcl
backup_configuration {
  enabled                        = var.environment == "prod" ? true : false
  point_in_time_recovery_enabled = var.environment == "prod" ? true : false
  start_time                     = "03:00"  # 3 AM UTC
  backup_retention_settings {
    retained_backups = 7
  }
}
```

**Production:**
- Daily automated backups at 3 AM UTC
- Point-in-time recovery enabled (can restore to any point in the last 7 days)
- 7-day retention

**Development:**
- No automated backups (cost savings)
- Can be manually backed up if needed

## Viewing Backups

### Via Google Cloud Console

1. Go to [Cloud SQL Instances](https://console.cloud.google.com/sql/instances)
2. Click on `music-graph-prod`
3. Go to **Backups** tab
4. View available backups and their timestamps

### Via gcloud CLI

```bash
# List backups for production
gcloud sql backups list --instance=music-graph-prod

# List backups for dev (if any)
gcloud sql backups list --instance=music-graph-dev
```

## Restore Procedures

### Option 1: Restore to Same Instance (In-Place)

**WARNING:** This overwrites the current database!

```bash
# List available backups
gcloud sql backups list --instance=music-graph-prod

# Restore from a specific backup
gcloud sql backups restore BACKUP_ID \
  --restore-instance=music-graph-prod
```

The instance will be unavailable during the restore (typically a few minutes).

### Option 2: Point-in-Time Recovery (Production Only)

Restore to a specific point in time within the last 7 days:

```bash
# Create a new instance from point-in-time recovery
gcloud sql instances clone music-graph-prod music-graph-prod-restored \
  --point-in-time="2025-12-17T10:00:00Z"
```

This creates a NEW instance with the restored data. You can then:
1. Verify the data on the new instance
2. Update the DATABASE_URL secret to point to the new instance
3. Delete the old instance (or keep as archive)

### Option 3: Restore to New Instance

Create a new instance from a backup (useful for testing or disaster recovery):

```bash
# Get backup ID
gcloud sql backups list --instance=music-graph-prod

# Restore to a new instance
gcloud sql instances restore-backup music-graph-prod-new \
  --backup-instance=music-graph-prod \
  --backup-id=BACKUP_ID
```

## Manual Backup (On-Demand)

If you need to create an immediate backup before a risky operation:

```bash
# Create on-demand backup
gcloud sql backups create --instance=music-graph-prod

# Verify it was created
gcloud sql backups list --instance=music-graph-prod
```

## Export Database (For Migration or Archive)

Export the database to Cloud Storage for long-term archival or migration:

```bash
# Export to GCS bucket
gcloud sql export sql music-graph-prod \
  gs://music-graph-backups-music-graph-479719/exports/manual-export-$(date +%Y%m%d).sql \
  --database=musicgraph
```

## Import Database

Import from a SQL file (useful for migration or seeding):

```bash
# Import from GCS
gcloud sql import sql music-graph-prod \
  gs://music-graph-backups-music-graph-479719/exports/backup.sql \
  --database=musicgraph
```

## Disaster Recovery Runbook

### Scenario: Production Database Corrupted

1. **Assess the damage:** Determine when the corruption occurred
2. **Choose restore method:**
   - If you know the exact time: Use point-in-time recovery
   - If you want a specific backup: Use backup restore
3. **Notify users:** Site may be unavailable during restore
4. **Perform restore:** Follow procedures above
5. **Verify:** Check data integrity after restore
6. **Update secrets if needed:** If restored to new instance, update Secret Manager

### Scenario: Accidental Data Deletion

1. **Stop the bleeding:** If app is still running and could cause more damage, stop it:
   ```bash
   docker-compose -f docker-compose.prod.yml down
   ```
2. **Identify when data was deleted**
3. **Use point-in-time recovery** to restore to just before the deletion
4. **Verify restored data**
5. **Restart application**

## Monitoring

### Check Backup Status

```bash
# Recent backup operations
gcloud sql operations list --instance=music-graph-prod --filter="operationType:BACKUP"
```

### Set Up Alerts (Optional)

Consider setting up Cloud Monitoring alerts for:
- Backup failures
- Storage usage approaching limits
- Instance availability

## Cost Considerations

- **Backup storage:** Charged per GB/month (~$0.08/GB)
- **Point-in-time recovery:** Requires additional storage for transaction logs
- **Estimated cost:** ~$1-2/month for this workload

## Previous Backup System (Archived)

The previous backup system used:
- `backup-database.sh` - Cron script that ran pg_dump in Docker container
- `verify-backup-setup.sh` - Verification script for backup configuration
- GCS bucket for storing compressed SQL dumps

These scripts were removed in Phase 11 as Cloud SQL handles backups automatically with better reliability and point-in-time recovery capabilities.

---

## Related Documentation

- Terraform configuration: `terraform/environments/main.tf`
- [Cloud SQL Backup Documentation](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups)
- [Point-in-Time Recovery](https://cloud.google.com/sql/docs/postgres/backup-recovery/pitr)

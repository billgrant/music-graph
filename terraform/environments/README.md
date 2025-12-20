# Terraform - Environment Infrastructure

Environment-specific infrastructure for dev and prod, managed via GitOps CI/CD.

## Structure

```
terraform/
├── bootstrap/       # State buckets, CI service accounts (manual apply only)
├── project/         # Project-level: APIs, GCR, backup bucket, certbot IAM
├── environments/
│   ├── dev/         # Dev Cloud Run, Cloud SQL, DNS
│   └── prod/        # Prod Cloud Run, Cloud SQL, DNS
└── modules/
    └── music-graph/ # Shared module for Cloud Run + Cloud SQL
```

## CI/CD Workflows

- **On PR**: `terraform-plan.yml` runs plan for project, dev, and prod; posts results as PR comments
- **On merge to main**: `terraform-apply.yml` auto-applies project and dev
- **Production**: Manual dispatch only via GitHub Actions

## Local Development

### Connecting to Cloud SQL

To add your IP for direct database access:

```bash
# Get your public IP
curl ifconfig.me

# Set the environment variable and apply
export TF_VAR_admin_ips='["YOUR_IP/32"]'
cd terraform/environments/dev  # or prod
terraform apply
```

This adds your IP to the Cloud SQL authorized networks. The variable defaults to empty, so CI/CD won't add any admin IPs.

### Running Terraform Locally

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## Bootstrap (Manual Only)

The `terraform/bootstrap` directory creates foundational resources and is NOT managed by CI:
- GCS state buckets
- terraform-ci service account + keys
- AWS IAM user for Route53

If bootstrap needs changes, apply locally:
```bash
cd terraform/bootstrap
terraform apply
```

## State Lock Issues

If a CI run is cancelled mid-apply, you may need to force-unlock:
```bash
cd terraform/project  # or environments/dev, etc.
terraform force-unlock LOCK_ID
```

The lock ID is shown in the error message.

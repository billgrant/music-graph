# Bootstrap Recovery Procedures

This document describes how to recover if the bootstrap state is lost.

## Why Local State?

The bootstrap configuration creates the GCS buckets that store Terraform state. This creates a chicken-and-egg problem - you can't store state in a bucket that doesn't exist yet.

We use local state for bootstrap because:
1. It solves the chicken-and-egg problem
2. Bootstrap is rarely modified (only when adding new environments)
3. The state file contains sensitive data (SA keys) and shouldn't be in git

## Recovery Procedures

### If bootstrap state is lost but resources exist:

1. Recreate tfvars:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with actual project_id
   ```

2. Import existing resources:
   ```bash
   terraform init

   # Import GCS buckets
   terraform import google_storage_bucket.tf_state_project music-graph-479719-tf-project
   terraform import google_storage_bucket.tf_state_dev music-graph-479719-tf-dev
   terraform import google_storage_bucket.tf_state_prod music-graph-479719-tf-prod

   # Import service account
   terraform import google_service_account.terraform_ci projects/music-graph-479719/serviceAccounts/terraform-ci@music-graph-479719.iam.gserviceaccount.com

   # Import AWS resources
   terraform import aws_iam_user.terraform_ci ci/terraform-ci-music-graph
   # Note: Access keys cannot be imported - must be recreated
   ```

3. Run plan to verify:
   ```bash
   terraform plan
   ```

### If starting fresh (disaster recovery):

1. Ensure you have GCP and AWS credentials configured locally
2. Create terraform.tfvars
3. Run terraform apply
4. Save the outputs to GitHub Secrets:
   - `TERRAFORM_SA_KEY`: terraform output -raw terraform_ci_key
   - `AWS_ACCESS_KEY_ID`: terraform output -raw aws_access_key_id
   - `AWS_SECRET_ACCESS_KEY`: terraform output -raw aws_secret_access_key

### Rotating credentials:

To rotate the service account key:
```bash
terraform taint google_service_account_key.terraform_ci
terraform apply
# Update TERRAFORM_SA_KEY in GitHub Secrets
```

To rotate AWS credentials:
```bash
terraform taint aws_iam_access_key.terraform_ci
terraform apply
# Update AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in GitHub Secrets
```

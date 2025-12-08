# Terraform Workspace Guide

## Why Workspaces?

Terraform workspaces allow you to maintain **separate state files** for prod and dev environments using the same configuration files. This prevents accidentally destroying prod when deploying dev.

## How It Works

- **default workspace** - Your current prod infrastructure lives here
- **prod workspace** - Move prod here for clarity
- **dev workspace** - New dev infrastructure

Each workspace has its own `terraform.tfstate` file stored in `terraform.tfstate.d/`

## Initial Setup (One Time)

```bash
cd terraform/

# Your prod infrastructure is currently in "default" workspace
# Create prod workspace and switch to it
terraform workspace new prod

# This moves your state to the prod workspace
# Your existing prod VM is now managed in the "prod" workspace

# Create dev workspace
terraform workspace new dev
```

## Daily Usage

### Before ANY Terraform Command

```bash
# ALWAYS check which workspace you're in
terraform workspace show
```

### Working with Dev

```bash
# Switch to dev workspace
terraform workspace select dev

# Verify
terraform workspace show  # Should output: dev

# Now safe to run dev commands
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Working with Prod

```bash
# Switch to prod workspace
terraform workspace select prod

# Verify
terraform workspace show  # Should output: prod

# Now safe to run prod commands
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## Safety Checklist

Before running `terraform apply`:

1. ✅ Check workspace: `terraform workspace show`
2. ✅ Run plan first: `terraform plan -var-file=XXX.tfvars`
3. ✅ Review the plan output carefully
4. ✅ Verify it's creating/updating the RIGHT resources
5. ✅ Look for "Plan: X to add, Y to change, Z to destroy"
6. ✅ Make sure it's not destroying prod when you want dev!

## Common Commands

```bash
# List all workspaces (* shows current)
terraform workspace list

# Show current workspace
terraform workspace show

# Switch workspace
terraform workspace select dev
terraform workspace select prod

# Create new workspace
terraform workspace new staging
```

## File Structure

```
terraform/
├── main.tf                      # Shared configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── prod.tfvars                  # Prod values (gitignored)
├── dev.tfvars                   # Dev values (gitignored)
├── terraform.tfstate.d/         # Workspace states (gitignored)
│   ├── prod/
│   │   └── terraform.tfstate
│   └── dev/
│       └── terraform.tfstate
```

## Migration Steps (Moving Existing Prod)

If your prod is currently in the "default" workspace:

**Method 1: Using terraform state push (Recommended)**

```bash
cd terraform/

# Make sure you're in default workspace with existing state
terraform workspace show  # Shows: default

# Create prod workspace
terraform workspace new prod

# Push the state from default to prod
terraform state push terraform.tfstate

# Verify the state is in prod
terraform workspace select prod
terraform plan -var-file=prod.tfvars  # Should show no changes

# Now you can use default or create dev
terraform workspace new dev
```

**Method 2: Copy state file manually**

```bash
cd terraform/

terraform workspace select default
# Copy the state file
cp terraform.tfstate terraform.tfstate.d/prod/terraform.tfstate
terraform workspace select prod
```

Or just leave prod in "default" and only use workspaces for dev/staging.

## Troubleshooting

### "Error: Workspace X already exists"
```bash
# List workspaces
terraform workspace list

# Switch to it instead
terraform workspace select X
```

### "Wrong workspace - plan shows destroying prod!"
```bash
# STOP! Don't apply!
# Switch to correct workspace
terraform workspace select dev
terraform plan -var-file=dev.tfvars
```

### "Can't delete workspace - not empty"
```bash
# First destroy all resources in that workspace
terraform workspace select dev
terraform destroy -var-file=dev.tfvars

# Then you can delete it
terraform workspace select default
terraform workspace delete dev
```

## Best Practices

1. **Always** check workspace before running terraform commands
2. **Never** use `-auto-approve` with apply/destroy
3. **Always** run `plan` first and review output
4. **Use** descriptive workspace names (prod, dev, staging)
5. **Document** which workspace contains what infrastructure
6. **Backup** your terraform state files regularly

## Quick Reference Card

```bash
# Check where you are
terraform workspace show

# Switch to dev
terraform workspace select dev && terraform workspace show

# Switch to prod
terraform workspace select prod && terraform workspace show

# Deploy to current workspace
terraform plan -var-file=$(terraform workspace show).tfvars
terraform apply -var-file=$(terraform workspace show).tfvars
```

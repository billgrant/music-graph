# Terraform - Environment Infrastructure

This Terraform configuration manages **environment-specific GCP resources** using workspaces for dev and prod.

## What This Manages

- Compute Engine VMs (dev-music-graph, prod-music-graph)
- Static external IP addresses
- Firewall rules
- VM startup scripts
- Service account attachments

## Workspaces

This configuration uses Terraform workspaces to manage separate environments:

- `dev` - Development environment VM
- `prod` - Production environment VM

### View Current Workspace
```bash
terraform workspace show
```

### List All Workspaces
```bash
terraform workspace list
```

### Switch Workspace
```bash
terraform workspace select dev
# or
terraform workspace select prod
```

## Usage

### Initialize Terraform
```bash
cd terraform/environments
terraform init
```

### Select Environment
```bash
terraform workspace select dev  # or prod
```

### Review Changes
```bash
terraform plan -var-file="dev.tfvars"  # or prod.tfvars
```

### Apply Changes
```bash
terraform apply -var-file="dev.tfvars"  # or prod.tfvars
```

## Important Notes

⚠️ **Always verify workspace before running terraform commands!**

- `terraform workspace show` - Check current workspace
- Wrong workspace = changes to wrong environment
- Use `-var-file` flag to specify correct variables

## Related

- See `terraform/project/` for project-level resources (GCR lifecycle policy)
- Part of Phase 5 (Production Deployment) and Phase 7 (CI/CD)

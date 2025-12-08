# Dev Environment Setup Guide

This guide walks through setting up the dev environment on a separate GCP VM.

## Architecture

- **Separate VM**: e2-micro (~$10/month with static IP)
- **Database**: Separate PostgreSQL container (musicgraph_dev)
- **Domain**: dev.music-graph.billgrant.io
- **SSL**: Let's Encrypt certificate via certbot
- **Access**: Same IP restrictions as prod

## Prerequisites

- Terraform installed locally
- gcloud CLI configured
- Access to your GCP project
- DNS access to add subdomain

## Step 1: Create Terraform Variable Files

```bash
cd terraform/

# Create prod.tfvars from template
cp prod.tfvars.example prod.tfvars
# Edit prod.tfvars with your actual values

# Create dev.tfvars from template
cp dev.tfvars.example dev.tfvars
# Edit dev.tfvars - use environment="dev"
```

## Step 2: Set Up Terraform Workspaces

**IMPORTANT:** We use Terraform workspaces to maintain separate state for prod and dev.

```bash
cd terraform/

# Initialize Terraform (if not already done)
terraform init

# Create prod workspace and import existing infrastructure
terraform workspace new prod
# If your prod VM already exists, you're now in the prod workspace

# Create and switch to dev workspace
terraform workspace new dev
terraform workspace select dev

# Verify you're in the dev workspace
terraform workspace show  # Should output: dev
```

## Step 3: Deploy Dev VM with Terraform

```bash
# Make sure you're in dev workspace!
terraform workspace show  # Must be "dev"

# Plan the dev deployment
terraform plan -var-file=dev.tfvars

# Review the plan - should show creating NEW resources, not replacing
# Apply to create dev VM
terraform apply -var-file=dev.tfvars

# Note the output - you'll need the IP address
```

This creates:
- `dev-music-graph` VM (e2-micro)
- `dev-music-graph-ip` static IP
- Firewall rules for HTTP, HTTPS, SSH (IP-restricted)

## Step 3: Set Up DNS

Add an A record for the dev subdomain:

```
Type: A
Name: dev
Value: [IP address from terraform output]
TTL: 3600
```

Wait for DNS propagation (5-15 minutes):
```bash
dig dev.music-graph.billgrant.io
```

## Step 4: SSH to Dev VM

```bash
# Use the output from terraform
gcloud compute ssh dev-music-graph --zone=us-east1-b

# Or manually
ssh your-username@[dev-ip-address]
```

## Step 5: Clone Repository and Configure

```bash
# On the dev VM
cd ~
git clone https://github.com/billgrant/music-graph.git
cd music-graph

# Create .env.dev from template
cp .env.dev.example .env.dev
nano .env.dev  # Fill in actual values
```

Example `.env.dev`:
```bash
POSTGRES_PASSWORD=secure-dev-password-123
DATABASE_URL=postgresql://musicgraph:secure-dev-password-123@db:5432/musicgraph_dev
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=dev-secret-key-change-me
ENVIRONMENT=dev
```

## Step 6: Install and Configure Nginx

```bash
# Install Nginx
sudo apt-get update
sudo apt-get install -y nginx

# Create Nginx config for dev
sudo nano /etc/nginx/sites-available/music-graph-dev
```

Nginx config content:
```nginx
server {
    listen 80;
    server_name dev.music-graph.billgrant.io;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/music-graph-dev /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Remove default site
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## Step 7: Install Certbot and Get SSL Certificate

```bash
# Install certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d dev.music-graph.billgrant.io

# Follow prompts:
# - Enter email
# - Agree to terms
# - Choose to redirect HTTP to HTTPS
```

Certbot will automatically update your Nginx config for HTTPS.

## Step 8: Start the Application

```bash
cd ~/music-graph

# Build and start containers
docker-compose -f docker-compose.dev.yml up -d --build

# Check logs
docker-compose -f docker-compose.dev.yml logs -f

# Verify containers are running
docker-compose -f docker-compose.dev.yml ps
```

## Step 9: Verify Everything Works

1. Visit https://dev.music-graph.billgrant.io
2. You should see the Music Graph application
3. Try logging in
4. Check that database is working

## Management Commands

### View logs
```bash
docker-compose -f docker-compose.dev.yml logs -f web
docker-compose -f docker-compose.dev.yml logs -f db
```

### Restart application
```bash
docker-compose -f docker-compose.dev.yml restart web
```

### Stop everything
```bash
docker-compose -f docker-compose.dev.yml down
```

### Rebuild after code changes
```bash
cd ~/music-graph
git pull origin main
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d --build
```

### Database operations
```bash
# Initialize database
docker-compose -f docker-compose.dev.yml exec web python init_db.py

# Make user admin
docker-compose -f docker-compose.dev.yml exec web python make_admin.py username

# Access PostgreSQL
docker-compose -f docker-compose.dev.yml exec db psql -U musicgraph -d musicgraph_dev
```

## Troubleshooting

### Application not starting
```bash
# Check logs
docker-compose -f docker-compose.dev.yml logs web

# Check if database is healthy
docker-compose -f docker-compose.dev.yml ps
```

### Nginx errors
```bash
# Check Nginx config
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### SSL certificate issues
```bash
# Test certificate renewal
sudo certbot renew --dry-run

# Check certificate status
sudo certbot certificates
```

### Can't access from browser
- Verify DNS is propagated: `dig dev.music-graph.billgrant.io`
- Check firewall rules in GCP console
- Verify your IP is in the allowed_ips list

## Maintenance

### Auto-renewal for SSL
Certbot automatically creates a renewal cron job. Test it:
```bash
sudo certbot renew --dry-run
```

### Backups
```bash
# Backup dev database
docker-compose -f docker-compose.dev.yml exec db pg_dump -U musicgraph musicgraph_dev > backup-dev-$(date +%Y%m%d).sql

# Restore from backup
docker-compose -f docker-compose.dev.yml exec -T db psql -U musicgraph -d musicgraph_dev < backup-dev-20251208.sql
```

## Managing Terraform Workspaces

### Workspace Commands

```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Switch to a workspace
terraform workspace select prod
terraform workspace select dev

# Delete a workspace (must be empty first)
terraform workspace delete dev
```

### Important Workspace Rules

⚠️ **ALWAYS verify your workspace before running terraform commands:**

```bash
# Before ANY terraform command, check:
terraform workspace show

# For prod changes:
terraform workspace select prod
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

# For dev changes:
terraform workspace select dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Managing Prod Infrastructure

If you need to make changes to prod:

```bash
cd terraform/

# Switch to prod workspace
terraform workspace select prod
terraform workspace show  # Verify: prod

# Plan changes
terraform plan -var-file=prod.tfvars

# Apply changes
terraform apply -var-file=prod.tfvars
```

## Tearing Down Dev Environment

If you need to destroy the dev environment:

```bash
# On dev VM: Stop containers and remove data
docker-compose -f docker-compose.dev.yml down -v

# Locally: Destroy dev infrastructure with Terraform
cd terraform/

# MAKE SURE YOU'RE IN DEV WORKSPACE!
terraform workspace select dev
terraform workspace show  # Must show "dev"

# Destroy
terraform destroy -var-file=dev.tfvars
```

## Next Steps

After dev environment is working:
1. Set up automated deployment to dev (GitHub Actions)
2. Test changes in dev before promoting to prod
3. Consider database backup strategy
4. Set up monitoring/alerting

## Cost Estimate

- e2-micro VM: ~$7/month
- Static IP: ~$3/month
- Storage: ~$1-2/month
- **Total: ~$10-12/month**

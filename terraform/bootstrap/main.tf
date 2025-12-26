# =============================================================================
# Bootstrap - State Buckets and CI/CD Service Accounts
# =============================================================================
#
# This configuration creates the foundational resources needed for GitOps:
# - GCS buckets for Terraform state storage
# - Service account for CI/CD pipelines
# - AWS IAM user for Route53 DNS management
#
# Run this once manually, then state is stored locally (not in git - public repo)
# See RECOVERY.md for disaster recovery procedures.

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend - state stored on disk, not in git (public repo)
  # For recovery, see RECOVERY.md
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "aws" {
  region = "us-east-1"
}

locals {
  environments = ["dev", "prod", "project"]

  terraform_ci_roles = [
    "roles/artifactregistry.admin",
    "roles/cloudsql.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/run.admin",
    "roles/secretmanager.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
  ]
}

# =============================================================================
# GCS State Buckets
# =============================================================================

resource "google_storage_bucket" "terraform_state" {
  for_each = toset(local.environments)

  name          = "${var.project_id}-tf-${each.key}"
  location      = "US-EAST1"
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  labels = {
    purpose     = "terraform-state"
    environment = each.key
    managed-by  = "terraform-bootstrap"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 30
      with_state         = "ANY"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = 90
      with_state                 = "ANY"
    }
  }
}

# =============================================================================
# GCP Service Account for Terraform CI/CD
# =============================================================================

resource "google_service_account" "terraform_ci" {
  account_id   = "terraform-ci"
  display_name = "Terraform CI/CD"
  description  = "Service account for GitHub Actions to run Terraform plan/apply"
}

# State bucket access
resource "google_storage_bucket_iam_member" "terraform_ci_state_access" {
  for_each = toset(local.environments)

  bucket = google_storage_bucket.terraform_state[each.key].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# Project-level IAM for Terraform to manage resources
resource "google_project_iam_member" "terraform_ci" {
  for_each = toset(local.terraform_ci_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# Service account key for GitHub Actions
resource "google_service_account_key" "terraform_ci" {
  service_account_id = google_service_account.terraform_ci.name
}

# =============================================================================
# AWS IAM User for Route53 (Least Privilege)
# =============================================================================

data "aws_route53_zone" "billgrant" {
  name = var.route53_zone_name
}

resource "aws_iam_user" "terraform_ci" {
  name = "terraform-ci-music-graph"
  path = "/ci/"

  tags = {
    purpose    = "terraform-ci"
    managed-by = "terraform-bootstrap"
  }
}

resource "aws_iam_access_key" "terraform_ci" {
  user = aws_iam_user.terraform_ci.name
}

resource "aws_iam_policy" "terraform_ci_route53" {
  name        = "terraform-ci-route53-music-graph"
  description = "Allows Terraform CI to manage Route53 records for music-graph"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListZones"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "route53:GetChange",
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageRecords"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
        ]
        Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.billgrant.zone_id}"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "terraform_ci_route53" {
  user       = aws_iam_user.terraform_ci.name
  policy_arn = aws_iam_policy.terraform_ci_route53.arn
}

# IAM policy for Terraform CI to manage certbot IAM resources in project terraform
resource "aws_iam_policy" "terraform_ci_iam" {
  name        = "terraform-ci-iam-music-graph"
  description = "Allows Terraform CI to manage IAM users/policies for certbot"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageCertbotUser"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:ListAccessKeys",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:GetAccessKeyLastUsed",
        ]
        Resource = "arn:aws:iam::365673647556:user/certbot-music-graph"
      },
      {
        Sid    = "ManageCertbotPolicy"
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions",
        ]
        Resource = "arn:aws:iam::365673647556:policy/certbot-route53-dns-music-graph"
      },
      {
        Sid    = "ManagePolicyAttachment"
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:ListAttachedUserPolicies",
        ]
        Resource = "arn:aws:iam::365673647556:user/certbot-music-graph"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "terraform_ci_iam" {
  user       = aws_iam_user.terraform_ci.name
  policy_arn = aws_iam_policy.terraform_ci_iam.arn
}

output "state_buckets" {
  description = "GCS buckets for Terraform state"
  value       = { for k, v in google_storage_bucket.terraform_state : k => v.name }
}

output "terraform_ci_service_account" {
  description = "Terraform CI service account email"
  value       = google_service_account.terraform_ci.email
}

output "terraform_ci_key" {
  description = "Terraform CI service account key (base64 encoded) - add to GitHub Secrets as TERRAFORM_SA_KEY"
  value       = google_service_account_key.terraform_ci.private_key
  sensitive   = true
}

output "aws_access_key_id" {
  description = "AWS Access Key ID for Terraform CI - add to GitHub Secrets as AWS_ACCESS_KEY_ID"
  value       = aws_iam_access_key.terraform_ci.id
}

output "aws_secret_access_key" {
  description = "AWS Secret Access Key for Terraform CI - add to GitHub Secrets as AWS_SECRET_ACCESS_KEY"
  value       = aws_iam_access_key.terraform_ci.secret
  sensitive   = true
}

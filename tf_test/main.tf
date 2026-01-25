variable "token" {
  description = "GitHub PAT"
  type        = string
}

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.token
  owner = "Practical-DevOps-GitHub"
}

locals {
  repo_name = "github-terraform-task-berehx"
}

resource "github_repository_collaborator" "softserve_user" {
  repository = local.repo_name
  username   = "softservedata"
  permission = "push"
}

resource "github_branch" "develop" {
  repository    = local.repo_name
  branch        = "develop"
  source_branch = "main"
}

resource "github_branch_default" "default" {
  repository = local.repo_name
  branch     = github_branch.develop.branch
}

resource "github_branch_protection" "develop_rules" {
  repository_id = local.repo_name
  pattern       = "develop"
  required_pull_request_reviews {
    required_approving_review_count = 2
  }
  depends_on = [github_branch.develop]
}

resource "github_branch_protection" "main_rules" {
  repository_id = local.repo_name
  pattern       = "main"
  required_pull_request_reviews {
    required_approving_review_count = 1
    restrict_dismissals             = true
  }
}

resource "github_repository_deploy_key" "main_key" {
  title      = "DEPLOY_KEY"
  repository = local.repo_name
  key        = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMhkkfN139J/pRwB1Sf42bYIKZFKfMj3RZisIG/+B6U neo@MacBookAir"
  read_only  = true
}

resource "github_actions_secret" "pat_secret" {
  repository      = local.repo_name
  secret_name     = "PAT"
  plaintext_value = var.token
}

resource "github_repository_webhook" "discord" {
  repository = local.repo_name
  configuration {
    url          = "https://discord.com/api/webhooks/1464987359513804965/usO6NjLmEpGgyS7lheG7MzezjClM-eq8-qmwcVdWM7_qvwVP6kQFDCcgc5L08a7VuCSb/github"
    content_type = "json"
  }
  events = ["pull_request"]
}

resource "github_repository_file" "pr_template" {
  repository          = local.repo_name
  file                = ".github/pull_request_template.md"
  content             = "Describe your changes\n\nIssue ticket number and link\n\nChecklist..."
  branch              = "main"
  overwrite_on_create = true
}

resource "github_repository_file" "codeowners" {
  repository          = local.repo_name
  file                = "CODEOWNERS"
  content             = "* @softservedata"
  branch              = "main"
  overwrite_on_create = true
}

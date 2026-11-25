# A lab root in miniature: the org and its users, then one project with an
# OIDC client and a machine user. The provider is configured here, in the
# root, never in a module.

terraform {
  required_version = ">= 1.11"
  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "~> 3.0"
    }
  }
}

provider "zitadel" {
  domain           = var.zitadel_domain
  insecure         = false
  port             = "443"
  jwt_profile_file = var.jwt_profile_file
}

variable "zitadel_domain" {
  type        = string
  description = "ZITADEL instance, e.g. zitadel.example.com."
}

variable "jwt_profile_file" {
  type        = string
  description = "Path to the machine key (JSON) of the terraform machine user."
}

module "users" {
  # Consumers pin a tag:
  # source = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/org-users?ref=v0.1.0"
  source = "../../modules/org-users"

  users = {
    "jane" = {
      email      = "jane@example.com"
      first_name = "Jane"
      last_name  = "Doe"
    }
  }
}

module "argocd" {
  # source = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/oidc-project?ref=v0.1.0"
  source = "../../modules/oidc-project"

  org_id       = module.users.org_id
  project_name = "argocd"
  roles        = { "argocd-admin" = "Argo CD Admin" }

  apps = {
    "argocd-cluster1" = {
      redirect_uris             = ["https://argocd.cluster1.example.com/auth/callback"]
      post_logout_redirect_uris = ["https://argocd.cluster1.example.com/"]
    }
  }

  user_ids   = module.users.user_ids
  user_roles = { "jane" = ["argocd-admin"] }

  machine_users = {
    "argocd-ci" = {
      description = "CI access to the Argo CD API"
      roles       = ["argocd-admin"]
    }
  }
}

output "client_ids" {
  value     = module.argocd.client_ids
  sensitive = true
}

output "client_secrets" {
  value     = module.argocd.client_secrets
  sensitive = true
}

# Provision TFE workspaces for a project with multiple environments
#   local var, project_name - defines the name of the project
#   local var, workspaces - list of environments needed
#   created workspace names are of format {project}-{environment}

provider "tfe" {
  hostname = var.tfe_hostname
}

variable "tfe_hostname" {
  description = "The domain where TFE is hosted."
  default     = "app.terraform.io"
}

variable "tfc_org" {
  default = "multicloud-dev"
}

locals {
  project_name = "customer-alpha"

  workspaces = toset(["dev", "staging", "prod"])
}

resource "tfe_workspace" "this" {
  for_each     = local.workspaces
  name         = "${local.project_name}-${each.key}"
  organization = var.tfc_org
}

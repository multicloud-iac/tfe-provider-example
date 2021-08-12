# Create team on TFE and assign workspace permissions
#   Uses workspaces created in step 1
# This code
#   creates three teams: developers, manager, operators
#   assign permissions to workspaces as defined in locals
#   Add team_xxx = {} for each team you want to assign to workspace.

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

  teams = toset(["developers-team", "managers-team", "operators-team"])

  # map teams to workspaces
  team_dev = {
    "${data.tfe_workspace.this["dev"].id}"     = "write"
    "${data.tfe_workspace.this["staging"].id}" = "plan"
    "${data.tfe_workspace.this["prod"].id}"    = "read"
  }
  team_managers = {
    "${data.tfe_workspace.this["dev"].id}"     = "write"
    "${data.tfe_workspace.this["staging"].id}" = "write"
    "${data.tfe_workspace.this["prod"].id}"    = "plan"
  }
  team_ops = {
    "${data.tfe_workspace.this["dev"].id}"     = "write"
    "${data.tfe_workspace.this["staging"].id}" = "write"
    "${data.tfe_workspace.this["prod"].id}"    = "write"
  }
}

# create teams
resource "tfe_team" "this" {
  for_each     = local.teams
  name         = each.key
  organization = var.tfc_org
}

# Grab ids of workspaces defined in locals
data "tfe_workspace" "this" {
  for_each     = local.workspaces
  name         = "${local.project_name}-${each.key}"
  organization = var.tfc_org
}

#------------------------------------------------------------------------------
# Assign Team Access to Workspaces
#------------------------------------------------------------------------------

resource "tfe_team_access" "dev" {
  for_each     = local.team_dev
  access       = each.value
  team_id      = tfe_team.this["developers-team"].id
  workspace_id = each.key
}

resource "tfe_team_access" "managers" {
  for_each     = local.team_managers
  access       = each.value
  team_id      = tfe_team.this["managers-team"].id
  workspace_id = each.key
}

resource "tfe_team_access" "ops" {
  for_each     = local.team_ops
  access       = each.value
  team_id      = tfe_team.this["operators-team"].id
  workspace_id = each.key
}

#------------------------------------------------------------------------------
# OUTPUTS
#------------------------------------------------------------------------------

output "tfe_workspaces" {
  value = { for k, v in data.tfe_workspace.this : k => v.id }
}

output "tfe_teams" {
  value = { for k, v in tfe_team.this : k => v.id }
}

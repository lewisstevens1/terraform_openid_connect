locals {
  providers = {
    github    = var.github,
    gitlab    = var.gitlab,
    bitbucket = var.bitbucket
  }

  default = {
    github = {
      identity_provider_url = "token.actions.githubusercontent.com"
      audience              = "sts.amazonaws.com"
      repositories          = ["*"]
      permission_statements = [{
        Effect : "Allow",
        Resource : "*",
        Action : [
          "*"
        ]
      }]
    }

    gitlab = {
      identity_provider_url = "gitlab.com"
      audience              = "https://gitlab.com"
      project_slug          = "*"
      permission_statements = [{
        Effect : "Allow",
        Resource : "*",
        Action : [
          "*"
        ]
      }]
    }

    bitbucket = {
      identity_provider_url = format("api.bitbucket.org/2.0/workspaces/%s/pipelines-config/identity/oidc", var.bitbucket.workspace_name)
      audience              = format("ari:cloud:bitbucket::workspace/%s", replace(var.bitbucket.workspace_uuid, "/[{}]/", ""))
      repository_uuids      = ["*"]
      permission_statements = [{
        Effect : "Allow",
        Resource : "*",
        Action : [
          "*"
        ]
      }]
    }
  }

  enabled_providers = { for provider_key, provider_value in local.providers : provider_key => merge(
    # Add default settings
    local.default[provider_key],

    # Override with module input options
    { for item_key, item_value in provider_value : item_key => item_value if item_value != null }
  ) if provider_value.enabled }
}

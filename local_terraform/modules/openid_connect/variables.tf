variable "github" {
  type = object({
    enabled        = bool
    workspace_name = string
    repositories   = optional(string)
    permission_statements = optional(list(
      object({
        Effect   = string
        Action   = list(string)
        Resource = string
      })
    ))
  })

  default = {
    enabled        = false
    workspace_name = ""
    permission_statements = []
  }
}

variable "gitlab" {
  type = object({
    enabled   = bool
    group_url = string
    permission_statements = optional(list(
      object({
        Effect   = string
        Action   = list(string)
        Resource = string
      })
    ))
  })

  default = {
    enabled   = false
    group_url = ""
  }
}

variable "bitbucket" {
  type = object({
    enabled          = bool
    workspace_name   = string
    workspace_uuid   = string
    repository_uuids = optional(string)
    permission_statements = optional(list(
      object({
        Effect   = string
        Action   = list(string)
        Resource = string
      })
    ))
  })

  default = {
    enabled        = false
    workspace_name = ""
    workspace_uuid = ""
  }

  validation {
    condition = (
      var.bitbucket.enabled ? (
        length(var.bitbucket.workspace_name) > 0 &&
        length(var.bitbucket.workspace_uuid) > 0
      ) : true
    )
    error_message = "Workspace name and uuid is required. These can be found from OpenId Connect under the pipeline settings."
  }
}
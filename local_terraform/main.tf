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

locals {
  permission_statements = [
    {
      Effect : "Allow",
      Action : [
        "sns:*",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      Resource : "*"
    }
  ]
}

module "openid_connect" {
  source = "./modules/openid_connect"

  github = {
    enabled               = true
    workspace_name        = "lewisstevens1"
    permission_statements = local.permission_statements
  }

  gitlab = {
    enabled               = true
    group_url             = "https://www.gitlab.com/lewisstevens1"
    permission_statements = local.permission_statements
  }

  bitbucket = {
    enabled               = true
    workspace_name        = "digitickets"
    workspace_uuid        = "{aa97ce21-ab7e-49e8-af15-c2a5ed57512f}"
    permission_statements = local.permission_statements
  }
}

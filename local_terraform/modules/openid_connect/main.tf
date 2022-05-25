data "tls_certificate" "oid_provider" {
  for_each = local.enabled_providers

  url = format("https://%s", each.value.identity_provider_url)
}

resource "aws_iam_openid_connect_provider" "oid_provider" {
  for_each = local.enabled_providers

  url = format("https://%s", each.value.identity_provider_url)

  client_id_list = [
    each.value.audience
  ]

  thumbprint_list = [
    data.tls_certificate.oid_provider[each.key].certificates.0.sha1_fingerprint
  ]
}

data "aws_iam_policy_document" "assuming_role" {
  for_each = local.enabled_providers


  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    // Allow federated access with the oid provider's arn
    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.oid_provider[each.key].arn
      ]
    }

    // Allow access when audience is matching the audience value
    condition {
      test     = "StringLike"
      variable = format("%s:aud", each.value.identity_provider_url)

      values = [
        each.value.audience
      ]
    }


    condition {
      test     = "StringLike"
      variable = format("%s:sub", each.value.identity_provider_url)

      values = concat(
        # Github
        each.key == "github" ? formatlist("repo:%s/%s:*", each.value.workspace_name, each.value.repositories) : [],

        # Bitbucket
        each.key == "bitbucket" ? formatlist("%s:*", each.value.repository_uuids) : [],

        compact([
          # Gitlab
          each.key == "gitlab" ? format(
            "*:%s:*:*:*:*",
            join("/",
              slice(
                split("/", replace(each.value.group_url, "https://", "")),
                1,
                length(
                  split("/", replace(each.value.group_url, "https://", ""))
                )
              )
            )
          ) : null,
        ])
      )

    }
  }
}

resource "aws_iam_role" "assuming_role" {
  for_each = local.enabled_providers

  name               = format("identity-provider-%s-assume-role", each.key)
  assume_role_policy = data.aws_iam_policy_document.assuming_role[each.key].json

  inline_policy {
    name = "identity-provider-permissions"

    policy = jsonencode({
      Version   = "2012-10-17",
      Statement = each.value.permission_statements
    })
  }
}

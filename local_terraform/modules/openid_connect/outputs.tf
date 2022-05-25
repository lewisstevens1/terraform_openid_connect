output "count_certificate_thumbprints" {
  value = length(data.tls_certificate.oid_provider)
}

output "count_created_providers" {
  value = length(
    compact(
      values(aws_iam_openid_connect_provider.oid_provider)[*].arn
    )
  )
}

output "count_expected_providers" {
  value = length(local.enabled_providers)
}
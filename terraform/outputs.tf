output "cluster_name"                        { description = "EKS cluster name."              ; value = module.eks.cluster_name }
output "cluster_endpoint"                    { description = "EKS API endpoint."              ; value = module.eks.cluster_endpoint; sensitive = true }
output "cluster_certificate_authority_data"  { description = "Base64 CA cert."               ; value = module.eks.cluster_certificate_authority_data; sensitive = true }
output "oidc_provider_arn"                   { description = "OIDC provider ARN."            ; value = module.eks.oidc_provider_arn }
output "secrets_manager_role_arn"            { description = "IRSA role for Secrets Manager."; value = module.secrets_manager_irsa.iam_role_arn }
output "vpc_id"                              { description = "VPC ID."                        ; value = module.vpc.vpc_id }
output "private_subnet_ids"                  { description = "Private subnet IDs."           ; value = module.vpc.private_subnets }

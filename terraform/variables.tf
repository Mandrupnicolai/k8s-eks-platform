variable "aws_region"           { description = "AWS region."                    ; type = string }
variable "environment"          { description = "dev / staging / prod."           ; type = string; validation { condition = contains(["dev","staging","prod"], var.environment); error_message = "Must be dev, staging, or prod." } }
variable "project"              { description = "Project identifier."             ; type = string; default = "k8s-eks-platform" }
variable "tf_state_bucket"      { description = "S3 bucket for Terraform state."  ; type = string }
variable "tf_state_lock_table"  { description = "DynamoDB table for state lock."  ; type = string }
variable "vpc_cidr"             { description = "VPC CIDR block."                 ; type = string; default = "10.0.0.0/16" }
variable "availability_zones"   { description = "List of AZs."                   ; type = list(string) }
variable "private_subnet_cidrs" { description = "Private subnet CIDRs."          ; type = list(string) }
variable "public_subnet_cidrs"  { description = "Public subnet CIDRs."           ; type = list(string) }
variable "cluster_name"         { description = "EKS cluster name."              ; type = string }
variable "kubernetes_version"   { description = "Kubernetes version."            ; type = string; default = "1.30" }
variable "node_group_instance_types" { description = "Node instance types."      ; type = list(string); default = ["t3.medium"] }
variable "node_group_min_size"  { description = "Min nodes."                     ; type = number; default = 2 }
variable "node_group_max_size"  { description = "Max nodes."                     ; type = number; default = 6 }
variable "node_group_desired_size" { description = "Desired nodes."             ; type = number; default = 2 }
variable "secrets_prefix"       { description = "Secrets Manager path prefix."   ; type = string; default = "/k8s-eks-platform" }

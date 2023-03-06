variable "instance_type_utility" {
    description = "This defines utility (Sonarqube + PHPMyAdmin) Instance Size/Type"
    type        = string
    default     = ""
}
variable "volume_size_utility" {
    description = "This defines utility (Sonarqube + PHPMyAdmin) Instance Root Volume Size"
    type        = number
    default     = "30"
}
variable "pem_key_name" {
    description = "This defines Pem Key Name"
    type        = string
    default     = ""
}
variable "vpc_id" {
    description = "This defines utility (Sonarqube + PHPMyAdmin) Instance VPC ID"
    type        = string
    default     = ""
}
variable "vpc_cidr_block" {
    description = "This defines utility (Sonarqube + PHPMyAdmin) Instance VPC CIDR Block"
    type        = string
    default     = ""
}
variable "subnet_id" {
    description = "This defines utility (Sonarqube + PHPMyAdmin) Instance VPC Subnet ID"
    type        = string
    default     = ""
}
variable "postgresql_endpoint" {
    description = "This defines utility PostgreSQL Endpoint"
    type        = string
    default     = ""
}

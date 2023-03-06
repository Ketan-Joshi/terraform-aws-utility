module "prometheus" {
    source = "../"
    instance_type_utility = "t3.large"
    volume_size_utility = "50"
    pem_key_name = "utility"
    vpc_cidr_block = ""
    vpc_id = ""
    subnet_id = ""
    postgresql_endpoint = ""
    sonarqube_password = ""
    sonarqube_user = ""
    sonarqube_database = ""
}
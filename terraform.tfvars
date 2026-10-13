
aws_region = "eu-west-1"
project_id = "cmtr-n9nbj5cz"
vpc_name   = "cmtr-n9nbj5cz-vpc"

public_subnet_a_cidr  = "10.0.1.0/24"
private_subnet_a_cidr = "10.0.2.0/24"
public_subnet_b_cidr  = "10.0.3.0/24"
private_subnet_b_cidr = "10.0.4.0/24"

ec2_security_group_name  = "cmtr-n9nbj5cz-ec2_sg"
http_security_group_name = "cmtr-n9nbj5cz-http_sg"
alb_security_group_name  = "cmtr-n9nbj5cz-sglb"

instance_profile_name = "cmtr-n9nbj5cz-instance_profile"
key_pair_name         = "cmtr-n9nbj5cz-keypair"

instance_type    = "t3.micro"
desired_capacity = 2
min_size         = 1
max_size         = 2
http_port        = 80



ami_name         = "al2023-ami-2023.*-x86_64"
ami_owner        = "amazon"
ami_architecture = "x86_64"
ami_state        = "available"
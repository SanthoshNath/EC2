# EC2

Terraform module to build infrastructure for EC2 instance along with Application load balancer in a VPC.

## Usage

```terraform
module "ec2" {
  source = "github.com/SanthoshNath/EC2?ref=v1.0"

  name_prefix    = "example"
  vpc_cidr_block = "10.0.0.0/24"
  instance_ami   = "ami-12345"
  instance_type  = "t2.micro"
  port           = 80
}
```

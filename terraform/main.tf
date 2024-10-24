provider "aws" {
  region = "us-east-1"  # Replace with your preferred region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("/home/tal/.ssh/id_rsa.pub") # Update path if necessary
}
resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "centos" {
  count         = 2
  ami           = "ami-0df2a11dd1fe1f8e3"  # Replace with the actual AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.ssh.name]
  user_data                   = templatefile("${path.module}/user_data.sh", { public_key = file("${path.module}/public_key.pub") })
  associate_public_ip_address = true
}

resource "aws_ebs_volume" "data_volume" {
  count             = 4  # 2 volumes per instance
  availability_zone = element(aws_instance.centos.*.availability_zone, count.index % 2)
  size              = 1
}

resource "aws_volume_attachment" "ebs_attachment" {
  count       = 4
  device_name = element(["/dev/sdf", "/dev/sdg"], count.index % 2)
  volume_id   = aws_ebs_volume.data_volume[count.index].id
  instance_id = aws_instance.centos[count.index < 2 ? 0 : 1].id
}
resource "aws_eip" "elastic_ip" {
  count    = 2
  instance = aws_instance.centos[count.index].id
  domain      = "vpc"
}

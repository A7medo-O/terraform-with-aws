provider "aws" {
  region = "us-east-1"
}

# -------- VPC --------
resource "aws_vpc" "my_vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# -------- Public Subnet --------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "192.168.56.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "192.168.57.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}


# -------- Internet Gateway --------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}


# -------- Route Table --------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}


# Attach Route Table → Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------------
# MQ
# --------------------------


resource "aws_mq_broker" "rabbitmq" {
  broker_name = "my-rabbitmq-broker"

  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  auto_minor_version_upgrade = true

  host_instance_type = "mq.t3.micro"

  publicly_accessible = true
  deployment_mode     = "SINGLE_INSTANCE"

  
  #security_groups = [aws_security_group.allow_all.id]

  
  subnet_ids = [aws_subnet.public_subnet.id]

  user {
    username = "admin"
    password = "admin1234567"
  }
}


# --------------------------
# Security Group (Open Inbound)
# --------------------------

resource "aws_security_group" "allow_all" {
  name        = "allow_all_sg"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow all inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# --------------------------
# EC2 Instance 
# --------------------------
resource "aws_instance" "my_ec2" {
  ami           = "ami-0ecb62995f68bb549"  # Ubuntu Server 22.04 LTS (us-east-1)
  instance_type = "t3.micro"
  private_ip             = "192.168.56.12"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [ aws_security_group.allow_all.id ]
  key_name      = "project"
  # associate_public_ip_address = true
  #user_data = file("setup.sh")

  # --------------------------
  # Provisioners to run script
  # --------------------------
  provisioner "file" {
    source      = "setup.sh"
    destination = "/home/ubuntu/setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/abokkhaled/Downloads/project.pem")
      host        = self.public_ip
      timeout     = "1m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup.sh",
      "sudo /home/ubuntu/setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/abokkhaled/Downloads/project.pem")
      host        = self.public_ip
    }
  }




}




# --------------------------
# Elastic IP (Static Public IP)
# --------------------------
resource "aws_eip" "static_ip" {
  instance = aws_instance.my_ec2.id
  # vpc      = true

}

output "ec2_public_ip" {
  value = aws_eip.static_ip.public_ip
}
output "ec2_private_ip" {
  value = aws_instance.my_ec2.private_ip
}



# -------- RDS Subnet Group --------
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.public_subnet.id,
  aws_subnet.public_subnet_2.id]
  tags = { Name = "my-db-subnet-group" }
}

# -------- RDS Security Group --------
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow MySQL access"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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

# -------- RDS MySQL Instance --------
resource "aws_db_instance" "my_rds" {
  identifier             = "my-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  #name                   = "mydatabase" 
  username               = "admin"           # admin user
  password               = "admin123"  
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true
}

output "rds_endpoint" {
  value = aws_db_instance.my_rds.endpoint
}


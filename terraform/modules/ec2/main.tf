// Create aws_ami filter to pick up the ami available in your region
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

// Configure the EC2 instance in a public subnet
resource "aws_instance" "ec2_public" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = var.public_sub
  key_name                    = var.key_name
  vpc_security_group_ids      = ["${var.security_group}"]
  tags = {
    Name = "tf-example"
  }
  user_data = <<-EOL
  #!/bin/bash

sudo yum install -y java-1.8*
sudo wget -P /opt https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz
sudo tar -xvf /opt/apache-tomcat-9.0.85.tar.gz --directory /opt
sudo mv /opt/apache-tomcat-9.0.85 /opt/tomcat9
sudo useradd -r tomcat
chown -R tomcat:tomcat /opt/tomcat9
sudo tee /etc/systemd/system/tomcat.service<<EOF
[Unit]
Description=Tomcat Server
After=syslog.target network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment=CATALINA_HOME=/opt/tomcat9
Environment=CATALINA_BASE=/opt/tomcat9
Environment=CATALINA_PID=/opt/tomcat9/temp/tomcat.pid

ExecStart=/opt/tomcat9/bin/catalina.sh start
ExecStop=/opt/tomcat9/bin/catalina.sh stop

RestartSec=12
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo chmod -R 777 /opt/tomcat9/
sudo systemctl daemon-reload
sudo systemctl start tomcat
EOL
}


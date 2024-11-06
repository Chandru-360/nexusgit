#!/bin/bash

# Update package list and install OpenJDK 17
sudo apt update
sudo apt install openjdk-17-jdk -y

# Verify the installation
java -version

# Download and install Nexus Repository Manager
cd /opt
sudo wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
sudo tar -xvzf latest-unix.tar.gz
sudo mv /opt/nexus-3.* /opt/nexus

# Create a new user for running Nexus
sudo adduser nexus --disabled-password --gecos ""
echo "nexus ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# Change ownership of Nexus files
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

# Configure Nexus to run as the nexus user
sudo sed -i 's/#run_as_user=/run_as_user="nexus"/' /opt/nexus/bin/nexus.rc

# Increase JVM heap size
echo '-XX:MaxDirectMemorySize=2703m' | sudo tee -a /opt/nexus/bin/nexus.vmoptions
echo '-Djava.net.preferIPv4Stack=true' | sudo tee -a /opt/nexus/bin/nexus.vmoptions

# Create a systemd service file for Nexus
sudo bash -c 'cat <<EOF > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF'

# Start and enable Nexus service
sudo systemctl start nexus
sudo systemctl enable nexus

# Check Nexus service status
sudo systemctl status nexus

# Open firewall port 8081 if UFW is running
sudo ufw allow 8081/tcp

echo "Nexus Repository Manager installation is complete. Access it at http://<server_IP>:8081"


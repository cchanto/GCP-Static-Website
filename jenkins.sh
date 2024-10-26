#!/bin/bash

# Set variables
VM_NAME="jenkins-vm"
ZONE="us-central1-a"
MACHINE_TYPE="n1-standard-1"
IMAGE_FAMILY="debian-11"
IMAGE_PROJECT="debian-cloud"

# Create a new VM instance with the necessary scopes
gcloud compute instances create $VM_NAME \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --scopes=https://www.googleapis.com/auth/cloud-platform

# Wait for the VM to be ready
echo "Waiting for VM to start..."
sleep 30

# SSH into the VM and install Jenkins
gcloud compute ssh $VM_NAME --zone=$ZONE --command "
    # Update package lists
    sudo apt update && sudo apt upgrade -y

    # Install prerequisites
    sudo apt install -y wget openjdk-11-jdk

    # Add Jenkins GPG key
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -

    # Add Jenkins repository
    echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list

    # Update package lists again
    sudo apt update

    # Install Jenkins
    sudo apt install -y jenkins

    # Start and enable Jenkins service
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

    # Display Jenkins initial admin password
    echo 'Access Jenkins at http://<your-external-ip>:8080'
    echo 'Initial Admin Password:'
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
"

echo "Jenkins installation script completed."

# Static Website on Google Cloud with HTTPS Load Balancer

## Overview

This project sets up a static website hosted on Google Cloud Platform (GCP) using Terraform. The infrastructure includes a Google Cloud Storage bucket for static content, Cloud CDN for caching, and necessary networking components, such as a global IP address and DNS configuration.

## Folder Structure


## Requirements

- **Terraform**: Ensure you have [Terraform](https://www.terraform.io/downloads.html) installed on your machine.
- **Google Cloud SDK**: Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) to interact with GCP.

## Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/cchanto/GCP-Static-Website.git
   cd GCP-Static-Website

   Configure Variables:

Update the variables.tf file to set your GCP project ID and any other required variables.


## Limitations
Bucket Lock: The project does not implement bucket lock features due to the need for frequent recreations of the bucket.
Region Limitations: Ensure that the selected regions for resources align with your project needs and any restrictions imposed by your organization.
Scaling: The current setup does not include autoscaling configurations for handling high traffic loads.
Cost Management: Be aware of the costs associated with using GCP resources, particularly with data transfer and storage.
Security Best Practices
IAM Roles: Ensure that the service account used for Terraform has the necessary IAM roles to create and manage resources.
HTTPS: Use managed SSL certificates for secure communication over HTTPS.
CORS Policy: Implement appropriate CORS policies on your Cloud Storage bucket if required.
Network Security: Configure firewall rules to restrict access to only necessary IP ranges.
Contributing
Feel free to contribute to this project by submitting issues or pull requests. Your contributions are welcome!

License
This project is licensed under the MIT License - see the LICENSE file for details.

markdown


### How to Use

1. **Copy and Paste**: Copy the above content into a file named `README.md` in your project root directory.
2. **Modify as Needed**: Adjust any project-specific details, such as the repository URL, additional instructions, or any other relevant information.

This README provides a clear overview of your project and guidelines for users and contributors. Let me know if you need further modifications or additional sections!

```plaintext
Structure 
/GCP-Static-Website │ ├── /modules │ ├── /load_balancer │ │ ├── main.tf │ │ ├── variables.tf │ │ └── outputs.tf │ ├── /networking │ │ ├── main.tf │ │ ├── variables.tf │ │ └── outputs.tf │ ├── /ssl_certificate │ │ ├── main.tf │ │ ├── variables.tf │ │ └── outputs.tf │ └── /storage │ ├── main.tf │ ├── variables.tf │ └── outputs.tf │ ├── main.tf ├── variables.tf └── README.md

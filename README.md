Static Website Deployment on Google Cloud with Terraform
This project demonstrates how to deploy a static website on Google Cloud Storage (GCS) with HTTPS using Cloud CDN and Google Cloud DNS. Infrastructure as Code (IaC) is managed using Terraform to automate the deployment process.

Project Overview
Website Hosting: The static website is hosted in a GCS bucket.
HTTPS: Configured with Cloud CDN and SSL certificates for secure access.
DNS: Cloud DNS is set up for a custom domain.
Caching: Cloud CDN is used to speed up content delivery, and cache settings are configurable.
Prerequisites
Google Cloud Account: A GCP account with necessary permissions (Storage Admin, Compute Admin, and DNS Admin).
Terraform: Version 0.12+ is required.
gcloud CLI: Set up and authenticated to manage Google Cloud resources.
Architecture
Google Cloud Storage (GCS): Hosts the static website files.
Cloud CDN: Provides content caching and HTTPS.
Cloud DNS: Manages the custom domain for the website.
Directory Structure
graphql

project-root/
├── main.tf                   # Root Terraform configuration
├── modules/
│   └── cloud-storage-static-website/ # Module for GCS setup
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── index.html                # Static HTML file for the website
└── README.md                 # Project documentation
Setup & Configuration
1. Configure Google Cloud Project and Variables
Define the necessary variables in variables.tf or using environment variables in Terraform.

hcl

variable "project" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "website_domain_name" {
  description = "Domain name for the website (e.g., example.com)"
  type        = string
}

variable "website_location" {
  description = "Region for the GCS bucket (e.g., US)"
  type        = string
}

variable "index_page" {
  description = "Name of the main page (e.g., index.html)"
  type        = string
  default     = "index.html"
}

variable "not_found_page" {
  description = "Name of the 404 page (e.g., 404.html)"
  type        = string
  default     = "404.html"
}
2. Deploy Infrastructure
Run the following Terraform commands to deploy the static website infrastructure.

Initialize Terraform:

bash

terraform init
Plan the Deployment:

bash

terraform plan
Apply the Configuration:

bash

terraform apply -auto-approve
3. Upload Website Content
The static content for the website (e.g., index.html, 404.html) needs to be uploaded to the GCS bucket. Terraform automates this upload:

hcl

resource "google_storage_bucket_object" "index" {
  name    = var.index_page
  content = file("index.html")
  bucket  = module.static_site.website_bucket_name
  metadata = {
    "Cache-Control" = "no-cache, max-age=0"
  }
}
This configuration ensures that the website is served with minimal caching, allowing immediate updates.

Key Resources Created
Google Cloud Storage Bucket: Holds the static website files.
Cloud CDN: Configures HTTPS and speeds up content delivery.
Cloud DNS: Manages DNS for the custom domain.
Cache Management
To ensure the latest content is visible, purge the Cloud CDN cache if updates are not reflected immediately:

bash

gcloud compute url-maps invalidate-cdn-cache [URL_MAP_NAME] --path "/*"
Troubleshooting
Cache Issues: Use the cache invalidation command above to force refresh content.
Access Issues: Ensure public access is granted to the bucket objects.
DNS Propagation: Allow time for DNS changes to propagate.
Additional Notes
Security: The bucket is publicly accessible. For private deployments, consider using signed URLs.
Cost Management: Be aware of Cloud CDN and Cloud DNS costs, especially when testing.
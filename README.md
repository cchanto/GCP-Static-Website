## Static Website on Google Cloud with HTTPS Load Balancer

This Terraform configuration deploys a static website on Google Cloud Storage (GCS), served over HTTPS using a load balancer. The configuration includes automatic content caching, DNS settings, and public accessibility.


## Requirements
Google Cloud Project: You need a Google Cloud project with billing enabled.
Terraform: Ensure you have Terraform v0.12.26 or later installed.
Google Cloud SDK: Authenticate via Google Cloud SDK if running locally.

## Project Structure

Below is the directory structure of the project:

## Project Structure

Below is the directory structure of the project:

```plaintext
project-root/
├── infra/                       # Contains Terraform infrastructure code
│   ├── main.tf                  # Main configuration file
│   ├── outputs.tf               # Output values for resources created
│   └── variables.tf             # Input variables for configuration
├── website/                     # Holds the website content
│   └── index.html               # HTML file to deploy to GCP bucket
└── README.md                    # Project documentation

          
## Requirements
Google Cloud Project: You need a Google Cloud project with billing enabled.
Terraform: Ensure you have Terraform v0.12.26 or later installed.
Google Cloud SDK: Authenticate via Google Cloud SDK if running locally.

## Terraform Configuration Overview
Resources Created
-GCS Bucket: Stores static website content.
-Google Compute Global Address: Reserves a global IP for the website.
-DNS Record: Maps the reserved IP to the domain in Google Cloud DNS.
-Google Compute Backend Bucket: Acts as a CDN-enabled backend for the load balancer.
-SSL Certificate: Provides HTTPS access.
-Load Balancer: Routes traffic to the GCS bucket over HTTPS.

# Key Settings
* Caching: CACHE_ALL_STATIC mode caches static content for optimized delivery.
* Cache TTLs: Set to 1 minute by default to allow for real-time updates.
* Negative Caching: Configures 404 and 410 responses to be cached for 5 minutes.
* No Versioning: GCS bucket versioning is disabled for simplicity.

## Setup
#### Step 1: Initialize and Apply Terraform
Set the GCP Project ID:

Update the PROJECT_ID environment variable in your Terraform configuration.
Run Terraform:

terraform -chdir=./infra init
terraform -chdir=./infra apply -auto-approve
This will create the GCS bucket, reserve an IP, configure DNS, set up caching, and deploy the HTTPS load balancer.

### Step 2: Upload Content
After deploying the infrastructure, upload the website content (e.g., index.html) to the GCS bucket:

bash
gsutil -h "Cache-Control:no-cache, max-age=0" cp ./website/index.html gs://chantowebtest

This command ensures that the CDN revalidates cached content on each request.

### Step 3: Test the Deployment
Public URL: The website should be accessible via the HTTPS load balancer using your custom domain.
Content Refresh: Due to caching, changes to the content may take up to 1 minute to appear.

## Configuration Details
google_storage_bucket: Configures the GCS bucket to store website content with public access and caching policies.
google_compute_backend_bucket: Enables CDN and cache policies for optimized performance.
google_compute_managed_ssl_certificate: Automates SSL certificate management for HTTPS access.
google_compute_url_map: Routes incoming traffic to the GCS bucket.
google_compute_global_forwarding_rule: Configures an external IP with HTTPS forwarding.

## Additional Notes
Cache Control: Content updates are made in real-time but cached with a 1-minute TTL for high availability.
DNS Propagation: DNS records may take time to propagate, so allow time after initial setup.



## Static Website on Google Cloud with HTTPS Load Balancer

This Terraform configuration deploys a static website on Google Cloud Storage (GCS), served over HTTPS using a load balancer. The configuration includes automatic content caching, DNS settings, and public accessibility.


## Requirements
Google Cloud Project: You need a Google Cloud project with billing enabled.
Terraform: Ensure you have Terraform v0.12.26 or later installed.
Google Cloud SDK: Authenticate via Google Cloud SDK if running locally.

## Directory Structure


project-root/
├── infra/                     # Contains main infrastructure configurations
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Project-level variables used in main Terraform config
│   └── outputs.tf             # Defines outputs from root configuration
├── website/                   # Contains website content
│   └── index.html             # HTML file to be deployed to GCS
└── README.md                  # Documentation for setup and usage

          
## Requirements
Google Cloud Project: You need a Google Cloud project with billing enabled.
Terraform: Ensure you have Terraform v0.12.26 or later installed.
Google Cloud SDK: Authenticate via Google Cloud SDK if running locally.

## Terraform Configuration Overview
Resources Created
-GCS Bucket: Stores static website content.
-Google Compute Global Address: Reserves a global IP for the website.
-DNS Record: Maps the reserved IP to the domain in Google Cloud DNS.
-Google Compute Backend Bucket: Acts as a CDN-enabled backend for the load balancer.
-SSL Certificate: Provides HTTPS access.
-Load Balancer: Routes traffic to the GCS bucket over HTTPS.

# Key Settings
* Caching: CACHE_ALL_STATIC mode caches static content for optimized delivery.
* Cache TTLs: Set to 1 minute by default to allow for real-time updates.
* Negative Caching: Configures 404 and 410 responses to be cached for 5 minutes.
* No Versioning: GCS bucket versioning is disabled for simplicity.

## Setup
#### Step 1: Initialize and Apply Terraform
Set the GCP Project ID:

Update the PROJECT_ID environment variable in your Terraform configuration.
Run Terraform:

terraform -chdir=./infra init
terraform -chdir=./infra apply -auto-approve
This will create the GCS bucket, reserve an IP, configure DNS, set up caching, and deploy the HTTPS load balancer.

### Step 2: Upload Content
After deploying the infrastructure, upload the website content (e.g., index.html) to the GCS bucket: could be manual steps 

bash
gsutil -h "Cache-Control:no-cache, max-age=0" cp ./website/index.html gs://chantowebtest

This command ensures that the CDN revalidates cached content on each request.

### Step 3: Test the Deployment
Public URL: The website should be accessible via the HTTPS load balancer using your custom domain.
Content Refresh: Due to caching, changes to the content may take up to 1 minute to appear.

## Configuration Details
google_storage_bucket: Configures the GCS bucket to store website content with public access and caching policies.
google_compute_backend_bucket: Enables CDN and cache policies for optimized performance.
google_compute_managed_ssl_certificate: Automates SSL certificate management for HTTPS access.
google_compute_url_map: Routes incoming traffic to the GCS bucket.
google_compute_global_forwarding_rule: Configures an external IP with HTTPS forwarding.

## Additional Notes
Cache Control: Content updates are made in real-time but cached with a 1-minute TTL for high availability.
DNS Propagation: DNS records may take time to propagate, so allow time after initial setup.## Updating the `index.html` Text Dynamically
(https://storage.googleapis.com/chantowebtest/index.html ) 

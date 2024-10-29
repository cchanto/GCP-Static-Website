pipeline {
    agent any
    options {
        disableConcurrentBuilds() // Prevents concurrent builds of the same job
    }
    environment {
        GITHUB_CREDENTIALS = credentials('fe07ee7b-0baa-4f6f-b181-262818930d78')
        PROJECT_ID = 'poc-test-infra'
        BUCKET_NAME = 'chantowebtest' // Replace with your actual bucket name
    }
    stages {
        stage('Terraform Init for Destroy') {
            steps {
                withCredentials([file(credentialsId: 'gcloud-creds', variable: 'GCLOUD_CREDS')]) {
                    sh '''
                    gcloud auth activate-service-account --key-file="$GCLOUD_CREDS"
                    gcloud config set project $PROJECT_ID
                    terraform -chdir=./Terraform init
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                sh '''
                terraform -chdir=./Terraform destroy -auto-approve
                '''
            }
        }
        stage('Cleanup Workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage('Clone Repository') {
            steps {
                script {
                    git url: 'https://github.com/cchanto/GCP-Static-Website.git', 
                        branch: 'main', 
                        credentialsId: 'fe07ee7b-0baa-4f6f-b181-262818930d78'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([file(credentialsId: 'gcloud-creds', variable: 'GCLOUD_CREDS')]) {
                    sh '''
                    gcloud auth activate-service-account --key-file="$GCLOUD_CREDS"
                    gcloud config set project $PROJECT_ID
                    terraform -chdir=./Terraform init
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                terraform -chdir=./Terraform plan -out=tfplan
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                terraform -chdir=./Terraform apply -auto-approve tfplan
                '''
            }
        }
    }
    post {
        success {
            echo 'Infrastructure built successfully, and content uploaded!'
        }
        failure {
            echo 'Failed to build infrastructure or upload content.'
        }
    }
}

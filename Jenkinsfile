pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Select the action to perform'
        )
    }

    environment {
        AWS_REGION = "ap-south-1"   // change if needed
        CLUSTER_NAME = "ankit-cluster"  // must match Terraform
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/akshaydchavan01-droid/terraform-eks-nodegroup.git'
            }
        }

        stage("Terraform Init") {
            steps {
                sh "terraform init -reconfigure"
            }
        }

        stage("Terraform Plan") {
            steps {
                sh "terraform plan"
            }
        }

        stage("Terraform Action") {
            steps {
                script {
                    if (params.ACTION == 'apply') {
                        sh "terraform apply --auto-approve"
                    } else {
                        sh "terraform destroy --auto-approve"
                    }
                }
            }
        }

        // ✅ Only run for APPLY
        stage('Update kubeconfig') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh '''
                aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
                '''
            }
        }

        stage('Apply aws-auth') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh '''
                kubectl apply -f aws-auth.yaml
                '''
            }
        }
    }
}
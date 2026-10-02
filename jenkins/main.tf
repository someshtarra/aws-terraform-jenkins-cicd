
terraform {
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "0.11.0"
    }
  }
}

variable "jenkins_api_token" {
  description = "Jenkins API token"
  type        = string
  sensitive   = true
}

provider "jenkins" {
  server_url = "http://100.62.171.250:8080"
  username   = "somesh"
  password   = var.jenkins_api_token
}

resource "jenkins_job" "hello_job" {
  name = "terraform-hello-job"

  template = <<-EOT
    <flow-definition plugin="workflow-job">
      <description>Jenkins pipeline created using Terraform</description>
      <keepDependencies>false</keepDependencies>

      <properties/>

      <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
        <script>
pipeline {
  agent any

  environment {
    GITHUB_REPO_URL = 'https://github.com/someshtarra/project-management.git'
    GITHUB_BRANCH   = 'main'
    DOCKER_IMAGE    = 'someshtarra/projectimage'
    DOCKER_USER     = 'someshtarra'
  }

  stages {
    stage('Checkout Stage') {
      steps {
        echo 'Checking out source code from GitHub'
        git branch: env.GITHUB_BRANCH, url: env.GITHUB_REPO_URL
      }
    }

    stage('Docker Build') {
      steps {
        echo 'Building Docker image'
        sh 'docker build -t $DOCKER_IMAGE:$${BUILD_NUMBER} -f Dockerfile .'
      }
    }

    stage('Docker Hub Push') {
      steps {
        echo 'Pushing Docker image to Docker Hub'

        withCredentials([string(credentialsId: 'dockerhub', variable: 'DOCKER_HUB')]) {
          sh '''
            echo "$DOCKER_HUB" | docker login -u "$DOCKER_USER" --password-stdin
            docker push "$DOCKER_IMAGE:$${BUILD_NUMBER}"
            docker logout
          '''
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully!'
    }
    failure {
      echo 'Pipeline failed. Check the console output.'
    }
  }
}
        </script>

        <sandbox>true</sandbox>
      </definition>

      <triggers/>
      <disabled>false</disabled>
    </flow-definition>
  EOT
}
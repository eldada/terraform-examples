# Terraform Playground
This repository contains a collection of Terraform configurations that I use to learn and experiment with Terraform.

## Install Terraform
Follow the [Install Terraform](https://developer.hashicorp.com/terraform/install) page to install Terraform on your machine.

## Getting Started
### AWS VPC and EC2 Instance
The work here assumes you have an AWS account and have the AWS CLI installed and configured.

Change to the [1.aws-vpc-and-ec2](1.aws-vpc-and-ec2) directory
```shell
cd 1.aws-vpc-and-ec2
```

The [main.tf](1.aws-vpc-and-ec2/main.tf) file is the first step in creating a Terraform configuration. This file contains the configuration that Terraform will use to create the resources in the cloud.

Initialize the Terraform configuration by running the following command
```shell
terraform init
```

Plan the Terraform configuration by running the following command
```shell
terraform plan
```

Apply the Terraform configuration by running the following command
```shell
terraform apply
```

### Nginx In Kubernetes
The work here assumes you have a Kubernetes cluster with `kubectl` installed and configured to this cluster.

Change to the [2.kubernetes-nginx](2.kubernetes-nginx) directory
```shell
cd 2.kubernetes-nginx
```

The [main.tf](2.kubernetes-nginx/main.tf) file has the configuration that Terraform will use to create the Nginx in the Kubernetes cluster.

Initialize the Terraform configuration by running the following command
```shell
terraform init
```

Plan the Terraform configuration by running the following command
```shell
terraform plan
```

Apply the Terraform configuration by running the following command
```shell
terraform apply
```

### Artifactory Provider
The work here assumes you have an Artifactory instance running and accessible.

Change to the [3.artifactory](3.artifactory) directory
```shell
cd 3.artifactory
```

If not already installed, you can easily install Artifactory in Kubernetes by running the following command
```shell
helm upgrade --install artifactory jfrog/artifactory --set postgresql.postgresqlPassword="password1"
```

Create an [Artifactory access token](https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory) and store it in the [terraform.tfvars](3.artifactory/terraform.tfvars) file
```text
artifactory_url = "http://localhost"
artifactory_access_token = "eyJ2ZXI..."
```

The [main.tf](3.artifactory/main.tf) file has the configuration that Terraform will use to configure the Artifactory server.

Initialize the Terraform configuration by running the following command
```shell
terraform init
```

Plan the Terraform configuration by running the following command
```shell
terraform plan
```

Apply the Terraform configuration by running the following command
```shell
terraform apply
```

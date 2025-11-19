# Terraform Examples
This repository contains a collection of [Terraform](https://www.terraform.io/) configurations that I use to learn and experiment with Terraform.

## Install Terraform
Follow the [Install Terraform](https://developer.hashicorp.com/terraform/install) page to install Terraform on your machine.

## Setting up Terraform with Artifactory
The recommended way to manage Terraform state is to use a remote backend.
Some of the repository examples use JFrog Artifactory as the remote backend (commented out).

To set up Terraform with Artifactory, follow the instructions in the [Terraform Artifactory Backend](https://jfrog.com/integration/terraform-artifactory-backend/) documentation.

## Examples
1. Create an [AWS VPC and EC2 Instance](1.aws-vpc-and-ec2)
2. Deploy [Nginx in Kubernetes](2.kubernetes-nginx)
3. Install [JFrog Artifactory with Helm](3.artifactory-install)
4. Manage [JFrog Artifactory configuration](4.artifactory-config) with the [Artifactory Provider](https://github.com/jfrog/terraform-provider-artifactory)

For an example of spinning up the needed infrastructure to deploy the JFrog Platform in AWS, see the [jfrog-platform-aws-install](https://github.com/jfrog/charts/tree/master/examples/terraform/jfrog-platform-aws-install) example in the official [JFrog Helm Charts repository](https://github.com/jfrog/charts/).

## Observability
For adding observability to the provisioned EKS clusters, see the [Observability](./Observability.md) page.

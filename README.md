# Terraform Playground
This repository contains a collection of Terraform configurations that I use to learn and experiment with Terraform.

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
5. Create an [AWS EKS (Kubernetes) cluster](5.aws-eks)
6. Create the needed [AWS infrastructure for running JFrog Artifactory](6.artifactory-aws-install) using RDS, S3, and EKS. This uses the [Artifactory Helm Chart](https://github.com/jfrog/charts/tree/master/stable/artifactory) to install Artifactory
7. Create the needed [AWS infrastructure for running JFrog Artifactory and Xray in AWS](7.jfrog-platform-aws-install) using RDS, S3, and EKS. This uses the [JFrog Platform Helm Chart](https://github.com/jfrog/charts/tree/master/stable/jfrog-platform) to install Artifactory and Xray

## EKS Monitoring
Many of the examples here spin up a Kubernetes cluster in AWS using EKS. To monitor the EKS cluster. 
An easy way to get an observability stack for the EKS is by using [coroot](https://coroot.com/). The following steps will guide you on how to install coroot in EKS.

NOTE: The instructions are also available in the [coroot operator install page](https://docs.coroot.com/installation/kubernetes/?edition=ce)

### Install
```shell
# Setup the coroot helm repository
helm repo add coroot https://coroot.github.io/helm-charts
helm repo update coroot

# Install the coroot operator
helm install -n coroot --create-namespace coroot-operator coroot/coroot-operator

# Install the coroot community edition helm chart
helm install -n coroot coroot coroot/coroot-ce --set "clickhouse.shards=2,clickhouse.replicas=2"
```
**NOTE:** Once installed, it will take a few minutes for data to be collected and displayed in the dashboard. Be patient.


Open the Coroot dashboard by running the following command
```shell
kubectl port-forward -n coroot service/coroot-coroot 8080:8080
```
And browsing to [http://localhost:8080](http://localhost:8080)

### Upgrade

The Coroot Operator for Kubernetes automatically upgrades all components.

### Uninstall

To uninstall Coroot run the following command:

```shell
helm uninstall coroot -n coroot
helm uninstall coroot-operator -n coroot
```

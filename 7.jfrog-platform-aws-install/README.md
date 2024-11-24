### JFrog Platform Installation in AWS with Terraform
This example will install Artifactory and Xray (with the [jfrog-platform helm chart](https://github.com/jfrog/charts/tree/master/stable/jfrog-platform)) in AWS using Terraform. The Artifactory and Xray installations will use the AWS services
1. RDS (PostgreSQL) as the database for each application
2. S3 as the Artifactory object storage
3. EKS as the Kubernetes cluster running Artifactory and Xray with pre-defined node groups for the different services

The resources are split between individual files for easy and clear separation.

The [jfrog-values.yaml](jfrog-values.yaml) file has the values that Helm will use to configure the JFrog Platform installation.

*IMPORTANT:* The Xray RabbitMQ is not using a persistent volume due to the lack of EBS provisioner in the EKS cluster. This will be fixed in a later version.

1. Initialize the Terraform configuration by running the following command
```shell
terraform init
```

2. Plan the Terraform configuration by running the following command
```shell
terraform plan
```

3. Apply the Terraform configuration by running the following command
```shell
terraform apply
```

4. When you are done, you can destroy the resources by running the following command
```shell
terraform destroy
```

## Accessing the EKS Cluster and Artifactory Installation
To get the `kubectl` configuration for the EKS cluster, run the following command
```shell
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
```

# Artifactory Installation in AWS with Terraform
This example will install Artifactory in AWS using Terraform. The Artifactory installation will use the AWS services
1. RDS (PostgreSQL) as the database
2. S3 as the object storage
3. EKS as the Kubernetes cluster running Artifactory

The resources are split between individual files for easy and clear separation.

The [artifactory-values.yaml](artifactory-values.yaml) file has the values that Helm will use to configure the Artifactory installation.

## Sizing
You will need to get the Artifactory sizing files from the helm chart. To do this, you should run the following command
```shell
helm fetch jfrog/artifactory --untar
```

## Terraform

1. Initialize the Terraform configuration by running the following command
```shell
terraform init
```

2. Plan the Terraform configuration by running the following command
```shell
terraform plan -var 'sizing=small'
```

3. Apply the Terraform configuration by running the following command
```shell
terraform apply -var 'sizing=small'
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

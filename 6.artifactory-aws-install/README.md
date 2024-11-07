### Artifactory Installation in AWS with Terraform
This example will install Artifactory in AWS using Terraform and Helm. The Artifactory installation will use the AWS services
1. RDS (PostgreSQL) as the database
2. S3 as the object storage
3. EKS as the Kubernetes cluster running Artifactory

The [main.tf](main.tf) file has the configuration that Terraform will use to setup the AWS services and install Artifactory with Helm.

The [artifactory-values.yaml](artifactory-values.yaml) file has the values that Helm will use to configure the Artifactory installation.

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

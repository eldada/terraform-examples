# Nginx In Kubernetes Example
The work here assumes you have a Kubernetes cluster with `kubectl` installed and configured to this cluster.

The [main.tf](main.tf) file has the configuration that Terraform will use to create the Nginx in the Kubernetes cluster.

This example also has a commented out snippet of using Artifactory as the [Terraform backend](https://jfrog.com/help/r/jfrog-artifactory-documentation/terraform-backend-repository).

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

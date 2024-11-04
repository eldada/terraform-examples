# Nginx In Kubernetes Example
The work here assumes you have a Kubernetes cluster with `kubectl` installed and configured to this cluster.

The [main.tf](main.tf) file has the configuration that Terraform will use to create the Nginx in the Kubernetes cluster.

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

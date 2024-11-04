### Artifactory Installation with Helm Example
Using the [Terraform Helm Provider](https://developer.hashicorp.com/terraform/tutorials/kubernetes/helm-provider) to install Artifactory in Kubernetes.

The [main.tf](main.tf) file has the configuration that Terraform will use to install Artifactory with Helm.

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

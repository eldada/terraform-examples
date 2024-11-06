### Artifactory Installation with Helm Example
Using the [Terraform Helm Provider](https://developer.hashicorp.com/terraform/tutorials/kubernetes/helm-provider) to install Artifactory in Kubernetes.

The [main.tf](main.tf) file has the configuration that Terraform will use to install Artifactory with Helm.

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

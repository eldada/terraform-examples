# Artifactory Installation with Helm Example
Using the [Terraform Helm Provider](https://developer.hashicorp.com/terraform/tutorials/kubernetes/helm-provider) to install Artifactory in Kubernetes.

The [main.tf](main.tf) file has the configuration that Terraform will use to install Artifactory with Helm.

## Prepare the Artifactory Configurations

The [artifactory-values.yaml](artifactory-values.yaml) file has the values that Helm will use to configure the Artifactory installation.

The [artifactory-license-template.yaml](artifactory-license-template.yaml) file has the license key(s) template that you will need to copy to a `artifactory-license.yaml` file.
```shell
cp artifactory-license-template.yaml artifactory-license.yaml
```

If you plan on skipping the license key(s) for now, you can leave the `artifactory-license.yaml` file empty.

## Terraform
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

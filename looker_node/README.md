# Description

This is a packer builder and custom provisioner to create an AMI for Looker.

What does this AMI contain?

* It's based off the latest Amazon Linux 2 AMI
* Includes Chromium dependency
* Uses Amazon Corretto version 8 of Java
* Includes PhantomJS dependency
* Looker suggested sysctl changes
* Instance logging to Cloudwatch Logs
* Alert Logic Threat Manager - you'll have to pay AlertLogic to use it.
* Data Dog Agent -  - you'll have to pay DataDog to use it.
* Looker suggested limits changes
* Looker created systemd startup files
* JMX changes to make easy modifications in terraform(passwords)


## Builder

The builder phase uses a t2 medium of the Ubuntu 16.04 or the Amazon Linux AMI in the east region as the instance type to run the provisioner on.  The instance size can be changed to something larger if you need to create the AMI faster.  This is just for building the AMI and has no bearing on the long running instance.  That is determined in the terraform script.

## Provisioner

The provisioner phase installs all the Looker components.  If you take a look at the provision.sh script you can see all that's happening.

## Process

Once the provisioner has completed, an AMI will be created using the ami_name in the awslnux.json file.

Here's the command line needed to build the Amazon Linux AMI.

```bash
packer build
-var 'tag_application=<>'
-var 'tag_contact_email=<>'
-var 'tag_customer=<>'
-var 'tag_team=<>'
-var 'tag_environment=<>'
-var 'vpcid_to_build_in=<>'
-var 'subnetid_to_build_in=<>'
-var 'looker_license_key=<>'
-var 'looker_license_email=<>'
-var 'looker_version=<>'
-var 'datadog_api_key=<>'
awslinux.json
```

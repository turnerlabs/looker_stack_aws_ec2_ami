# What is this?

**Currently supported version of Looker: this is configurable via the looker_version variable in the looker_node packer code**
**AMI Base: Amazon Linux 2**

This contains the [packer](https://packer.io/) code to create 3 AMI's for Looker:

* A Bastion instance.
* The Looker Node instance.

The [looker_bastion](https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/looker_bastion/README.md) path contains the code to generate the bastion server.

The [looker_node](https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/looker_node/README.md) path contains the code to generate the looker node instance.

If you need to migrate a new version of Looker, check [here](https://github.com/turnerlabs/looker_stack_aws_ec2_tf) for detailed steps.

# What is this?

**Currently supported version of Looker: this is configurable via the looker_version variable in the looker_node packer code**
**AMI Base: Amazon Linux 2**

This contains the [packer](https://packer.io/) code to create 3 AMI's for Looker:

* The Bastion instance - provides access to looker nodes when needed.
* The Looker Node instance - provides Looker website / product.
* The EFS Backup instance - provides nightly backups of EFS.

The [looker_bastion](https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/looker_bastion) path contains the code to generate the bastion server.

The [looker_node](https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/looker_node) path contains the code to generate the looker node instance.

The [looker_backup](https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/looker_backup) path contains the code to generate the looker backup instance.

The [migrating_new_versions](https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/migrating_new_versions) path describes how you would migrate new versions of Looker in an pre existing environment using this stack [here](https://github.com/turnerlabs/looker_stack_aws_ec2_tf).

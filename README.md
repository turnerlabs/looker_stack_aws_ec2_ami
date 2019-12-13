# What is this?

**Currently supported version of Looker: this is configurable via the looker_version variable in the looker_node packer code**
**AMI Base: Amazon Linux 2**

This contains the packer code to create 3 AMI's for Looker:

* A Bastion instance.
* The Looker Node instance.

The looker_bastion path contains the code to generate the bastion server.

The looker_node path contains the code to generate the looker node instance.

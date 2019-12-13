# What is this?

**Currently supported version of Looker: <this is configurable>**
**AMI Base: Amazon Linux 2**

This contains the packer code to create the 3 AMI's for Looker:
  * A Bastion instance.
  * The Looker Node instance.
  * A Backup instance.(to allow backing up of EFS)

The looker_bastion path contains the code to generate the bastion server.

The looker_node path contains the code to generate the looker node instance.

The looker_backup path contains the code to generate the backup instance.

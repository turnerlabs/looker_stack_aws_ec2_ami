# How do I migrate a new Looker Node AMI?

There are several steps required to migrate a new version of Looker.

## Assumptions

* You have run samlkeygen(or used an alternative method) to generate secret / access keys for the account.
* You have git cloned the looker ami repo(git clone git@github.com:turnerlabs/looker_stack_aws_ec2_ami.git).
* You have followed the instructions here(https://github.com/turnerlabs/looker_stack_aws_ec2_ami/blob/master/looker_node/README.md) to succesfully create a new Looker Node AMI.
* You've already installed python and have pip installed the awscli.

## Updating

1. Display the current Looker AMI's in your AWS account to verify you see the AMI's in you created.
`aws ec2 describe-images
--filters "Name=tag:application,Values=looker*"`

2. If you don't see the AMI you just created in the list, you may need to go back to the AWS account you created the AMI in and share the AMI with the account your stack is runing in.  You can do this with the following aws cli command.
`aws ec2 modify-image-attribute
--image-id <your looker node ami>
--launch-permission "Add=[{UserId=<aws account id you need to share the ami to}]"`

3. Display the currently running Looker node's launch configuration.
`aws autoscaling describe-launch-configurations
--launch-configuration-names <current looker launch config name>`

4. Create a new Looker launch config with the new Looker Node AMI
`aws autoscaling create-launch-configuration
--launch-configuration-name <new looker launch config name>
--image-id <your looker node ami>
--key-name <pem key for ec2 access>
--security-groups <security group to use for looker>
--user-data file:////<your user data file. Look at the user-data.sh example in directory> 
--instance-type <aws instance type>
--instance-monitoring Enabled=true
--iam-instance-profile <looker instance profile>
--no-ebs-optimized
--block-device-mappings "[{\"DeviceName\": \"/dev/xvda\",\"Ebs\":{\"VolumeSize\":8,\"VolumeType\": \"gp2\", \"DeleteOnTermination\": true}}]"`

5. Update the Looker Auto Scale Group to use the new Looker launch config and set the number of instances running to zero.
`aws autoscaling update-auto-scaling-group
--auto-scaling-group-name <current looker auto scale group name>
--launch-configuration-name <new looker launch config name>
--min-size 0
--desired-capacity 0
--max-size 1`

6. Query Looker Auto Scale Group for instances that are still active(this may take a while since it has to wait for all connections to drain and release)
`aws autoscaling describe-auto-scaling-groups
--auto-scaling-group-name <current looker auto scale group name> | grep InstanceId`

7. Once you receive no results back from the above command, continue.

8. Update the Looker Auto Scale Group to be 1 or 3 as min size(1 in dev, 3 in prod), 1 or 3 as desired size and 5(or more) as max-size.
`aws autoscaling update-auto-scaling-group
--auto-scaling-group-name  <current looker auto scale group name>
--min-size 1
--desired-capacity 1
--max-size 5`

9. Query Looker Auto Scale Group again for instances that are active.
`aws autoscaling describe-auto-scaling-groups
--auto-scaling-group-name <current looker auto scale group name> | grep InstanceId`

10. Once you receive results back from the above command, continue.

11. Query the Looker Auto Scale Groups for the load balancers target group.
`aws autoscaling describe-load-balancer-target-groups
--auto-scaling-group-name <current looker auto scale group name>`

12. Using the ARN returned from step 11, query the health of the Looker Target Group.
`aws elbv2 describe-target-health
--target-group-arn arn:aws:elasticloadbalancing:<your region>:<your aws account number>:targetgroup/<your target group name>/<your target group id> | grep State`

13. Once you see a state of Healthy, you should be ready to test and verify Looker.





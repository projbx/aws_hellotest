# Description

This is a solution for DevOps test task:
> You should provision an environment on AWS and run a docker container using the docker image located on DockerHub and available by the following link: https://hub.docker.com/r/nginxdemos/nginx-hello
> Here are steps that you should do:
> * Create a VPC with public subnet
> * Create an AutoScaling Group (ASG) of the minimum size. It should manage an EC2 instance based on any Linux you like
> * Create an AWS Application Load Balancer (ALB) and tie it with ASG that you have created at the previous stage
> * EC2 instance used in ASG should be provisioned with the help of the following stages:
> * Installation of Docker Engine using any package managers
> * Download a docker-compose file from a remote repository
> * Launch a docker container from the aforementioned docker image
> * Make sure a simple web page provided by Nginx web server is available through ALB

# How solution works?

1. Packer part. Create new ami-image based on existing Ubuntu image (add Docker Engine + run needed docker image at startup). 
1. Terraform part. Preparing the environment on AWS as described in the task.

This solution looks optimal in this case (with this environment on AWS and task description).
All EC2 instances will be created using the new ami-image from step 1. 
This will ensure that each created (or recreated after some troubles) EC2 instane in AutoScaling Group works correctly.

# Usage

1. Download source folder
1. Go to downloaded folder
1. Configure AWS credentials and other variables in config.json
1. Run: chmod +x runme.sh
1. Execute: ./runme.sh

After runme.sh is finished, you will see created link (with load balancer dns name), something like this:
Please vizit http://loadbal4test-775833227799.us-east-2.elb.amazonaws.com

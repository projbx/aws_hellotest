#!/bin/sh -e

if [ ! -f "terraform" ]
then
  wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip
  unzip terraform_0.13.5_linux_amd64.zip
  rm -f terraform_0.13.5_linux_amd64.zip
fi

if [ ! -f "packer" ]
then
  wget https://releases.hashicorp.com/packer/1.6.5/packer_1.6.5_linux_amd64.zip
  unzip packer_1.6.5_linux_amd64.zip
  rm -f packer_1.6.5_linux_amd64.zip
fi

./packer build -var-file=config.json pckr.json

ami_id=$(cat manifest.json | grep "artifact_id" | awk -F ":" '{print $3}' |  awk -F "\"" '{print $1}')
echo $ami_id

./terraform init
./terraform plan -var="image_id=$ami_id" -var-file=config.json -out tform_plan
./terraform apply -var="image_id=$ami_id" -var-file=config.json -auto-approve

echo ""
echo "Complete!"
echo ""
loadbalancer_dnsname=$(./terraform output lb_dns)
echo "Please vizit http://$loadbalancer_dnsname"
echo ""
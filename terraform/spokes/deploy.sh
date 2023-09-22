#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "No arguments supplied"
    echo "Usage: deploy.sh <environment>"
    echo "Example: deploy.sh dev"
    exit 1
fi
env=$1
backend-config-bucket=$2
backend-config-region=$3
echo "Deploying $env with "workspaces/${env}.tfvars" ..."

set -x

terraform workspace new $env
terraform workspace select $env
terraform init
terraform init --backend-config="bucket=${backend-config-bucket}" \
--backend-config="key=${env}/terraform.tfstate" \
--backend-config="region=${backend-config-region}"
terraform apply -var-file="workspaces/${env}.tfvars"

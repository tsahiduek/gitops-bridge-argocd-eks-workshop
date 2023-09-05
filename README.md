# GitOps Bridge EKS Workshop

This workshop covers the following use cases

1. Deploy hub-spoke clusters (hub, staging, prod)
2. Deploy watch app store application on each environment cluster
3. Use ACK to deploy DB for app store application


## Deploy

Deploy the Hub Cluster
```shell
cd hub
terraform init
terraform apply
```

Access Terraform output for Hub Cluster
```shell
cd hub
terraform output
```

Setup `kubectl` and `argocd` for Hub Cluster
```shell
cd hub
export KUBECONFIG="/tmp/hub-cluster"
export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
aws eks --region us-west-2 update-kubeconfig --name hub-cluster
kubectl config set-context --current --namespace argocd
argocd login --port-forward --username admin --password $(argocd admin initial-password | head -1)
echo "ArgoCD URL: https://$(kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
```

Open a new Terminal and Deploy Staging Cluster
```shell
cd spokes
./deploy.sh staging
```

Setup `kubectl` for Staging Cluster
```shell
cd spokes
export KUBECONFIG="/tmp/spoke-staging"
export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
aws eks --region us-west-2 update-kubeconfig --name spoke-staging
```

Open a new Terminal and Deploy Staging Cluster
```shell
cd spokes
./deploy.sh prod
```

Setup `kubectl` for Staging Cluster
```shell
cd spokes
export KUBECONFIG="/tmp/spoke-prod"
export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
aws eks --region us-west-2 update-kubeconfig --name spoke-prod
```


Each environment uses a Terraform workspace

Access Terraform output for each environment
```shell
cd spokes
terraform workspace select ${env}
terraform output
```


## Clean

Destroy Spoke Clusters
```shell
cd spokes
./destroy.sh staging
./destroy.sh prod
```

Destroy Hub Clusters
```shell
cd hub
./destroy.sh
```

# GitOps Bridge EKS Workshop

This workshop covers the following use cases

1. Deploy hub-spoke clusters (hub, staging, prod)
1. Deploy namespaces and argocd project
1. Deploy watch app store application on each environment cluster



## Deploy Hub Cluster
Deploy the Hub Cluster
```shell
cd hub
terraform init
terraform apply
```

Access Terraform output for Hub Cluster
```shell
terraform output
```

Setup `kubectl` and `argocd` for Hub Cluster
```shell
export KUBECONFIG="/tmp/hub-cluster"
export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
aws eks --region us-west-2 update-kubeconfig --name hub-cluster
kubectl config set-context --current --namespace argocd
argocd login --port-forward --username admin --password $(argocd admin initial-password | head -1)
echo "ArgoCD URL: https://$(kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
```

## Deploy Staging Cluster

Open a new Terminal and Deploy Staging Cluster
```shell
cd spokes
./deploy.sh staging
```

Setup `kubectl` for Staging Cluster
```shell
export KUBECONFIG="/tmp/spoke-staging"
export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
aws eks --region us-west-2 update-kubeconfig --name spoke-staging
```

## Deploy Prod Cluster

Open a new Terminal and Deploy Production Cluster
```shell
cd spokes
./deploy.sh prod
```

Setup `kubectl` for Production Cluster
```shell
export KUBECONFIG="/tmp/spoke-prod"
export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
aws eks --region us-west-2 update-kubeconfig --name spoke-prod
```


Each environment uses a Terraform workspace

Access Terraform output for each environment, env is "staging" or "prod" from the `spokes` directory
```shell
terraform workspace select ${env}
terraform output
```

## Deploy Cluster Addons (On the Hub Cluster run the following command)
```shell
kubectl apply -f bootstrap/addons.yaml
```

## Deploy Namespaces and Argo Project (On the Hub Cluster run the following command)
```shell
kubectl apply -f bootstrap/platform.yaml
```

## Deploy Workloads (On the Hub Cluster run the following command)
```shell
kubectl apply -f bootstrap/workloads.yaml
```


## Access UI on Staging or Production, pick the correct terminal
```shell
kubectl port-forward -n ui svc/ui 8080:80
```
Open browser on http://localhost:8080

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

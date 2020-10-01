# Run Book

## Provisioning of Infra on GCP
Step 1 : First provision the infra on GCP using terraform for the cd to directory terraform-gke-private-tiler

```
cd terraform-gke-private-tiler
```

Step 2 : Use terraform command to deploy infra on GCP, validate first.

```
terrafom init
terraform validate
terraform plan
terraform apply
```

Note :- This terrafom modules includes following infra (wasn't able to complete it fully because of time contraint)

Includes : Modules for GKE Cluster, VPC-Network, GKE Service Account, CodeBuild GCR.

To-do : Deployment of Tiler on Kubernetes.

It will also Build the Application(Docker File) and push the image to GCR.

After This Step The Infra is Provisoned (GKE with Tiler) and image pushed to GCR.


## Deployemmnt of Application on Kubernetes using helm(Not needed if added in terraform)
Now we just need Deploy Our App using Helm and expose it Follow Below Steps.

Step 1 : Change Directory to charts and run helm install command to deploy.(we can also do this using terraform)
RELEASE-NAME is a placeholder, so please replace it

```
cd ../charts
helm install RELEASE-NAME
```

Note :- Make sure that you have access to cluster and have kubectl and helm installed.

Step 2 : Verify the Deployemnt using kubectl command.

```
kubectl get deployemnts
```

## Exposing the Service to outside world(Not needed if added in terraform)

After Deployment of App now let's expose it to outside world we can can also achive this by making the service type LoadBalancer

```
kubectl expose deployment <deployemnt-name> --type=LoadBalancer --port 80 --target-port 80
```

After this get the service using kubectl command and open the loadbalancer url in browser

```
kubectl get services -w
```

* Because of limited Bnadwidth wasn't able to add the Istio Functionality.
# Terraform

### Initialize

`terraform init`

`terraform validate`

`terraform plan -out=tfplan`

`terraform apply tfplan`

### Cleaning up

`terraform destroy`

# Kubectl

### Initialize

`aws eks update-kubeconfig --region eu-central-1 --name ma-cluster`

`kubectl apply -f deployment.yaml`

`kubectl apply -f service.yaml`

### Info

`kubectl get nodes`

`kubectl get pods`

`kubectl get svc fastify-docker-service`

### Logging

`kubectl describe svc fastify-docker-service`

### Cleaning up

`kubectl delete deployment fastify-docker-deployment -n default`

`kubectl delete service fastify-docker-service -n default`

# Kubernetes Cluster
Terraform configuration to bring up a kubernetes cluster on Brightbox Cloud

1. Clone the repository
2. Create a `terraform.tfvars` file setting the required variables. (You can skip this step).
```
username = "fred@example.com"
account = "acc-xxxxx"
password = "mypassword"
bastion = "public.srv-testy.gb1.brightbox.com"
```
3. Run `terraform apply`
4. Copy `examples/app2.yml` to the created server
5. Log onto the server and put the file in the manifests directory to create an http reflector container on port 8080
```
cp app2.yml /etc/kubernetes/manifests
```
6. kubelet will create the containers and they will appear in the process listing.
7. Containers are viewed with `crictl`. `ctictl ps` shows the containers, `crictl pods` shows the pods.
8. Run `crictl inspectp <pod id>| more` to find the IPv6 address of the pod.
9. From another cloud server run `curl -g [ipv6 address]:8080`

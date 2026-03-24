
Mission statement: Collect evidence fragme4nts for later inclusion in docs (not screenshots - thoise are pasted directly in evidence-dir)


# intro:


## goal / vorgehensweise and reason / value
In step 03, we iplement a valid  CI/CD baseline (with githiub hosted runne4rs) whcih proves real DevOps value: 

GitHub Actions workflow design
build/push automation
Kubernetes deployment automation
environment separation (dev / prod)
approval-gated production flow
reproducible deploy smoke tests in a clean cluster

workflow design in GitHub Actions
overlay validation
image build/push to GHCR
Kubernetes deployment smoke tests
dev/prod environment separation
manual prod approval

Step 03 proves uiseful insights from a DevOps Perspective:

pipeline mechanics
deployment automation
Kubernetes deploy reproducibility
environment modeling
approval flow

Those are real DevOps skills.


### Why not just move directly to Proxmox now?

Because right now that would mix too many variables at once:

new infrastructure target
new cluster
networking
firewall / ingress / DNS concerns
CI/CD logic

A pro often avoids stacking too many unknowns at once.

A clean professional move is:

first validate the pipeline + deploy mechanics in a clean CI Kubernetes target
then retarget the same deploy path to the real environment

That is exactly what kind is good for: testing and CI


### One honest limitation

This workflow proves delivery mechanics very well.

It does not yet prove:

that one of the main Sock Shop runtime services is rebuilt from local source and then deployed

because this repo’s obvious repo-owned build surfaces are still openapi and healthcheck, while the deployed main stack still references upstream images. That is a limitation — but it does not make Phase 03 meaningless. It just means this is a strong CI/CD baseline, not the final strongest possible variant.

It does not yet prove that one of the main Sock Shop runtime services is rebuilt from local source and deployed, because the repo’s obvious buildable surfaces are still openapi and healthcheck, while the app stack overlays still use the upstream runtime images. That is okay for now; this is still a strong CI/CD baseline.


---

# 1. manual dev deploy baseline

## Namespaces

$ kubectl create namespace sock-shop-dev 
namespace/sock-shop-dev created

$ kubectl create namespace sock-shop-prod
namespace/sock-shop-prod created

$ kubectl get ns s
ock-shop-dev sock-shop-prod
NAME             STATUS   AGE
sock-shop-dev    Active   38s
sock-shop-prod   Active   31s

$ kubectl get ns 
NAME                                 STATUS   AGE
datascientest                        Active   35d
default                              Active   38d
dev                                  Active   15d
fastapi-gitlab-dev                   Active   11d
fastapi-gitlab-prod                  Active   11d
fastapi-gitlab-qa                    Active   11d
fastapi-gitlab-staging               Active   11d
gitlab-agent-datascientest-cluster   Active   12d
kube-node-lease                      Active   38d
kube-public                          Active   38d
kube-system                          Active   38d
prod                                 Active   12d
sock-shop                            Active   14d
sock-shop-dev                        Active   68s
sock-shop-prod                       Active   61s
staging                              Active   12d
 


 ## patch /   kustomize

create fkustomoize yaml + folder in deploy/manifests


 ##  apply kustomize dev




## evicence - poroof of successfuil rollaout

 mayinx@mayinx-IdeaPad-3-17ABA7:~/PROJECTS/DataScientest/CAPSTONE/k8s-ecommerce-microservices-app (feat/ci-github-actions-dev-prod-gate)$ kubectl get pods -n sock-shop-dev -o wide
NAME                            READY   STATUS    RESTARTS      AGE   IP            NODE                      NOMINATED NODE   READINESS GATES
carts-5f5859c84b-2hdbz          1/1     Running   1 (20m ago)   37m   10.42.0.193   mayinx-ideapad-3-17aba7   <none>           <none>
carts-db-544c5bc9c8-r5v5m       1/1     Running   1 (20m ago)   37m   10.42.0.180   mayinx-ideapad-3-17aba7   <none>           <none>
catalogue-cd4ff8c9f-q2qqw       1/1     Running   1 (20m ago)   37m   10.42.0.198   mayinx-ideapad-3-17aba7   <none>           <none>
catalogue-db-74885c6d4c-7tqwm   1/1     Running   1 (20m ago)   37m   10.42.0.183   mayinx-ideapad-3-17aba7   <none>           <none>
front-end-7467866c7b-b5679      1/1     Running   1 (20m ago)   37m   10.42.0.187   mayinx-ideapad-3-17aba7   <none>           <none>
orders-6b8dd47986-jsggf         1/1     Running   1 (20m ago)   37m   10.42.0.156   mayinx-ideapad-3-17aba7   <none>           <none>
orders-db-5d7db99c6-qpmjm       1/1     Running   1 (20m ago)   37m   10.42.0.199   mayinx-ideapad-3-17aba7   <none>           <none>
payment-c5fbdbc6-4hbns          1/1     Running   1 (20m ago)   37m   10.42.0.181   mayinx-ideapad-3-17aba7   <none>           <none>
queue-master-7f965677fb-nnc8h   1/1     Running   1 (20m ago)   37m   10.42.0.184   mayinx-ideapad-3-17aba7   <none>           <none>
rabbitmq-59955f8bff-srpdf       2/2     Running   2 (20m ago)   37m   10.42.0.185   mayinx-ideapad-3-17aba7   <none>           <none>
session-db-5d89f4b5bb-87q9v     1/1     Running   1 (20m ago)   37m   10.42.0.195   mayinx-ideapad-3-17aba7   <none>           <none>
shipping-868cd6587d-2slxh       1/1     Running   2             37m   10.42.0.157   mayinx-ideapad-3-17aba7   <none>           <none>
user-67488ff854-pcn6q           1/1     Running   1 (20m ago)   37m   10.42.0.191   mayinx-ideapad-3-17aba7   <none>           <none>
user-db-7bd86cdcd-l8fmd         1/1     Running   1 (20m ago)   37m   10.42.0.161   mayinx-ideapad-3-17aba7   <none>           <none>
mayinx@mayinx-IdeaPad-3-17ABA7:~/PROJECTS/DataScientest/CAPSTONE/k8s-ecommerce-microservices-app (feat/ci-github-actions-dev-prod-gate)$ kubectl get svc -n sock-shop-d
ev -o wide
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
carts          ClusterIP   10.43.132.247   <none>        80/TCP              38m   name=carts
carts-db       ClusterIP   10.43.105.82    <none>        27017/TCP           38m   name=carts-db
catalogue      ClusterIP   10.43.226.142   <none>        80/TCP              38m   name=catalogue
catalogue-db   ClusterIP   10.43.179.222   <none>        3306/TCP            38m   name=catalogue-db
front-end      ClusterIP   10.43.185.13    <none>        80/TCP              38m   name=front-end
orders         ClusterIP   10.43.126.21    <none>        80/TCP              38m   name=orders
orders-db      ClusterIP   10.43.128.131   <none>        27017/TCP           38m   name=orders-db
payment        ClusterIP   10.43.33.60     <none>        80/TCP              38m   name=payment
queue-master   ClusterIP   10.43.171.235   <none>        80/TCP              38m   name=queue-master
rabbitmq       ClusterIP   10.43.232.43    <none>        5672/TCP,9090/TCP   38m   name=rabbitmq
session-db     ClusterIP   10.43.86.48     <none>        6379/TCP            38m   name=session-db
shipping       ClusterIP   10.43.158.252   <none>        80/TCP              38m   name=shipping
user           ClusterIP   10.43.54.212    <none>        80/TCP              38m   name=user
user-db        ClusterIP   10.43.219.160   <none>        27017/TCP           38m   name=user-db
mayinx@mayinx-IdeaPad-3-17ABA7:~/PROJECTS/DataScientest/CAPSTONE/k8s-ecommerce-microservices-app (feat/ci-github-actions-dev-prod-gate)$ kubectl get deploy -n sock-sho
p-dev -o wide
NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                   IMAGES                                               SELECTOR
carts          1/1     1            1           38m   carts                        weaveworksdemos/carts:0.4.8                          name=carts
carts-db       1/1     1            1           38m   carts-db                     mongo                                                name=carts-db
catalogue      1/1     1            1           38m   catalogue                    weaveworksdemos/catalogue:0.3.5                      name=catalogue
catalogue-db   1/1     1            1           38m   catalogue-db                 weaveworksdemos/catalogue-db:0.3.0                   name=catalogue-db
front-end      1/1     1            1           38m   front-end                    weaveworksdemos/front-end:0.3.12                     name=front-end
orders         1/1     1            1           38m   orders                       weaveworksdemos/orders:0.4.7                         name=orders
orders-db      1/1     1            1           38m   orders-db                    mongo                                                name=orders-db
payment        1/1     1            1           38m   payment                      weaveworksdemos/payment:0.4.3                        name=payment
queue-master   1/1     1            1           38m   queue-master                 weaveworksdemos/queue-master:0.3.1                   name=queue-master
rabbitmq       1/1     1            1           38m   rabbitmq,rabbitmq-exporter   rabbitmq:3.6.8-management,kbudde/rabbitmq-exporter   name=rabbitmq
session-db     1/1     1            1           38m   session-db                   redis:alpine                                         name=session-db
shipping       1/1     1            1           38m   shipping                     weaveworksdemos/shipping:0.4.8                       name=shipping
user           1/1     1            1           38m   user                         weaveworksdemos/user:0.4.7                           name=user
user-db        1/1     1            1           38m   user-db                      weaveworksdemos/user-db:0.3.0                        name=user-db



2. Actual GitHub Actions delivery path

## Preprerations 

### Create cusotm workflow file in .github/workflows 
phase-03-delivery.yaml


### create namespaces dev + prod on github 
... and configure required reviewers on prod (1 - myslef). Jobs that reference an environment with required reviewers will wait for approval before starting.



 GitHub UI prep — Environments

Go to:

Repo
Settings
Environments
New environment

Create:

dev
name: dev
leave defaults
prod
name: prod
enable Required reviewers
add yourself
leave Prevent self-review off
save


### Create + add a GitHub self-hosted runner on teh lcoal machine   




kind is explicitly designed for local development or CI and runs Kubernetes clusters in Docker-based nodes






Intro: We gonna use:
- github-hosted runenrs / CI  - benefit: GitHub-hosted runners run each job in a fresh instance - and self hosted runenrs are too dangerous in a publci repo (thatÄs we don't run teh pipeline against aour local k3s cluster, whcih woudl havbe been an option, but oinly via a self-hosted runenr in combinaioinw th a publci repo whcih is a no-no) - GitHub says each GitHub-hosted job gets a new VM, and that VM is automatically decommissioned when the job finishes. That is exactly why this approach is cleaner and safer for your public fork.
- kind is explicitly designed for local development or CI and runs Kubernetes clusters in Docker-based nodes / That is exactly what kind is good for: testing and CI
- That means every deployment smoke test starts from a cleaner state than your laptop cluster.
- For deployment validation, this is actually very strong.
- and we are preparing ourselves for proxmox already


Logic:

- we make repo private temporarily
- use GitHub-hosted for build/test/push
- use self-hosted for deploy
- keep local k3s namespaces as temporary dev/prod targets
- later switch deploy target to Proxmox

That is the best balance of:

speed
professionalism
security
future portability


We implement a self-hosted runner on teh lcoal machine, because the deploy jobs need to reach our local k3s cluster as deploy targets for dev + prod,, and GitHub-hosted runners cannot magically deploy into your laptop cluster. GitHub documents repository-level self-hosted runner setup under Settings → Actions → Runners → New self-hosted runner.

Once it is installed, I recommend adding a custom label like:

k3s-local

so the deploy jobs can target it cleanly.
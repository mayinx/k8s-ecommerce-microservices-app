
Mission statement: Collect evidence fragme4nts for later inclusion in docs (not screenshots - thoise are pasted directly in evidence-dir)


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
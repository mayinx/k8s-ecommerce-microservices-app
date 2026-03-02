# 🧭 Runbook (TL;DR)

> ## 👤 About
> This runbook is the **short, command-first** version of the Phase 00 baseline setup and verification flow.  
> It’s meant as a quick reference for reruns without the long-form diary.  
> For the full narrative log, see: **[00-baseline/IMPLEMENTATION.md](IMPLEMENTATION.md)**.

---

## 📌 Index (top-level)
- [Repo setup](#repo-setup)
- [Start stack](#start-stack)
- [Verify router dashboard](#verify-router-dashboard)
- [Storefront check](#storefront-check)
- [Diagnose host :80 interception](#diagnose-host-80-interception)
- [Local workaround: expose storefront on :8081](#local-workaround-expose-storefront-on-8081)
- [Stop / cleanup](#stop--cleanup)

---

## Repo setup

~~~bash
git clone git@github.com:mayinx/k8s-ecommerce-microservices-app.git
cd k8s-ecommerce-microservices-app

git status
git branch -vv
git remote -v

git remote add upstream git@github.com:DataScientest/microservices-app.git
git remote set-url --push upstream no_push
git remote -v
~~~

## Start stack

~~~bash
cd deploy/docker-compose
docker compose -f docker-compose.yml up -d
docker compose ps
docker compose ps --services
~~~

## Verify router dashboard

~~~bash
curl -i http://localhost:8080/
curl -s http://localhost:8080/dashboard/ | head -n 5
~~~

## Storefront check

~~~bash
curl -I http://localhost
curl -s http://localhost | head -n 3; echo
~~~

## Diagnose host 80 interception

~~~bash
# Prove storefront works inside the compose network (router + service)
docker compose exec edge-router sh -lc 'wget -qO- http://127.0.0.1:80/ | head -n 5'
docker compose exec edge-router sh -lc 'wget -qO- http://front-end:8079/ | head -n 5'

# Show docker-proxy target for host :80 (expects edge-router container IP)
sudo ss -ltnp | grep ':80 ' # gives us docker-proxy-pid
sudo tr '\0' ' ' < /proc/<docker-proxy-pid>/cmdline; echo

# If k3s is running, host :80 may be DNAT'ed by CNI hostport rules
sudo systemctl list-units --type=service | grep -Ei 'k3s'
sudo nft list ruleset | grep -nE 'CNI-HOSTPORT|KUBE-|tcp dport 80' | head -n 80
~~~

## Local workaround: expose storefront on 8081

~~~bash
# Create local-only override file (if not present yet)
cat > deploy/docker-compose/docker-compose.local.yml <<'YAML'
services:
  edge-router:
    ports:
      - "8081:80"
      - "8080:8080"
YAML

cd deploy/docker-compose
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d

curl -s http://127.0.0.1:8081/ | head -n 3; echo
~~~

## Stop / cleanup

~~~bash
cd deploy/docker-compose

# Stop stack when started with the local override (recommended on this machine)
docker compose -f docker-compose.yml -f docker-compose.local.yml down

# Stop stack when started without the override (default upstream mode)
docker compose -f docker-compose.yml down
~~~
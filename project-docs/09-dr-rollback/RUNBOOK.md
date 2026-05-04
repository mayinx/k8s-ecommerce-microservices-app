# Runbook — Phase 09 Disaster Recovery & Rollback

> ## 👤 About
> This runbook provides the short rerun path for **Phase 09 (Disaster Recovery & Rollback)**.
>
> It covers the backup helper, backup report inspection, MongoDB dump restore validation, safe pod recovery proof, rollback commands, and the documented full-target recovery model.
>
> For the full implementation story, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For phase-local decisions, see: **[DECISIONS.md](./DECISIONS.md)**.  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## 📌 Index

- [Quick command map](#quick-command-map)
- [Preconditions](#preconditions)
- [Backup helper checks](#backup-helper-checks)
- [Backup report inspection](#backup-report-inspection)
- [MongoDB dump restore validation](#mongodb-dump-restore-validation)
- [Container recovery proof](#container-recovery-proof)
- [Rollback paths](#rollback-paths)
- [Full target recovery model](#full-target-recovery-model)
- [Recommended usage](#recommended-usage)
- [Notes](#notes)
- [Files added / modified in this phase](#files-added--modified-in-this-phase)

---

## Quick command map

| Command | What it does | Safe default? |
| :--- | :--- | :--- |
| `make p09-dr-script-syntax` | Validates Bash syntax of the Phase 09 backup helper | Yes |
| `make p09-dr-backup-dev` | Creates a timestamped DR backup for `sock-shop-dev` | Yes |
| `make p09-dr-backup-prod` | Creates a timestamped DR backup for `sock-shop-prod` | Yes, read-only backup path |
| `make p09-dr-print-report-dev` | Prints the latest dev backup report and artifact list | Yes |
| `make p09-dr-print-report-prod` | Prints the latest prod backup report and artifact list | Yes |
| `make k8s-show-live-dev-pod COMPONENT=front-end` | Shows one selected live dev pod by `name=<component>` | Yes |
| `make k8s-delete-live-dev-pod COMPONENT=front-end` | Deletes one selected live dev pod to prove Deployment recovery | Dev only |
| `make p07-tests-live` | Runs the live Python contract smoke and Playwright browser smoke checks | Yes |

---

## Preconditions

- The Proxmox-backed K3s target cluster is reachable from the workstation.
- The kubeconfig path exists locally:

~~~bash
$HOME/.kube/config-proxmox-dev.yaml
~~~

- The namespaces exist on the target cluster:

~~~text
sock-shop-dev
sock-shop-prod
~~~

- Docker is available locally for the temporary MongoDB restore-check container.
- Phase 07 live smoke targets are available for post-recovery validation.

---

## Backup helper checks

Run the syntax check before using the backup helper:

~~~bash
make p09-dr-script-syntax
~~~

Create a dev backup:

~~~bash
make p09-dr-backup-dev
~~~

Create a prod backup:

~~~bash
make p09-dr-backup-prod
~~~

The backup helper writes timestamped local backup folders under:

~~~text
backups/
~~~

Generated backup artifacts are intentionally excluded from Git.

---

## Backup report inspection

Inspect the latest dev backup package:

~~~bash
make p09-dr-print-report-dev
~~~

Inspect the latest prod backup package:

~~~bash
make p09-dr-print-report-prod
~~~

Expected artifact shape after a successful namespace backup:

~~~text
.
└── backups
    └── <namespace>_<timestamp>
        ├── db
        │   ├── backup-report.txt
        │   ├── carts-db_<generated-carts-db-pod-name>.archive.gz
        │   ├── orders-db_<generated-orders-db-pod-name>.archive.gz
        │   └── user-db_<generated-user-db-pod-name>.archive.gz
        ├── k8s
        │   ├── all-resources-wide.txt
        │   ├── configmaps.yaml
        │   ├── deployments.yaml
        │   ├── ingress.yaml
        │   ├── namespace.yaml
        │   ├── persistent-volumes-wide.txt
        │   ├── pods.yaml
        │   ├── pvc.yaml
        │   ├── secrets-metadata.txt
        │   └── services.yaml
        └── README.txt
~~~

Expected database-report behavior:

- `carts-db`, `orders-db`, and `user-db` should produce MongoDB archive dumps where `mongodump` is available.
- `catalogue-db` and `session-db` can be skipped without failing the whole backup run.
- Skipped database targets must be visible in `backup-report.txt`.

---

## MongoDB dump restore validation

Use this path to validate one representative `user-db` dump in a disposable local MongoDB container.

This does not restore anything into `sock-shop-dev` or `sock-shop-prod`.

~~~bash
# Pick the latest local dev backup folder.
latest_backup="$(find backups -maxdepth 1 -type d -name 'sock-shop-dev_*' | sort | tail -n 1)"

# Select the latest user-db dump archive from that backup.
USER_DUMP="$(find "$latest_backup/db" -maxdepth 1 -type f -name 'user-db_*.archive.gz' | sort | tail -n 1)"

# Show the selected archive.
echo "$USER_DUMP"

# Start from a clean restore-check container name.
RESTORE_CHECK_CONTAINER="p09-mongo-restore-check"
docker rm -f "$RESTORE_CHECK_CONTAINER" >/dev/null 2>&1 || true

# Start a temporary local MongoDB container.
docker run --rm -d --name "$RESTORE_CHECK_CONTAINER" mongo:3.4

# Wait until MongoDB is ready.
docker exec "$RESTORE_CHECK_CONTAINER" sh -c 'until mongo --quiet --eval "db.adminCommand({ ping: 1 })" >/dev/null 2>&1; do sleep 1; done'

# Copy the selected archive into the temporary container.
docker cp "$USER_DUMP" "$RESTORE_CHECK_CONTAINER:/tmp/user-db.archive.gz"

# Restore the archive.
docker exec "$RESTORE_CHECK_CONTAINER" mongorestore --archive=/tmp/user-db.archive.gz --gzip

# Query restored collection counts.
docker exec "$RESTORE_CHECK_CONTAINER" mongo users --quiet --eval 'print("customers=" + db.customers.count()); print("cards=" + db.cards.count()); print("addresses=" + db.addresses.count())'

# Remove the temporary restore-check container.
docker rm -f "$RESTORE_CHECK_CONTAINER"
~~~

Expected result:

~~~text
customers=3
cards=4
addresses=4
~~~

Use the full implementation log for the longer schema comparison against the live `user-db` pod.

---

## Container recovery proof

This proof is intentionally limited to `sock-shop-dev`.

Show the current live `front-end` pod:

~~~bash
make k8s-show-live-dev-pod COMPONENT=front-end
~~~

Delete one live dev `front-end` pod:

~~~bash
make k8s-delete-live-dev-pod COMPONENT=front-end
~~~

Wait for the Deployment to become healthy again:

~~~bash
export KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml"

kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s
kubectl get pods -n sock-shop-dev -l name=front-end -o wide
~~~

Validate the application after recovery:

~~~bash
make p07-tests-live
~~~

Expected result:

- A new `front-end` pod is created with a different pod name.
- The replacement pod reaches `Running` and `READY 1/1`.
- The Phase 07 live validation bundle passes.

---

## Rollback paths

### Normal rollback path

Use Git revert as the normal rollback path for a bad application change:

~~~bash
git revert <bad_commit_sha>
git push
~~~

Then use the normal protected pull request and deployment path.

### Emergency Kubernetes rollback path

Use Kubernetes rollout rollback only as an emergency runtime rollback for a Deployment revision.

Inspect rollout history first:

~~~bash
export KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml"

kubectl rollout history deployment/front-end -n sock-shop-dev
~~~

Emergency rollback command:

~~~bash
kubectl rollout undo deployment/front-end -n sock-shop-dev
~~~

Validate after rollback:

~~~bash
kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s
make p07-tests-live
~~~

If the Deployment has only one recorded revision, there is no older revision to roll back to.

---

## Full target recovery model

The current target is a single-node K3s platform on a Proxmox VM. It does not provide automatic node failover.

For full target VM or node loss, the recovery model is:

1. Recreate the Proxmox VM foundation from the Phase 04 VM-template baseline.
2. Recreate or replace the target runtime from the Phase 05 delivery model:
   - K3s
   - Tailscale private access
   - Cloudflare Tunnel public edge
   - Traefik ingress routing
3. Use the Phase 08 Terraform proof as the current IaC reference for reproducible Proxmox VM provisioning.
4. Redeploy `sock-shop-dev` and `sock-shop-prod` through the GitHub Actions/Kustomize delivery path.
5. Use Phase 09 backup artifacts to inspect previous namespace state and restore MongoDB-compatible data where applicable.
6. Validate the recovered platform:
   - Deterministic checks
   - Live Python contract smoke checks
   - Playwright storefront smoke checks
   - Relevant security scan targets
   - Observability checks in Grafana and Prometheus

---

## Recommended usage

### Before relying on the backup helper

~~~bash
make p09-dr-script-syntax
~~~

### Routine dev backup check

~~~bash
make p09-dr-backup-dev
make p09-dr-print-report-dev
~~~

### Routine prod backup check

~~~bash
make p09-dr-backup-prod
make p09-dr-print-report-prod
~~~

### Milestone restoreability check

Run the MongoDB dump restore validation against the latest dev `user-db` archive.

### Safe recovery proof

~~~bash
make k8s-show-live-dev-pod COMPONENT=front-end
make k8s-delete-live-dev-pod COMPONENT=front-end
kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s
make p07-tests-live
~~~

### After any rollback or recovery action

~~~bash
make p07-tests-live
~~~

---

## Notes

- Backup artifacts are local and gitignored.
- The backup helper records Kubernetes Secret metadata only, not Secret values.
- `catalogue-db` and `session-db` are skipped by the MongoDB dump path when `mongodump` is unavailable or not applicable.
- Redis-specific backup handling for `session-db` remains follow-up hardening scope.
- Image-specific backup handling for `catalogue-db` remains follow-up hardening scope.
- Full node/VM loss is handled through rebuild, redeploy, and restore where backup artifacts are available.

---

## Files added / modified in this phase

### Files added in this phase

- `scripts/dr/backup-k8s-namespace.sh`
- `project-docs/09-dr-rollback/IMPLEMENTATION.md`
- `project-docs/09-dr-rollback/RUNBOOK.md`
- `project-docs/09-dr-rollback/DECISIONS.md`
- `project-docs/09-dr-rollback/evidence/`

### Files modified in this phase

- `.gitignore`
- `Makefile`
- `README.md`
- `project-docs/INDEX.md`
- `project-docs/ROADMAP.md`
- `project-docs/DECISIONS.md`

### Local-only files and folders used in this phase

- `backups/`
- `$HOME/.kube/config-proxmox-dev.yaml`
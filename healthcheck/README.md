# Healthcheck Helper

## Purpose

This folder contains a small repo-owned Ruby healthcheck helper and its Docker packaging.

The helper queries one or more service `/health` endpoints, collects the reported service states, prints the resulting status map, and exits successfully only when all discovered services report `OK`.

This makes it useful as:

- a lightweight runtime verification helper
- a repo-owned support artifact in the delivery pipeline
- a realistic owned test target for unit-test coverage

---

## Files

- `healthcheck.rb`  
  Ruby CLI helper that performs the health checks.

- `Dockerfile`  
  Container packaging for the helper.

---

## Runtime behavior

The helper:

- accepts a hostname/base URL plus a comma-separated service list
- requests `/health` for each selected service
- parses the returned JSON payload
- collects the reported service states
- exits with:
  - `0` if all collected services are `OK`
  - `1` otherwise

If no services are provided, the script prints an error and exits non-zero.

---

## Build the helper image

~~~bash
docker build -t sockshop-healthcheck ./healthcheck
~~~

Notes:

- `docker build` builds a Docker image from the local `Dockerfile`
- `-t sockshop-healthcheck` assigns a local image name/tag
- `./healthcheck` is the build context directory

---

## Quick checks

### Ruby syntax check inside the image

~~~bash
docker run --rm --entrypoint ruby sockshop-healthcheck -c /healthcheck.rb
~~~

Expected result:

- `Syntax OK`

### Direct execution smoke check

~~~bash
docker run --rm sockshop-healthcheck
~~~

Expected result:

- the script prints `no services specified`
- the container exits non-zero

That is the expected baseline behavior when the mandatory `-s/--services` input is missing.

---

## Example direct usage

The exact runtime input depends on how the target health endpoints are exposed.

General shape:

~~~bash
ruby healthcheck.rb \
  --hostname http://localhost:8080 \
  --services catalogue,user,carts \
  --retry 3 \
  --delay 5
~~~

Meaning:

- `--hostname` supplies the base URL or hostname prefix
- `--services` selects the service names to check
- `--retry` defines how many rounds should be attempted
- `--delay` adds a delay before each round

---

## Why this helper matters in the project

This helper is intentionally small, but it provides several useful DevOps signals:

- it is a repo-owned runtime verification artifact
- it can be packaged and run in containers
- it has direct CI/CD relevance
- it is small enough to test properly
- it demonstrates ownership beyond pure upstream manifests

---

## Testing relevance

This helper is a strong unit-test target because it contains owned Ruby logic such as:

- option parsing
- validation of required inputs
- retry behavior
- health-state aggregation
- success/failure exit logic

The script has been structured so it can now be:

- executed directly as a CLI tool
- required from Ruby tests without auto-running the script body
# Phase 03 baseline = GitHub Actions + raw manifests + dev/prod namespaces

Steps:

- GitHub Actions
- GHCR
- self-hosted GitHub runner on your laptop for deploy jobs
- deploy to sock-shop-dev automatically
- deploy to sock-shop-prod after manual approval
- based on the already proven Kubernetes manifest path

- But: No helm (not yet) - reason:

Fragments:

- Helm exists in the repo, but it is not ready-to-use out of the box for our Phase-03 baseline path.
- Helm was evaluated during Phase 03 triage, but because it was optional and showed dependency/setup friction, the CI/CD baseline was implemented first on the already proven Kubernetes deployment path. Helm remained a later enhancement candidate.
- I evaluated Helm: 
    - I found an outdated/incomplete dependency setup
    - Helm is not required
    - I chose the already proven Kubernetes path for the baseline
    - I preserved Helm as a later enhancement candidate
- So: Helm is deferred, not rejected!


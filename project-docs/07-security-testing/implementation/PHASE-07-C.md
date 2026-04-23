# TODO: Decide subphase title:
- Implementation — Subphase 03: Security scanning baseline and CI gate preparation (Step 8 - ...) / 
- Implementation — Subphase 03: Trivy security baseline and CI gate integration (Step 8 - ...)
- ...



- Create makefile targets for that comamnd monsters trivy seems to need  

- Doc necessary make target fixes to get install to pass

- doc ist zustand before docekrfile fix

┌────────────┬────────────┬───────────────────┬─────────┐
│   Target   │    Type    │ Misconfigurations │ Secrets │
├────────────┼────────────┼───────────────────┼─────────┤
│ Dockerfile │ dockerfile │         2         │    -    │
└────────────┴────────────┴───────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


Dockerfile (dockerfile)
=======================
Tests: 20 (SUCCESSES: 18, FAILURES: 2)
Failures: 2 (HIGH: 2, CRITICAL: 0)

DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user as argument
════════════════════════════════════════
Running containers with 'root' user can lead to a container escape situation. It is a best practice to run containers as non-root users, which can be done by adding a 'USER' statement to the Dockerfile.

See https://avd.aquasec.com/misconfig/ds-0002
────────────────────────────────────────


DS-0025 (HIGH): '--no-cache' is missed: apk update &&     apk add ruby ruby-json ruby-rdoc ruby-irb
════════════════════════════════════════
You should use 'apk add' with '--no-cache' to clean package cached data and reduce image size.

See https://avd.aquasec.com/misconfig/ds-0025
────────────────────────────────────────
 Dockerfile:3-4
────────────────────────────────────────
   3 ┌ RUN apk update && \
   4 └     apk add ruby ruby-json ruby-rdoc ruby-irb
────────────────────────────────────────


make: *** [Makefile:557: p07-trivy-repo-scan] Error 1



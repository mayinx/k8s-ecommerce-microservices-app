
## [Issue XX] <Issue Title> (Phase XX/Step XX)

<Intro>

### Observed Behavior

<Descrption>

<Code Excerpt>
~~~bash
$ sudo kubectl get pods -n sock-shop
NAME                            READY   STATUS             RESTARTS
carts-db-544c5bc9c8-2jtgs       0/1     CrashLoopBackOff   10 (57s ago)
orders-db-5d7db99c6-7bmtb       0/1     CrashLoopBackOff   10 (70s ago)
~~~

### Investigation & Triage

<what was done to figure out the cause / what was inspcted>


<Code Excerpts/Comamnds>

~~~bash
$ sudo kubectl logs -n sock-shop deployment/carts-db
...
[image-entrypoint] Initializing MongoDB v7.0...
FATAL: MongoDB 5.0+ requires a CPU with AVX support.
~~~

**Diagnosis:** <summary of the cause and solution hint>

### Resolution (Hotfix)

<measures taken / code implemented / commands run to resolve the issue>

<Code Excerpts/Comamnds>

~~~bash
# Patch the carts-db + orders-db deployments to a specific MongoDB version 
$ sudo kubectl set image deployment/carts-db -n sock-shop carts-db=mongo:3.4
$ sudo kubectl set image deployment/orders-db -n sock-shop orders-db=mongo:3.4
~~~

**Result:** <Ideally success description>

### Permanent Fix & Prevention

<In case thsi was not resolevd completely / permanetöly: What can be doen / will be doen to fix teh issue permanetly - and when and how? WHat can be done to prevent it in the future>

---


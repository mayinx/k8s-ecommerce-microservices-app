# Notes Templates
Purpose:
- Reusable note styles for implementation docs, setup docs, runbooks, decisions, and related project documentation
- Acts as both a style guide and a copy-paste base 
---

## Copy-paste starter set

> [!NOTE] **🧩 [Title]**
> 
> [Explanation]


> [!TIP] **🧩 [Title]**
>
> [Implementation detail]

> [!IMPORTANT] **🧩 [Title]**
>
> [Important boundary or authority clarification]

---

> [!NOTE] **🧭 <Title>**
>
> <Rationale / trade-off / scope note>

> [!IMPORTANT] **🧭 <Title>**
>
> <Important operational separation or design decision>

---

> [!WARNING] **⚠️ <Title>**
>
> <Real pitfall or failure mode>

> [!CAUTION] **⚠️ <Title>**
>
> <Softer warning or limitation>

---


## 1) Standard concept / explanation note

Template:

> [!NOTE] **🧩 <Concept or explanation title>**
>
> <Short explanation of the concept, term, pattern, or mechanism.>

Example:

> [!NOTE] **🧩 Consumer-side contract guard**
>
> The Python schema in this phase is not treated as the authoritative upstream API specification.
> It acts as a consumer-side compatibility guard that defines the minimum response structure this project expects to remain stable.

---

## 2) Rationale / decision-direction note / Important operational/execution note

Template:

> [!NOTE] **🧭 <Rationale or scope title>**
>
> <Short explanation of the reasoning, trade-off, or boundary behind the choice.>

Example:

> [!NOTE] **🧭 Why this baseline stays intentionally narrow**
>
> Missing images or descriptions may still matter commercially or visually in a real e-commerce setting.
> The focus in this phase, however, is structural downstream compatibility: guarding the fields most likely to represent genuine technical breakage if they disappear or change incompatibly.

---

## 3) Practical implementation tip

Template:

> [!TIP] **🧩 <Implementation tip title>**
>
> <Short practical note about a useful implementation detail, shortcut, or behavior.>

Example:

> [!TIP] **🧩 Why `_VALIDATOR.iter_errors()` is used**
>
> A standard `jsonschema.validate()` call stops at the first error it encounters.
> By using `_VALIDATOR.iter_errors(payload)`, the contract guard can report multiple schema violations in one run.

---

## 4) Important boundary / authority clarification

Template:

> [!IMPORTANT] **🧩 <Important clarification title>**
>
> <Short clarification of an important boundary, ownership rule, or architectural distinction.>

Example:

> [!IMPORTANT] **🧩 Schema authority**
>
> The compatibility schema in this phase is not a second canonical source of truth for the upstream API.
> It is a project-local compatibility baseline for downstream validation.

---

## 5) Warning / caution note

Template:

> [!WARNING] **⚠️ <Warning title>**
>
> <Short warning about a real pitfall, risk, or misleading behavior.>

Example:

> [!WARNING] **⚠️ Public-edge validation is not the same as pure in-cluster validation**
>
> A contract smoke test executed through the public edge can fail because of ingress or edge-path issues even if the backing service itself is healthy.

---

## 6) Optional caution note for softer warnings


Template:

> [!CAUTION] **⚠️ <Caution title>**
>
> <Short caution about a softer but still relevant risk or limitation.>

Example:

> [!CAUTION] **⚠️ Local port-forward checks are primarily for debugging**
>
> A local port-forward path is useful for debugging, but it should not be confused with the default deployed-edge validation path.

---

---




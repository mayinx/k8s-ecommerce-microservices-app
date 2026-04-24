## Phase-specific decision entry template

#### PXX-DXX — <Short decision title>

- **Decision:** <What was decided?>
- **Why:** <Why was this the chosen approach instead of the alternatives?>
- **Proof:** <What in the implementation, validation, or evidence shows this decision was actually applied?>
- **Next-step impact:** <What does this decision enable, constrain, or prepare for in the following steps?>


## Concrete example

#### P07-D27 — Repository governance = Enable branch protection before CI status checks are enforced

- **Decision:** Enable the first branch-protection controls on `master` before wiring the Phase 07 validation targets into GitHub Actions as required status checks.
- **Why:** The local validation layer is already strong enough that direct pushes to the default branch should no longer remain unrestricted. Early branch protection reduces the risk of bypassing review and prepares the repository for the later CI-gate model. At the same time, the specific required status checks are deferred until the workflow jobs exist with stable names.
- **Proof:** The repository protection rule now requires pull requests and blocks unrestricted direct updates to `master`, while the required-check wiring is prepared for the following CI step.
- **Next-step impact:** Step 10 can attach the concrete GitHub Actions jobs as mandatory merge checks and complete the branch-governance model without restructuring the repository policy afterward.
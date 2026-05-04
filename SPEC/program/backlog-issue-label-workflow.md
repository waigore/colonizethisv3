# Backlog issue label workflow

**SPEC/program** - Label-state contract for the backlog automation chain spanning review, refinement, implementation, and verification.

## Purpose

Define one deterministic issue-label workflow so automation and humans move backlog issues through the same lifecycle without ambiguous ownership or skipped gates.

## Labels in scope

- `backlog:review`
- `backlog:refinement`
- `backlog:implementation`
- `backlog:verification`
- `backlog:clarification`
- `backlog:acceptance`

## Role ownership

- Automation-owned labels and transitions:
  - `backlog:review`
  - `backlog:refinement`
  - `backlog:implementation`
  - `backlog:verification`
- Product-owner-only labels and transitions:
  - `backlog:clarification`
  - `backlog:acceptance`

Automation must not apply, remove, or transition through product-owner-only labels.

## State machine

### Canonical transitions

- `backlog:review` -> `backlog:implementation` (review pass)
- `backlog:review` -> `backlog:refinement` (review fail)
- `backlog:refinement` -> `backlog:review` (feedback fully resolved)
- `backlog:refinement` -> `backlog:refinement` (material uncertainty remains; automation posts clarification request and waits for product-owner relabel)
- `backlog:implementation` -> `backlog:verification` (issue fully implemented)
- `backlog:verification` -> `backlog:implementation` (gaps remain)
- `backlog:verification` -> `backlog:verification` (verification complete; automation posts readiness and waits for product-owner relabel)

### Product owner handoffs (manual labels only)

- Product owner applies `backlog:clarification` when automation has posted unresolved uncertainties and product-owner clarification work is required.
- `backlog:clarification` -> `backlog:review` after product owner resolves uncertainty in issue scope, behavior, or acceptance criteria.
- Product owner applies `backlog:acceptance` after reviewing verification evidence and deciding the issue is accepted.
- `backlog:acceptance` is terminal for this workflow and indicates product-owner acceptance outcome handling is outside automation scope.

## Causal link validation against skills

The four backlog skills form a closed automation loop over quality gates:

- Review gate decides implementation readiness or refinement need.
- Refinement gate either returns to review or emits a clarification request for product-owner takeover.
- Implementation gate moves to verification only when no substantive work remains.
- Verification gate either loops back to implementation for gaps or emits an acceptance-ready handoff for product-owner relabel.

This creates an auditable cause-and-effect chain where each transition is driven by explicit evidence (review findings, unresolved feedback, remaining work, or verification gaps).

## Workflow invariants

- Exactly one state label from this spec is active on an issue at a time.
- Every transition removes the previous state label and adds exactly one destination label.
- Automation never closes issues in this state workflow.
- `backlog:verification` must not be applied when implementation work remains.
- Only the product owner may add or remove `backlog:clarification` and `backlog:acceptance`.

## Acceptance criteria

- Given an open issue labeled `backlog:review`  
  When automation performs review and unresolved `P0`, `P1`, and `P2` findings are all absent  
  Then automation removes `backlog:review`, adds `backlog:implementation`, and posts one consolidated review comment.

- Given an open issue labeled `backlog:review`  
  When automation performs review and at least one unresolved `P0`, `P1`, or `P2` finding exists  
  Then automation removes `backlog:review`, adds `backlog:refinement`, and posts one consolidated review comment listing those findings.

- Given an open issue labeled `backlog:refinement`  
  When automation applies feedback and all material uncertainties are resolved in the issue body  
  Then automation removes `backlog:refinement`, adds `backlog:review`, and persists the refined issue body.

- Given an open issue labeled `backlog:refinement`  
  When automation cannot resolve at least one material uncertainty from comments, SPEC, and code evidence  
  Then automation keeps `backlog:refinement` unchanged and posts a numbered clarification request comment for product-owner relabel to `backlog:clarification`.

- Given an open issue labeled `backlog:implementation`  
  When automation delivers only a partial implementation slice with substantive deferred work remaining  
  Then automation keeps `backlog:implementation` unchanged and does not add `backlog:verification`.

- Given an open issue labeled `backlog:implementation`  
  When automation completes implementation with targeted acceptance-criteria coverage and no substantive deferred work  
  Then automation removes `backlog:implementation` and adds `backlog:verification`.

- Given an open issue labeled `backlog:verification`  
  When automation verifies implementation and finds at least one unresolved acceptance-criteria, spec, or test gap  
  Then automation removes `backlog:verification`, adds `backlog:implementation`, and posts one consolidated verification gap comment.

- Given an open issue labeled `backlog:verification`  
  When automation verifies implementation and finds no unresolved material gaps  
  Then automation keeps `backlog:verification` unchanged and posts one consolidated verification-ready comment for product-owner relabel to `backlog:acceptance`.

- Given an open issue labeled `backlog:clarification`  
  When the product owner resolves uncertainty in issue description, scope, and acceptance criteria  
  Then the product owner removes `backlog:clarification` and adds `backlog:review` so automation can resume.

- Given an open issue labeled `backlog:acceptance`  
  When the product owner performs final product acceptance decisioning  
  Then the issue remains outside automation transition control unless the product owner explicitly re-labels it for further automation work.

- Given an open issue in any automation-owned state label  
  When an automation run reaches a point that requires clarification or acceptance decisioning  
  Then automation does not add `backlog:clarification` or `backlog:acceptance` and instead posts a handoff comment instructing product-owner manual relabel.

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

- Agent-owned relabel transitions:
  - Agent performs all label transitions in this workflow, including transitions into and out of `backlog:clarification` and `backlog:acceptance`.
- Product-owner-owned decisions:
  - `backlog:clarification`: Product owner resolves ambiguity and provides final clarification direction.
  - `backlog:acceptance`: Product owner performs final acceptance decisioning.

Automation sets lifecycle labels; product owner performs the business decision steps for clarification and acceptance.

## State machine

### Canonical transitions

- `backlog:review` -> `backlog:implementation` (review pass)
- `backlog:review` -> `backlog:refinement` (review fail)
- `backlog:refinement` -> `backlog:review` (feedback fully resolved)
- `backlog:refinement` -> `backlog:clarification` (material uncertainty remains; agent relabels to hand off clarification work)
- `backlog:implementation` -> `backlog:verification` (issue fully implemented)
- `backlog:verification` -> `backlog:implementation` (gaps remain)
- `backlog:verification` -> `backlog:acceptance` (verification complete; agent relabels for product-owner final acceptance decision)

### Product owner handoffs

- Agent applies `backlog:clarification` when unresolved uncertainty requires product-owner clarification.
- `backlog:clarification` -> `backlog:review` after the product owner resolves uncertainty in issue scope, behavior, or acceptance criteria.
- Agent applies `backlog:acceptance` after verification indicates completion readiness.
- Product owner reviews acceptance evidence and performs final acceptance decisioning while the issue is in `backlog:acceptance`.
- `backlog:acceptance` is terminal for this workflow and indicates product-owner acceptance outcome handling is outside automation scope.

## Causal link validation against skills

The four backlog skills form a closed automation loop over quality gates:

- Review gate decides implementation readiness or refinement need.
- Refinement gate either returns to review or relabels to `backlog:clarification` for product-owner clarification.
- Implementation gate moves to verification only when no substantive work remains.
- Verification gate either loops back to implementation for gaps or relabels to `backlog:acceptance` for product-owner acceptance decisioning.

This creates an auditable cause-and-effect chain where each transition is driven by explicit evidence (review findings, unresolved feedback, remaining work, or verification gaps).

## Workflow invariants

- Exactly one state label from this spec is active on an issue at a time.
- Every transition removes the previous state label and adds exactly one destination label.
- Automation never closes issues in this state workflow.
- `backlog:verification` must not be applied when implementation work remains.
- Agent relabeling is the only mechanism for state transitions in this workflow.
- Product owner decision ownership for clarification/acceptance does not change agent relabel authority.

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
  Then automation removes `backlog:refinement`, adds `backlog:clarification`, and posts a numbered clarification comment for product-owner decisioning.

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
  Then automation removes `backlog:verification`, adds `backlog:acceptance`, and posts one consolidated verification-ready comment for product-owner acceptance decisioning.

- Given an open issue labeled `backlog:clarification`  
  When the product owner resolves uncertainty in issue description, scope, and acceptance criteria  
  Then the product owner removes `backlog:clarification` and adds `backlog:review` so automation can resume.

- Given an open issue labeled `backlog:acceptance`  
  When the product owner performs final product acceptance decisioning  
  Then the issue remains outside automation transition control unless the product owner explicitly re-labels it for further automation work.

- Given an open issue in any workflow state label  
  When an automation run reaches a point that requires clarification or acceptance decisioning  
  Then automation performs the state relabel (`backlog:clarification` or `backlog:acceptance`) and the product owner performs the corresponding business decision action.

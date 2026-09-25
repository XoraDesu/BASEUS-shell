# BASEUS — Agent Operating Protocol

## Authority

Read product truth before acting.

Authority order:

1. `MASTER.md`
2. `DESIGN.md` + accepted `DECISIONS.md`
3. `ROADMAP.md`
4. `TASKS.md`
5. implementation

`ANTI-SLOP.md` applies to all UI work.

## Lifecycle

```text
ORIENT
→ READ SOURCE OF TRUTH
→ CHECK CURRENT STATE
→ UNDERSTAND CURRENT PHASE
→ PLAN
→ IMPLEMENT
→ VALIDATE
→ UI/UX REVIEW
→ ANTI-SLOP REVIEW
→ UPDATE STATE
→ CHECKPOINT
→ REPORT
→ STOP
```

## Progressive Context Loading

Always read:
- `MASTER.md`
- `AGENTS.md`
- `TASKS.md`
- `STATE.md`

For UI work also read:
- `DESIGN.md`
- `ANTI-SLOP.md`

For architectural decisions read:
- relevant `DECISIONS.md` entries
- relevant architecture documentation

Do not load the entire repository unnecessarily.

## Before Implementation

State:
- what will change
- why it is needed
- which files/components are affected
- what remains untouched
- how it will be validated

Choose the smallest coherent implementation.

## Scope Discipline

Do not expand the phase except for:
- a blocking dependency
- a critical regression
- an explicit owner request

Do not silently turn a bug fix into a redesign.

## Product Truth Conflict

If implementation conflicts with MASTER, DESIGN, or an accepted decision:

1. stop the affected work
2. identify the conflict
3. explain the impact
4. propose a solution
5. wait for owner direction

Never edit product truth just to justify code already written.

## Validation

Validation must test the actual acceptance criteria. Never weaken or rewrite validation simply to make a failing implementation pass.

For UI work, validation includes:
- functional behavior
- visual hierarchy
- interaction behavior
- motion behavior
- anti-slop review
- accessibility basics
- performance implications

## Failure Protocol

```text
attempt
→ diagnose
→ make the smallest correction
→ validate again
```

Repeated failure with no clear correction path becomes a blocker. Report it instead of hiding it.

## Definition of Done

A task is done only when:

- implementation works
- relevant regressions are checked
- UX is sensible
- DESIGN is respected
- anti-slop review passes where applicable
- performance is acceptable
- acceptance criteria are validated
- STATE/TASKS are accurate

## Phase Boundary

When the phase exit criteria pass:

- update state
- record checkpoint
- report what changed and what was validated
- STOP

Do not automatically begin the next phase.

## Design Proposals

Significant identity-level visual changes require a Design Proposal and owner approval before implementation.

## Reporting Format

At the end of work, report:

- Completed
- Changed files
- Validation performed
- Known limitations
- Decisions needed
- Next phase/task (without starting it)

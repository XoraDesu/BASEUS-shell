# BASEUS — Decisions

Accepted decisions are product truth. Implementation cannot silently override them.

## Statuses

- Proposed
- Accepted
- Superseded
- Rejected

## D-001 — MIT License

**Status:** Accepted

BASEUS uses the MIT License. The project owner does not require restrictions on commercial use.

**Open detail:** copyright holder/name must be supplied before release.

## D-002 — Single Maintainer / Project Owner

**Status:** Accepted

BASEUS has one final project authority. Contributors may participate through written issues, pull requests, and design proposals. Contribution does not automatically determine project direction.

## D-003 — Design Identity Protection

**Status:** Accepted

BASEUS's established design language is the project's identity and soul. Significant identity-level UI changes require a Design Proposal, owner approval, and an updated decision record before implementation.

## D-004 — Agent Authority Boundary

**Status:** Accepted

Agents may update progress, task status, state, and checkpoints. Agents may not modify MASTER, DESIGN, or accepted decisions merely to make an implementation fit. If implementation conflicts with product truth, affected work stops and the conflict is reported with a proposed solution.

## D-005 — Hybrid Roadmap

**Status:** Accepted

Roadmap structure is Milestone → Phase → Task. The product is organized by capability and dependency rather than a simple list of visual components.

## D-006 — Foundation Freeze

**Status:** Accepted

Once a foundational phase passes its exit gate, later work must not casually rewrite it. Fundamental architectural changes require proposal, impact analysis, owner approval, decision update, and migration planning.

## D-007 — Phase Boundary

**Status:** Accepted

A phase has explicit scope and non-goals. An agent must not expand phase scope except for a blocking dependency, critical regression, or explicit owner request. Completion ends with a stop/report boundary.

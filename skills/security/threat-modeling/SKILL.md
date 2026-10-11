---
name: threat-modeling
description: Identify assets, trust boundaries, entry points, and realistic threats before building a feature. Use at design time for any feature that handles sensitive data, money, or untrusted input.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# Threat Modeling

## Core principle

Designing for security is cheaper than fixing it. Spend a short, structured session
thinking about what could go wrong, who would want it to, and what the blast radius is -
before writing the code.

## Operating procedure

A lightweight, four-question model (adapted from common practice):

1. **What are we building?**
   - Describe the feature and the data it handles.
   - Draw the flow: clients, services, datastores, external systems, and the trust
     boundaries between them.

2. **What can go wrong?**
   For each element, consider the common threat categories (STRIDE is a useful lens:
   Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation
   of privilege). Ask concretely:
   - Can an attacker impersonate a user or service here?
   - Can data be modified in transit or at rest without detection?
   - Can an action be denied later (no audit)?
   - Can data leak to someone who should not see it?
   - Can a small request cause disproportionate work (DoS)?
   - Can a lower-privileged actor gain higher privileges?

3. **What are we going to do about it?**
   For each realistic threat, decide: mitigate (how), accept (with a reason), transfer
   (e.g. provider responsibility), or eliminate (remove the feature/flow). Record the
   decision.

4. **Did we do a good job?**
   Confirm each mitigation is actually implemented and testable. Revisit when the design
   changes.

## Focus areas for common features

- **Authentication/session** - token theft, fixation, replay, weak expiry.
- **Data access** - IDOR, over-broad queries, missing ownership checks.
- **File handling** - traversal, type confusion, resource exhaustion.
- **Integrations** - SSRF, webhook forgery, secret exposure, unbounded retries.
- **Admin/privileged actions** - escalation, missing audit, dangerous defaults.

## Output format

Produce a short, concrete artifact, for example:

| Element | Threat | Likelihood/Impact | Mitigation | Status |
| ------- | ------ | ----------------- | ---------- | ------ |
| Upload endpoint | Path traversal via filename | Med/High | Generate storage name; never use client filename in path | Planned |

Keep it short enough that it is actually written. A one-page model beats an unread
fifty-page document.

## Quality criteria

- Assets, trust boundaries, and entry points are identified.
- Threats are concrete and tied to elements, not generic categories.
- Each realistic threat has a decision (mitigate/accept/transfer/eliminate) and, if
  mitigated, a testable control.
- The model is revisited when the design changes.

## Anti-patterns to avoid

- A generic list of the OWASP Top 10 with no relation to this feature.
- Listing threats with no decisions.
- Treating the model as a one-time document that is never revisited.
- Boiling the ocean with every conceivable threat until the exercise is abandoned.

## Validation strategy

- Confirm each "mitigate" entry maps to code that can be tested.
- Confirm each "accept" entry has a written reason and an owner.
- Re-review the model when the data flow or trust boundaries change.

## Reference

- STRIDE threat modeling; OWASP Threat Modeling guidance.

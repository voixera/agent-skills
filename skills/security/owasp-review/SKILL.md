---
name: owasp-review
description: Review code against recognized web application risk categories and state clearly which checks were not performed. Use when performing a security review of an application or feature.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# OWASP-Oriented Web Security Review

## Core principle

Use a recognized category list (OWASP Top 10 and the Cheat Sheet Series) as a checklist
so reviews are systematic rather than ad hoc. Report honestly: a review covers what was
actually examined, and clearly flags what was not. Do not perform destructive tests
against systems you are not authorized to test.

## Operating procedure

Review the codebase against each category. For each, record what you found and what you
could not check.

1. **Broken Access Control** - Is every protected action authorized server-side? Are
   object-level ownership checks present (no IDOR)? Is access denied by default?
2. **Cryptographic Failures** - Are secrets and sensitive data protected in transit and
   at rest? Are strong algorithms used? Is anything sensitive stored in plaintext?
3. **Injection** - Are SQL/NoSQL/command/LDAP queries parameterized? Is output encoded
   per context? Any unsafe deserialization?
4. **Insecure Design** - Are there missing rate limits, no abuse protection, no
   defense-in-depth on risky flows?
5. **Security Misconfiguration** - Default credentials, verbose errors, permissive CORS,
   debug mode in production, unnecessary features enabled?
6. **Vulnerable and Outdated Components** - Known vulnerabilities in dependencies; unused
   components still present?
7. **Identification and Authentication Failures** - Weak session handling, missing
   expiry/rotation, credential stuffing exposure, weak password policy?
8. **Software and Data Integrity Failures** - Unsigned updates, untrusted deserialization,
   unsafe CI/CD supply chain?
9. **Security Logging and Monitoring Failures** - Are security-relevant events logged
   without sensitive data? Alerts on failure?
10. **Server-Side Request Forgery** - Does the server fetch user-controlled URLs without
    allow-listing and internal-address blocking?

## Operating procedure for the review itself

1. **Scope and authority.** Confirm you are authorized to review this code. Do not run
   active/destructive tests against live systems without explicit authorization.
2. **Read-first review.** For each category, grep and read the relevant code. Record
   observations with file references.
3. **Prefer evidence over assumption.** "There is no rate limiting on the login endpoint"
   is evidence; "rate limiting is probably fine" is not.
4. **Classify findings by severity** and whether they are confirmed or suspected.
5. **State coverage.** List the categories examined, the ones not examined, and why.

## Quality criteria

- Every category is either examined (with a finding or a clear) or explicitly marked
  not examined.
- Findings reference specific code locations.
- Confirmed and suspected findings are distinguished.
- No destructive or unauthorized testing was performed.

## Anti-patterns to avoid

- Claiming "no vulnerabilities found" when only a subset of categories was checked.
- Running exploits against production without authorization.
- Reporting a generic category name with no specific finding.
- Treating a scanner output as a complete review.
- Mixing subjective code-style opinions into a security review.

## Validation strategy

- Produce a table: category, status (examined / not examined), finding, severity.
- For each finding, cite the code and describe the concrete risk.
- If a tool (dependency audit, SAST) was run, report its real output and its limits.

## Limitations

This review is a manual, code-level assessment. It does not include penetration testing,
runtime testing, or infrastructure review unless explicitly stated. Absence of findings
does not mean the application is secure.

## Reference

- OWASP Top 10 (current edition); OWASP Cheat Sheet Series; OWASP ASVS for a deeper checklist.

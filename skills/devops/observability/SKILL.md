---
name: observability
description: Emit structured logs, useful metrics, and traces without logging secrets or personal data. Use when adding logging, metrics, or monitoring to a service.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# Logging and Observability

## Core principle

Observability exists so you can answer "what is happening?" and "why did it break?"
without guessing. That means structured, correlated logs, meaningful metrics, and never
logging sensitive data.

## Operating procedure

1. **Log structured events, not sentences.** Emit JSON (or key-value) with consistent
   fields: timestamp, level, event/message, correlation id, service, and relevant
   identifiers. Structured logs are queryable; free-text blobs are not.

2. **Choose the right level.**
   - `debug` - development detail, off in production.
   - `info` - normal significant events (request handled, job completed).
   - `warn` - something unexpected but handled (a retry, a fallback).
   - `error` - a failure needing attention.
   Avoid `error` for expected outcomes (a validation rejection is `info`/`warn`), which
   drowns real errors in noise.

3. **Correlate with a request/trace id.** Generate an id per request (or accept an
   incoming trace id), include it in every log line and in error responses, so a user
   report can be traced end to end.

4. **Never log sensitive data.**
   - No secrets, tokens, passwords, or `Authorization` headers.
   - No personal data beyond what is necessary; redact or hash where identification is
     needed without exposure.
   - Be careful with request/response body logging: it frequently carries credentials
     and personal data. Log identifiers, not payloads.
   - Redact at the logging layer so individual call sites cannot accidentally leak.

5. **Emit meaningful metrics.** Track what reflects health and the service's purpose:
   request rate, error rate, latency (percentiles, not just averages), saturation (queue
   depth, connection pool usage), and business-relevant counters. Avoid metrics nobody
   acts on.

6. **Add traces where you have many hops.** Distributed tracing shows where time is spent
   across services and where a request failed. Instrument the boundaries (incoming,
   outgoing, database).

7. **Alert on symptoms users feel**, not on every error. Alert on error-rate and latency
   thresholds and on saturation, with a clear owner and runbook. An alert nobody acts on
   is noise that trains people to ignore alerts.

## Quality criteria

- Logs are structured with consistent fields and a correlation id.
- Levels are used correctly; expected outcomes are not logged as errors.
- No secrets or unnecessary personal data in logs; redaction is centralized.
- Metrics cover rate, errors, latency, and saturation.
- Alerts are tied to user-visible symptoms and have owners.

## Anti-patterns to avoid

- `console.log`/`print` debugging left in production paths.
- Logging the full request including the authorization header.
- Catching an exception and logging nothing.
- Averages hiding a terrible p99.
- Alerts on every exception, causing alert fatigue.
- Logging personal data "because it is easier to debug".

## Validation strategy

- Read the logging configuration and confirm redaction of sensitive fields.
- Trigger a request and confirm a correlation id links its log lines.
- Confirm a failure is logged at `error` while an expected validation is not.
- Confirm metrics exist for the golden signals on the main path.
- Grep for `print`/`console.log` in code that runs in production.

## Reference

- The "golden signals" (latency, traffic, errors, saturation); structured logging practice.

---
name: integration-engineering
description: Call external services reliably with timeouts, retries, backoff, idempotency, and webhook verification. Use when integrating a third-party API, webhook, message queue, or any network dependency.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Integration Engineering

## Core principle

Any network call can be slow, fail, or be retried. Design external calls assuming
the remote side is unreliable, and assume your retry will arrive twice.

## Operating procedure

1. **Use a dedicated client** per external service, configured in one place with
   base URL, credentials (from the secret store), and defaults. Do not scatter raw
   HTTP calls.

2. **Always set a timeout.** Connect and read timeouts must exist; the default of
   "wait forever" turns a slow dependency into your outage. Choose a timeout that
   matches the endpoint's expected latency.

3. **Retry only what is safe to retry.**
   - Retry on connection errors, timeouts, `429`, and `5xx`.
   - Do not retry `4xx` client errors (except `429`), which will keep failing.
   - Use exponential backoff with jitter; cap the total attempts and total time.
   - Make the retried operation **idempotent** so duplicates are harmless (see below).

4. **Make writes idempotent.** Use an idempotency key or a natural unique key so a
   repeated call does not create duplicates. This matters most for payments, orders,
   and any non-repeatable side effect.

5. **Respect rate limits.** Honor `Retry-After` and provider quotas. Queue or defer
   work rather than hammering a limited endpoint.

6. **Verify webhooks.**
   - Verify the signature/HMAC using the provider's scheme and a constant-time compare.
   - Reject requests that fail verification.
   - Use the timestamp/replay window if the provider supplies one.
   - Acknowledge quickly and process asynchronously; make processing idempotent since
     providers retry delivery.

7. **Handle partial failure explicitly.** Decide and document what happens when the
   external call fails mid-workflow: roll back, compensate, queue for retry, or surface
   an error. Do not leave work half-done silently.

8. **Protect secrets.** Credentials come from the environment or secret store, are
   never logged, and are never committed.

## Quality criteria

- Every external call has an explicit timeout.
- Retries use bounded, backed-off, jittered attempts and only for retryable failures.
- Non-repeatable writes are idempotent.
- Webhook handlers verify signatures and are idempotent.
- Failure of a dependency has a defined, documented behavior.

## Anti-patterns to avoid

- Unbounded retries or retry storms with no backoff.
- Retrying a non-idempotent create and producing duplicates.
- Trusting a webhook payload without verifying its signature.
- Logging request/response bodies that contain tokens or personal data.
- A single slow dependency taking down unrelated endpoints (no isolation/timeout).

## Validation strategy

- Confirm a timeout is set on each client call site.
- Simulate timeout and `5xx` responses; confirm retry/backoff and final failure behavior.
- Send a webhook twice; confirm idempotent handling.
- Send a webhook with a bad signature; confirm rejection.

## Reference

- RFC 9110 (idempotency of methods); provider docs for webhook signing schemes.

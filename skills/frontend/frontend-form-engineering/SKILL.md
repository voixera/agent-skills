---
name: frontend-form-engineering
description: Build forms with clear validation, accessible errors, loading and disabled states, and protection against duplicate submission. Use when implementing or reviewing any data entry form or its validation.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Frontend Form Engineering

## Core principle

Client-side validation is a usability feature, never a security control. Every
constraint enforced in the browser must also be enforced on the server. State this
in any form implementation.

## Operating procedure

1. **Design the validation behavior.**
   - Validate on blur and on submit by default; avoid validating on every keystroke
     for a field the user is still typing (it is discouraging and noisy).
   - Show an error next to the field it belongs to, not only in a summary.
   - Re-validate a field once it has an error, so the error clears when fixed.

2. **Write clear messages.** Say what is wrong and how to fix it.
   - Bad: "Invalid input."
   - Good: "Enter a date in the past."

3. **Associate errors accessibly.** Link the message to the input with
   `aria-describedby`, set `aria-invalid` on the field, and move focus to the first
   error on submit failure. Do not rely on color alone (see the accessibility skill).

4. **Handle submission states.**
   - Disable the submit control or guard against re-entry while a request is in flight.
   - Show a loading indicator on the submit control.
   - Keep the entered values on failure; do not clear the form on a server error.
   - Show a distinct, non-field-level message for server/network failures.

5. **Prevent duplicate submissions.** Guard with an in-flight flag, and make the
   server operation idempotent where the action is not naturally repeatable (see the
   API design skill).

6. **Keyboard usability.**
   - The form is completable with keyboard alone.
   - Enter submits a single-field form and moves appropriately in multi-field forms.
   - Focus order matches visual order.

7. **Use appropriate input types.** `type="email"`, `inputmode="numeric"`,
   `autocomplete` attributes and sensible `name`s improve mobile and auto-fill
   behavior for free.

8. **Mirror the rules on the server.** Enumerate the same constraints in server-side
   validation and in tests.

## Quality criteria

- Each field has a label, and errors are associated and announced.
- Submit is protected against duplicate submission.
- Loading, disabled, error, and success states all defined.
- Values persist on server-side failure.
- Server repeats every validation rule enforced on the client.

## Anti-patterns to avoid

- Validating on every keystroke and flashing errors mid-typing.
- A single generic "Something went wrong" for all failures.
- Clearing the form on error.
- Relying on client validation for security.
- Disabled submit with no explanation of what is missing.

## Validation strategy

- Keyboard-only completion of the form, including triggering and correcting errors.
- Simulate a slow request and a failed request; confirm loading and error states.
- Double-click / double-submit test; confirm only one request is sent.
- Confirm the server rejects values the client would reject.

## Reference

- WCAG: error identification and labels; HTML `autocomplete` attribute.

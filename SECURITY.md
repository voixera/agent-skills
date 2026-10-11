# Security Policy

## Supported versions

This project is in initial development. There are no published releases yet.

| Version | Supported |
| ------- | --------- |
| unreleased development | Best effort |

## Reporting a vulnerability

Please report security issues privately rather than opening a public issue.

Use GitHub's **private vulnerability reporting** on this repository
(Security tab -> "Report a vulnerability") if it is enabled. If you cannot use
that channel, open a minimal public issue that says only that you have a security
report and would like a private channel; do not include exploit details.

Please include, where possible:

- The affected component (registry validation, an adapter, the installer,
  the SVGs produced, or the validator).
- A description of the issue and its impact.
- Reproduction steps or a minimal example.
- The version or commit you tested.

## Scope

This toolkit:

- Writes instruction and configuration files to a selected project or user scope.
- Reads and validates JSON registries and SVG markup.
- Does **not** execute skill content during installation.
- Does **not** transmit data to any external service.

Issues of particular interest:

- Path traversal or writes escaping the selected installation scope.
- Silent overwrite or deletion of user-owned (untracked) files.
- Deletion of unrelated files during uninstall.
- Weak SVG security detection that could give a false sense of safety.
- Registry content that could cause code execution during install or verify.

## Out of scope

- The behavior of third-party AI agents after skills are installed.
- Security of third-party tools invoked optionally (for example, an external
  SVG optimizer or a project's own linter). These are documented as optional.
- Any guarantee that SVGs produced by an AI agent using these skills are safe or
  original. See the SVG security and visual review skills for the guarantees that
  are and are not made.

## Our commitments

- We will not claim a check passed unless it was actually run.
- Security-relevant checks are conservative and report their own limitations.
- We will not store credentials or API keys anywhere in the registry.

## Handling of secrets

This repository must never contain secrets. If you find one, report it privately.
The CI configuration includes a secret scan step as a first line of defense, but
it is not a substitute for reporting.

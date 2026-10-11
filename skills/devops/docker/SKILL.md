---
name: docker
description: Write small, reproducible, non-root container builds with sane layers, health checks, and secret handling. Use when creating or reviewing a Dockerfile or container configuration.
metadata:
  category: devops
  version: 1.0.0
  agents: all
  tools: docker
---

# Docker and Containers

## Core principle

A container image should be small, reproducible, and run with the fewest privileges
possible. Reproducibility means the same inputs build the same image, and secrets are
never baked into a layer.

## Operating procedure

1. **Choose an appropriate base image.**
   - Prefer a minimal, well-maintained base (distroless, slim, or alpine variants) when
     compatibility allows. Weigh size against debuggability and native-compatibility needs.
   - Pin the base to a specific version (and digest where reproducible builds matter),
     not a floating `latest`.

2. **Structure layers for caching and size.**
   - Copy the dependency manifest first, install dependencies, then copy the source, so
     code changes do not invalidate the dependency layer.
   - Combine related `RUN` steps to reduce layers, but keep them readable.
   - Clean package caches in the same layer that installs them.
   - Order instructions from least to most frequently changing.

3. **Run as non-root.**
   - Create and switch to an unprivileged user for the runtime stage.
   - Do not run the application as `root`.

4. **Use multi-stage builds** to keep build tooling out of the final image: build in one
   stage, copy only the artifacts into a minimal runtime stage.

5. **Never bake secrets into the image.** No `ENV SECRET=...`, no copying `.env` or keys.
   Use build secrets for build-time needs and runtime environment/secret stores for the
   application. Remember: values in any layer remain in the image history.

6. **Add a health check** where the platform uses one, so orchestrators can detect a
   wedged container.

7. **Handle signals correctly.** Run the application as PID 1 with correct signal
   handling (use an init such as `tini`, or an exec-form `ENTRYPOINT`) so it shuts down
   gracefully on `SIGTERM`.

8. **Be explicit about the ports and the entrypoint.** Use `EXPOSE` for documentation and
   an exec-form `ENTRYPOINT`/`CMD`.

9. **Pin and audit build dependencies** like any other dependency.

## Quality criteria

- Base image is minimal and version-pinned.
- Dependency layer is cached separately from source.
- Container runs as a non-root user.
- No secrets in any layer.
- Health check present where the platform uses it.
- PID 1 handles signals; shutdown is graceful.

## Anti-patterns to avoid

- `FROM image:latest`.
- `ENV API_KEY=...` or copying `.env` into the image.
- Running as root in production.
- Copying the whole repo before installing dependencies, busting the cache every build.
- A single-stage image carrying compilers and dev tooling into production.
- Ignoring `SIGTERM`, causing slow or forced kills.

## Scope note

Do not add a container to a project that has no containerization need. If the project
already deploys without containers, do not introduce Docker "because it is standard".

## Validation strategy

- Inspect the image for expected user and absence of secrets (`docker history`, config).
- Build twice and confirm hashes match for reproducible inputs where claimed.
- Confirm the container starts, passes its health check, and shuts down on `SIGTERM`.
- Report the image size before/after changes if size is a claim.

## Reference

- Docker build best practices documentation.

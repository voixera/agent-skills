---
name: secure-file-handling
description: Handle uploads, paths, and archives safely against traversal, type confusion, and resource exhaustion. Use when accepting files, reading user-supplied paths, or extracting archives.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# Secure File Handling

## Core principle

A filename is user input. A file's declared type is user input. An archive's contents are
user input. None of them may be trusted to be what they claim, or to stay inside the
directory you intended.

## Operating procedure

1. **Never trust the client filename for a path.**
   - Generate a new storage name (a UUID or content hash) and store the original name
     only as display metadata.
   - If the original name must be used, strip directory components, reject `..`, and
     normalize the path.
   - Prevent path traversal: after resolving the final absolute path, verify it is still
     inside the intended base directory. A normalized path check is the reliable control,
     not a string replace.

2. **Validate type by content, not by claim.**
   - Do not trust the extension alone, or the client-sent `Content-Type` alone.
   - Inspect the file's magic bytes / actual content to confirm the type.
   - Decide an allow-list of accepted types and reject everything else. Prefer rejecting
     on ambiguity.

3. **Bound resource usage.**
   - Enforce a maximum file size, and enforce it while reading (stream), not after loading
     the whole thing into memory.
   - Limit the number of files per request and the total request size.
   - Apply timeouts and limits to processing (image resizing, parsing).

4. **Store safely.**
   - Store uploads outside the web root, or in object storage, so they cannot be executed
     or served as code from your origin.
   - If files must be served, serve them with a safe `Content-Type` and
     `Content-Disposition` and from a separate origin where possible.
   - Strip metadata when the file type embeds it (EXIF in images) if privacy matters.

5. **Handle archives carefully.**
   - Guard against archive bombs (zip within zip, huge expansion ratio).
   - Extract only after validating each entry's path stays inside the destination
     (the same traversal check applies to `../` entries inside the archive).
   - Limit total extracted size and entry count.

6. **Clean up and isolate.** Remove temporary files; never process uploads with the same
   privileges as trusted internal files.

## Quality criteria

- Storage names are generated; client names are never used as paths.
- Final resolved paths are verified to be inside the intended base directory.
- Type is validated by content, with an allow-list.
- Size and count are bounded during reading.
- Archives are checked for traversal and expansion bombs.
- Uploads are stored/served in a way that prevents execution.

## Anti-patterns to avoid

- `path.join(uploadDir, req.file.originalname)` without traversal checks.
- Trusting the file extension or the client `Content-Type`.
- Reading an entire upload into memory before checking its size.
- Extracting an archive without validating entry paths.
- Serving user uploads from the main application origin as executable content.

## Validation strategy

- Test a filename containing `../` and confirm rejection / safe storage.
- Test a file whose content does not match its extension and confirm rejection.
- Test a file exceeding the size limit and confirm it is rejected during streaming.
- Test an archive with a `../` entry and confirm extraction is blocked.
- If a control cannot be exercised here, report it as not verified.

## Reference

- OWASP File Upload Cheat Sheet; OWASP Path Traversal guidance.

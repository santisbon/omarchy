# Reporting Issues and Submitting PRs

Read this when the user wants to report an Omarchy bug, suggest a feature, or
contribute a fix.

Omarchy's desktop lives at https://github.com/santisbon/omarchy. Its maintainer
forwards a bug to another project when the bug turns out to be that project's.
Route requests:

- **Verified bugs** -> GitHub issues on santisbon/omarchy. Issues are for
  validated bugs; when it is not clear yet whether something is a bug, say so
  to the user instead of filing.
- **Feature ideas and suggestions** -> also an issue on santisbon/omarchy, with
  a title that starts with "Suggestion:", and only after the user agrees.

## Filing a Good Bug Report

The bug template asks for system details (CPU, GPU, Omarchy version), a
description with steps to reproduce, and diagnostics. Gather them:

```bash
omarchy version

# Generate the diagnostic log (also written to /tmp/omarchy-debug.log)
# There is no log upload service: quote the relevant lines in the issue.
omarchy debug --no-sudo --print
```

**Capture the problem on screen.** A screenshot or short recording of the bug
is often worth more than the description — see [`capture.md`](capture.md) for
`omarchy capture screenshot` and `omarchy screenrecord`. Keep recordings short
and focused on the misbehavior. GitHub issue attachments are added by
drag-and-drop in the web form, so save the capture and hand the user the file
path to attach (`gh` cannot upload media).

For screen-recording failures specifically, rerun with
`OMARCHY_SCREENRECORD_DEBUG=true` and attach `/tmp/omarchy-screenrecord.log`.

File the issue with `gh` when available:

```bash
gh issue create --repo santisbon/omarchy --title "..." --body "..."
```

Include: what happened, what was expected, steps to reproduce, system details,
the relevant lines of the debug log, and the capture.

## Submitting a PR

Never develop against `/usr/share/omarchy`. Clone a working copy instead:

```bash
gh repo fork santisbon/omarchy --clone
cd omarchy
```

Follow the repository's own `AGENTS.md` for style, testing, and commit
conventions — it is the authority on contributions. Keep commits atomic, run
`./test/all` before pushing, and open the PR with `gh pr create`. A PR that
fixes a visual problem should include before/after captures (again, see
[`capture.md`](capture.md)).

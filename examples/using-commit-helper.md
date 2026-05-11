# Using the commit-helper skill

This file shows what an interaction with the `commit-helper` skill looks like in practice. Nothing in this file gets executed; it is documentation.

## Setup

After cloning this repo, copy the `.claude/` directory into your own project, or symlink the individual skills:

```bash
mkdir -p .claude/skills
ln -s /path/to/claude-code-skills-starter/.claude/skills/commit-helper .claude/skills/commit-helper
```

## Triggering it

Stage some changes, then ask Claude in plain English:

> draft a commit message for what I have staged

Claude reads the skill description, decides it applies, and runs the steps in `SKILL.md`.

## Example session

Suppose you have edited `src/auth.py` to fix a token-refresh bug.

```
$ git add src/auth.py
$ git diff --cached
diff --git a/src/auth.py b/src/auth.py
index 1f2a..3c4b 100644
--- a/src/auth.py
+++ b/src/auth.py
@@ -42,7 +42,7 @@ def refresh_token(client):
-    if client.token_expires_at <= now():
+    if client.token_expires_at <= now() + REFRESH_LEEWAY:
         client.token = client.fetch_new_token()
```

You ask Claude:

> write a commit message

The skill produces:

```
fix off-by-one in token refresh window

Refresh now happens REFRESH_LEEWAY before expiry instead of at expiry,
which avoids a race where the token expires mid-request after the
freshness check passes.
```

The body explains the *why* (avoid race), not what changed line-by-line.

## When it does not trigger

If you say "make a commit" or "commit this", the skill should not invoke. The description is intentionally narrow ("draft", "write", "improve") so it does not get in the way of plain commit operations.

If it ever fires when you do not want it to, edit the `description` field in `SKILL.md` to be more restrictive.

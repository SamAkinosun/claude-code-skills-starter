---
name: commit-helper
description: Use this skill when the user asks to write, draft, or improve a git commit message. Reads the staged diff and proposes a single-line subject plus optional body. Do not invoke for "make a commit" if the user has not asked for help with the message.
---

# commit-helper

When this skill triggers, do the following in order:

1. Run `git diff --cached --stat` to see what is staged. If nothing is staged, run `git diff --stat` and tell the user the changes are not staged yet. Do not auto-stage.

2. Run `git diff --cached` (or `git diff` if nothing is staged) to read the actual changes. If the diff is larger than 500 lines, sample the first 200 and the last 100 instead of reading everything, and note that the message is based on a sample.

3. Run `git log -n 5 --pretty=format:"%s"` to match the repo's existing commit style.

4. Draft a message with this shape:

   ```
   <subject line, imperative mood, under 72 chars>

   <optional body explaining the why, wrapped at 72>
   ```

   Subject line rules:
   - Imperative mood ("add" not "added", "fix" not "fixed")
   - No trailing period
   - No conventional-commits prefix unless the repo's recent log uses them
   - Lowercase first word unless it is a proper noun

   Body rules:
   - Skip the body for trivial changes (one-line fixes, typo fixes, dependency bumps)
   - When included, explain why the change was made, not what changed
   - Reference issues only if the user mentioned an issue number

5. Show the draft to the user. Do not run `git commit` unless they explicitly ask.

## Anti-patterns

Do not produce messages like:
- "Update files" (vacuous)
- "feat: implement comprehensive solution for X" (marketing language)
- "Fixed bug" (past tense, no detail)
- Multi-paragraph bodies for a one-line code change

## Edge cases

- Merge commits: skip the body, use the default merge message format
- Revert commits: use `Revert "<original subject>"` and include the original SHA in the body
- WIP commits: if the user says "wip" or "work in progress", produce `wip: <area>` and skip the body

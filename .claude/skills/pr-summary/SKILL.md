---
name: pr-summary
description: Use this skill when the user asks to summarize a pull request, write a PR description, or explain what a PR does. Works on the current branch's diff against the base branch, or on a specific PR number via gh CLI.
---

# pr-summary

When this skill triggers:

1. Determine the PR scope:
   - If the user passed a PR number, run `gh pr view <number> --json title,body,baseRefName,headRefName` and `gh pr diff <number>`.
   - If the user did not pass a number, run `git rev-parse --abbrev-ref HEAD` to get the current branch and compare against `main` (fall back to `master` if `main` does not exist). Use `git diff <base>...HEAD` and `git log <base>..HEAD --pretty=format:"%h %s"`.

2. Read the diff. If it is larger than 800 lines, summarize each changed file in one sentence rather than reading line by line.

3. Produce a summary with this structure:

   ```markdown
   ## What changed

   <2-4 bullets. Each bullet is one logical change, not one file.>

   ## Why

   <1-3 sentences. The motivation. If you cannot infer it, ask the user.>

   ## How to review

   <Bulleted list. Suggest the order to read files, what to look for, what to ignore.>

   ## Test plan

   <Bulleted checklist of what to verify. Real steps, not "test thoroughly".>
   ```

4. If the repo has a `.github/PULL_REQUEST_TEMPLATE.md`, match its section names instead of the defaults above.

5. Print the summary. Do not call `gh pr edit` or `gh pr create` unless the user asks.

## Style rules

- Write at the level of "another engineer on the team will read this"
- Avoid restating function or variable names that are already obvious from the diff
- One sentence per bullet in the "What changed" section
- Quote actual error messages or behaviors when relevant, not paraphrases

## When to push back

- If the diff touches more than 15 files and they are clearly unrelated, suggest splitting the PR
- If the test plan would be longer than 10 items, suggest splitting the PR
- If the diff has commented-out code, debug `print` statements, or `.only`/`.skip` in tests, flag these in a "Before merging" section at the end

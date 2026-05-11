# claude-code-skills-starter

A small, opinionated starter for [Claude Code](https://docs.anthropic.com/claude-code) skills, hooks, and `settings.json`. Three working skills, two working hooks, one CI job, and a README that actually explains the choices instead of just listing the files.

If you have read the official docs and walked away wondering what a useful skill actually looks like in practice, this repo is for you.

## Why this exists

I started writing Claude Code skills the third time I caught myself pasting the same "draft a tight commit message from this diff" prompt. The skills system itself is straightforward, but the public examples I found were either toy demos that did not survive contact with real work, or 200-line "everything and the kitchen sink" skills that the model could not reliably trigger.

This repo is the in-between: small skills with narrow descriptions, hooks that block obvious mistakes without getting in the way, and a `settings.json` that is annotated rather than mysterious.

## What is in here

```
claude-code-skills-starter/
├── .claude/
│   ├── settings.json              annotated, project-level config
│   ├── skills/
│   │   ├── commit-helper/         draft a commit message from staged diff
│   │   ├── prd-scaffold/          generate a PRD markdown file
│   │   └── pr-summary/            summarize the current branch or a gh PR
│   └── hooks/
│       ├── block-secrets.sh       PreToolUse hook, blocks Write/Edit on common secret patterns
│       └── notify-stop.sh         Stop hook, sends a desktop notification
├── examples/                      walkthroughs of using each skill
├── tests/
│   └── test_block_secrets.py      smoke tests for the secrets hook
├── .github/workflows/test.yml     runs the hook tests on push and PR
├── LICENSE                        MIT
└── README.md
```

Total install footprint when you copy `.claude/` into your own project: about 15 KB.

## Quick start

You have two reasonable options.

### Option 1: copy into your project

```bash
git clone https://github.com/SamAkinosun/claude-code-skills-starter.git
cp -R claude-code-skills-starter/.claude /path/to/your/project/
chmod +x /path/to/your/project/.claude/hooks/*.sh
```

Open the project in Claude Code. The skills are now available; the hooks fire automatically.

### Option 2: cherry-pick

Skills are independent. If you only want the commit helper, copy that one directory:

```bash
mkdir -p /path/to/your/project/.claude/skills
cp -R claude-code-skills-starter/.claude/skills/commit-helper /path/to/your/project/.claude/skills/
```

Hooks are also independent, but they need a matching entry in `settings.json` to fire. See the [settings.json walkthrough](#settingsjson-walkthrough) below.

## The skills

Each skill is a `SKILL.md` file with frontmatter. Claude Code reads the `description` field to decide when to invoke the skill, so the description is the most important part. Be specific about when *not* to fire.

### commit-helper

**Triggers when:** you ask for help drafting, writing, or improving a commit message. Does not fire on bare "commit this".

**What it does:**
1. Reads the staged diff (or unstaged, if nothing is staged, with a warning).
2. Reads the last 5 commit subjects to match the repo's existing style.
3. Produces a single subject line in imperative mood plus an optional body explaining the *why*.
4. Stops short of running `git commit`. You stay in control.

The skill is opinionated about subject style: imperative mood, under 72 chars, no trailing period, no Conventional Commits prefix unless your repo's recent log already uses them. It will explicitly skip the body for trivial changes (typo fixes, dependency bumps).

See [examples/using-commit-helper.md](examples/using-commit-helper.md) for a full session.

### prd-scaffold

**Triggers when:** you ask for a PRD, product spec, design doc, or feature brief.

**What it does:** creates a markdown file with these sections in order: Problem, Why now, Goals, Non-goals, Proposed solution, Open questions, Risks, Success metrics. Anything the skill cannot infer from your prompt becomes a `<TODO: ...>` marker rather than invented content.

The "Why now" section is optional and the skill will drop it when there is no real time-sensitive trigger. The "Future work" section is *not* present by default; I have found it almost always becomes a graveyard for ideas no one will revisit.

See [examples/using-prd-scaffold.md](examples/using-prd-scaffold.md).

### pr-summary

**Triggers when:** you ask to summarize a PR, write a PR description, or explain what a PR does. Works on either the current branch (compared to `main`) or a specific PR number via `gh pr view`.

**What it does:** produces a four-section summary (What changed, Why, How to review, Test plan). If your repo has a `.github/PULL_REQUEST_TEMPLATE.md`, the skill matches your template's section names instead of the defaults.

The skill will push back if the diff touches more than 15 unrelated files, or if the test plan would exceed 10 items. Both are signals that the PR should be split.

## The hooks

Hooks are bash scripts that Claude Code runs around tool calls or session events. They receive a JSON payload on stdin and signal allow/block via exit code.

### block-secrets.sh (PreToolUse)

Runs before every `Write` and `Edit` call. Scans the proposed content against patterns for OpenAI/Anthropic-style API keys, GitHub PATs, GitHub server tokens, AWS access key IDs, Slack tokens, and PEM private key blocks. If anything matches, the hook exits 2 and the model sees a stderr message explaining what was blocked and why.

It deliberately errs toward false positives. Three reasons:
1. The cost of a leaked key in your commit history is much higher than the cost of a false positive.
2. The skip list is short and explicit (`*.env.example`, `*/SECRETS.md`, `*/secrets.example.*`) so you can opt out when you are intentionally writing example values.
3. If you hit a false positive, the stderr message tells the model how to fix it (move the value into an env var), so the next attempt usually works.

Run the bundled tests:

```bash
python3 tests/test_block_secrets.py
```

Output:

```
ok   clean python content is allowed
ok   github personal access token is blocked
ok   aws access key id is blocked on Edit
ok   private key block is blocked
ok   dotenv example file is allowed even with token-shaped value
ok   non Write/Edit tool calls are ignored
ok   slack token is blocked

7/7 passed
```

Add your own patterns by editing the `PATTERNS` block in the script. Each line is a regex, a tab, then a human-readable label.

### notify-stop.sh (Stop)

Fires a desktop notification when Claude finishes a turn. macOS uses `osascript`; Linux falls back to `notify-send` if available; Windows / WSL is a deliberate no-op (edit the script to add your preferred notifier).

Always exits 0 so it never blocks. Drains stdin so the parent does not hang on a broken pipe.

I do not recommend this hook if you keep Claude Code visible at all times. It pays off when you let it run a long task in the background.

## settings.json walkthrough

The bundled `settings.json` is a project-level config. If you want these defaults globally instead, move the file to `~/.claude/settings.json`.

Key sections:

**`permissions.allow`** lists tool calls that run without prompting. The starter pre-approves read-only git and `gh` commands, plus `ls`, `cat`, `Read`, `Grep`, and `Glob`. These cover ~80% of what Claude does in a typical session and remove most of the "approve this?" friction.

**`permissions.deny`** lists tool calls that are flatly refused, even when you would normally be asked. The starter denies `rm -rf`, `git push --force`, and `git reset --hard`. Add your own here for anything destructive that you never want to authorize, even by accident.

**`hooks.PreToolUse`** registers `block-secrets.sh` against the `Write|Edit` matcher. The matcher is a regex, so `Write|Edit` covers both tool names. Add more matchers for finer control.

**`hooks.Stop`** registers `notify-stop.sh` with no matcher (Stop has no tool name to match against).

The `$CLAUDE_PROJECT_DIR` substitution is a Claude Code built-in that resolves to your project root, so the hook paths are portable across machines.

## Adding your own skill

1. Create a directory under `.claude/skills/`:

   ```bash
   mkdir -p .claude/skills/my-skill
   ```

2. Drop a `SKILL.md` inside with frontmatter:

   ```markdown
   ---
   name: my-skill
   description: Use this skill when the user asks for X. Do not invoke for Y.
   ---

   # my-skill

   Steps the model should follow when this skill triggers.
   ```

3. Restart Claude Code (or reload the project) so it picks up the new skill.

The two things that most affect whether a skill triggers reliably:

- The `description` field. Be specific about *when* and equally specific about *when not*. Vague descriptions cause the skill to fire when you do not want it and to be skipped when you do.
- The skill body. Number your steps. The model follows numbered steps more reliably than prose.

## Limitations and known issues

- **The hooks assume a Unix-like shell.** They work on macOS and Linux. On Windows, run them under WSL or rewrite as PowerShell. PRs welcome for native Windows versions.
- **`block-secrets.sh` is pattern-based.** It catches obvious tokens but will not catch a custom secret format (e.g. an internal-only key prefix). If your team uses such a format, add a pattern for it. There is no entropy-based scanner here on purpose; that adds dependencies and false positives faster than it adds value.
- **The `commit-helper` does not handle binary diffs gracefully.** If the staged change is mostly binary, you will get a vague message. This is a known sharp edge; suggestions welcome.
- **The `pr-summary` skill assumes `gh` is installed and authenticated** when you pass a PR number. If you do not use `gh`, the branch-based mode still works.
- **No tests for the skills themselves.** Skills are markdown files interpreted by the model, so testing them requires running the model. The CI here covers the hooks only.

## FAQ

**Why are the skills so short?**

Because long skills are not more capable, they are just harder for the model to follow. Each skill here is a single file under 80 lines. If you find yourself writing more than that, the skill is probably trying to do two things and should be split.

**Why no `.claude/CLAUDE.md`?**

`CLAUDE.md` is project-instructions, not skill or hook config, so it does not belong in a skills starter. If you want a `CLAUDE.md` template, [Anthropic's docs](https://docs.anthropic.com/claude-code) cover that better than I would.

**Why MIT and not Apache 2.0?**

Smaller, more permissive, and the patent grant in Apache 2.0 is overkill for ~15 KB of bash and markdown. If you need Apache 2.0 for organizational reasons, fork it and relicense; the original MIT terms allow this.

**Will this work with future Claude Code versions?**

The hook event names (`PreToolUse`, `Stop`) and the skill frontmatter format have been stable since the skills feature shipped. The `$CLAUDE_PROJECT_DIR` variable was added in a later version. If a future change breaks something here, open an issue and I will look.

**Can I use this with the Anthropic API directly instead of Claude Code?**

No. Skills and hooks are Claude Code features. The patterns in the SKILL.md files are reusable as system prompts, but the file format only means something inside Claude Code.

## Tested with

- Claude Code v2.x on macOS 14 and Ubuntu 22.04
- Python 3.11 and 3.12 (for the test script)
- bash 3.2 (the macOS default) and bash 5.x

## Contributing

Issues and PRs welcome. A few notes:

- New skills should follow the same structure: narrow `description`, numbered steps, anti-patterns called out explicitly.
- New hooks need test coverage in `tests/`.
- Keep the README in sync with reality. If you add a skill, add it to the file tree and the skills section.
- No emojis in code or docs. Plain text only.

## License

MIT, see [LICENSE](LICENSE).

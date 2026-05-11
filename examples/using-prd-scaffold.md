# Using the prd-scaffold skill

A walkthrough of what it looks like when the `prd-scaffold` skill fires.

## Triggering it

Ask Claude something like:

> write a PRD for adding two-factor auth to the dashboard

The skill triggers on the word "PRD". It also responds to "product spec", "design doc", and "feature brief".

## What you get

The skill creates `prd-two-factor-auth.md` (or `docs/prd-two-factor-auth.md` if a `docs/` directory exists). The file follows the section order defined in `SKILL.md`:

```markdown
# Two-factor auth for the dashboard

**Status:** Draft
**Owner:**
**Last updated:** 2026-05-10

## Problem

Dashboard accounts are protected by password only. <TODO: how often
are credentials phished or reused?> Today, users who want stronger
protection have no option in-product.

## Why now

<TODO: is there a trigger event, e.g. recent incident or compliance
deadline? If not, delete this section.>

## Goals

- Offer TOTP-based 2FA as an opt-in setting
- Recovery codes generated at setup time
- ...
```

Anything the skill cannot infer becomes a `<TODO: ...>` marker. This is intentional: filling those in is your job, and inventing answers there would produce a worse doc than flagging the gap.

## Customizing the section order

If your team uses a different template, edit the markdown block in `SKILL.md`. The model copies that template exactly, so your changes propagate without any code change.

## What it deliberately does not do

- Does not commit the file
- Does not push to a remote
- Does not invent metrics or risks
- Does not include a "Future work" section by default

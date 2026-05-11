---
name: prd-scaffold
description: Use this skill when the user asks for a PRD, product spec, design doc, or feature brief. Generates a single markdown file with the standard sections. Do not invoke for general "what should we build" brainstorming.
---

# prd-scaffold

When this skill triggers:

1. Confirm the feature title and the target audience in one short clarifying question if either is missing from the user's request. If both are clear, skip the question.

2. Create a file named `prd-<kebab-case-feature-name>.md` in the current directory (or under `docs/` if that directory exists).

3. Use this exact section order:

   ```markdown
   # <Feature name>

   **Status:** Draft
   **Owner:** <leave blank for the user to fill>
   **Last updated:** <today's date in YYYY-MM-DD>

   ## Problem

   <2-4 sentences. Who is hitting the problem, how often, what they do today as a workaround.>

   ## Why now

   <1-2 sentences. What changed that makes this worth doing now. Skip if there is no time-sensitive reason.>

   ## Goals

   <Bulleted list. Each goal is measurable.>

   ## Non-goals

   <Bulleted list. What this feature explicitly does not do. Useful for scope control.>

   ## Proposed solution

   <2-6 paragraphs. Walk through the user-facing flow first, then the implementation sketch.>

   ## Open questions

   <Bulleted list. Things the team needs to decide before building.>

   ## Risks

   <Bulleted list. What could go wrong and what the mitigation is.>

   ## Success metrics

   <How we will know this worked. Specific numbers, not "users will be happy".>
   ```

4. Fill in what you can infer from the user's prompt. Mark anything you genuinely cannot infer with `<TODO: ...>` rather than making it up.

5. Show the file path back to the user when done. Do not commit.

## Style rules

- One concept per paragraph
- Avoid hedging language ("we might want to consider possibly...")
- Use the user's own terminology where they have used a specific term
- Do not include a "future work" section unless the user mentions roadmap items

## Anti-patterns

- Padding sections with filler when there is nothing real to say
- Inventing metrics like "10x improvement" without basis
- Listing every possible risk; cap at the top 3-5

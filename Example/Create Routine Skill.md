# Create Routine

Generate a properly formatted routine markdown file that the RoutineRunner iOS app can parse.

## Format Rules

The file MUST follow this exact format:

# Routine Title

## Step Name (Xm)
- Optional note
- [Optional Link Text](https://url)

## Step Name (Xm)

## Step Name (Xm)
- Note 1
- Note 2

### Requirements:
- Line 1: `# Title` — exactly one H1 heading for the routine title
- Steps: `## Step Name (duration)` — H2 headings, each with a duration at the end in parentheses
- Duration format: `(Xm)` for minutes, `(Ys)` for seconds, or `(Xm Ys)` for both. Examples: `(5m)`, `(30s)`, `(2m 30s)`
- Notes (optional): `- text` bullet points under a step
- Links (optional): `- [display text](url)` markdown links in notes
- Blank lines between steps for readability
- No duration defaults to 60 seconds in the parser, but always include explicit durations
- File extension must be `.md`
- Filename should be lowercase with hyphens, e.g. `morning-routine.md`

### Preference:
- Prefer **main steps (H2 headings)** for nearly all actions
- Break tasks into multiple sequential main steps instead of grouping under one step
- Use sub-items (`- bullets`) **only for minor notes, clarifications, or links**
- Avoid placing actual actionable steps inside bullet points

## Instructions

1. Ask the user what the routine is about if they haven't described it
2. Generate the markdown content following the format above
3. Write the file to the project root or wherever the user specifies
4. Show the user the generated content
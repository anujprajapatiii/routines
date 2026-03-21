---
description: Generate a routine markdown file from a user description. Use when the user wants to create a new routine, add steps, or generate a .md routine file.
user_invocable: true
---

# Create Routine

Generate a properly formatted routine markdown file that the RoutineRunner iOS app can parse.

## Format Rules

The file MUST follow this exact format:

```
# Routine Title

## Step Name (Xm)
- Optional note
- [Optional Link Text](https://url)

## Step Name (Xm Ys)

## Step Name (Ys)
- Note 1
- Note 2
```

### Requirements:
- **Line 1**: `# Title` — exactly one H1 heading for the routine title
- **Steps**: `## Step Name (duration)` — H2 headings, each with a duration at the end in parentheses
- **Duration format**: `(Xm)` for minutes, `(Ys)` for seconds, or `(Xm Ys)` for both. Examples: `(5m)`, `(30s)`, `(2m 30s)`
- **Notes** (optional): `- text` bullet points under a step
- **Links** (optional): `- [display text](url)` markdown links in notes
- **Blank lines** between steps for readability
- **No duration** defaults to 60 seconds in the parser, but always include explicit durations
- File extension must be `.md`
- Filename should be lowercase with hyphens, e.g. `morning-routine.md`

## Instructions

1. Ask the user what the routine is about if they haven't described it
2. Generate the markdown content following the format above
3. Write the file to the project root or wherever the user specifies
4. Show the user the generated content

## Example

For input "a 15 minute morning stretch routine", generate:

```markdown
# Morning Stretch

## Neck rolls (2m)
- Slow circles, both directions

## Shoulder shrugs (1m 30s)

## Cat-cow stretch (2m)
- On hands and knees
- Sync movement with breath

## Standing forward fold (2m)

## Quad stretch (2m)
- 1 minute each leg

## Hip circles (1m 30s)

## Child's pose (2m)
- Focus on deep breathing

## Savasana (2m)
```

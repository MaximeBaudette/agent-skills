---
name: gemini-cli
description: "Run autonomous dev tasks using Gemini CLI (gemini-cli) with Maxime's free Google quota. Use for programming projects where MARS needs to delegate agentic coding work — file edits, code gen, refactoring, analysis — to Gemini in a project directory."
homepage: https://github.com/google-gemini/gemini-cli
metadata:
  openclaw:
    emoji: "♊"
    requires:
      bins: ["gemini"]
---

# Gemini CLI Skill

Delegate autonomous dev tasks to Gemini CLI using Maxime's free Google OAuth quota.

## Binary

```
~/bin/gemini   (v0.34.0)
```

Auth is pre-configured via OAuth personal (`~/.gemini/settings.json`). No API key needed.

## When to Use

Use this skill when Maxime assigns a coding task on a local project and wants Gemini to do the heavy lifting — code generation, refactoring, file edits, analysis, etc.

**Good fit:**
- "Fix the bug in this repo"
- "Refactor this module"
- "Generate tests for this file"
- "Analyze this codebase and summarize the architecture"

**Not a fit:** web search, emails, calendar, anything outside a local project directory.

## Core Usage

### Headless (non-interactive) — preferred

Run a single task and get output back:

```bash
cd /path/to/project
gemini -p "your task description here" --output-format text -y
```

Key flags:
- `-p` — headless/non-interactive prompt
- `-y` — auto-approve all file edits (use for trusted project dirs only)
- `--output-format text` — clean text output (also: `json`, `stream-json`)
- `-m` — override model (e.g. `-m gemini-2.5-pro`)

### With stdin context

Pipe file content as additional context:

```bash
cat src/main.py | gemini -p "refactor this to use async/await" -y --output-format text
```

### Auto-edit mode (approves edits, prompts for shell commands)

```bash
gemini --approval-mode auto_edit -p "add error handling to all API calls" -y
```

### Resume a previous session

```bash
gemini --resume latest -p "continue where we left off"
gemini --list-sessions   # list available sessions
```

## Practical Patterns

### Fix a bug

```bash
cd ~/projects/myapp
gemini -p "There's a bug where X happens when Y. Find and fix it." -y --output-format text
```

### Generate code

```bash
cd ~/projects/myapp
gemini -p "Create a FastAPI endpoint at /health that returns {status: ok, uptime: <seconds>}" -y --output-format text
```

### Code review / analysis (read-only, no edits)

```bash
cd ~/projects/myapp
gemini --approval-mode plan -p "Review the auth logic in src/auth/ and identify security issues" --output-format text
```

### Capture structured output

```bash
cd ~/projects/myapp
gemini -p "List all functions in src/ with no docstrings. Output as JSON array." --output-format json
```

## Notes

- Always `cd` to the project directory before running — Gemini CLI operates in the cwd
- Free quota applies per Maxime's Google account; no cost for normal dev tasks
- Sessions stored under `~/.gemini/` — use `--resume` to continue long tasks
- For large tasks, `--output-format stream-json` streams progress in real time
- Only use `-y` on trusted project directories

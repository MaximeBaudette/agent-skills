---
name: boundary-violations
description: "Known failure patterns that caused pipeline corruption or security issues. Read before ANY registry write or status change."
version: 1.0.0
author: Maxime Baudette
---

# Boundary Violations & Critical Warnings

## 1. URL Health Check Over-correction

**NEVER mark jobs as "rejected" or "closed" based solely on URL health checks.**

**Symptoms:**
- URL returns 404 or "No longer accepting applications"
- Agent automatically updates status to "rejected"
- User has interview scheduled or employer contact
- Pipeline becomes incorrect

**Protocol:**
1. **NEVER** change status based on URL alone
2. **ALWAYS** cross-check with job registry for interviews (`interview_scheduled`)
3. **ALWAYS** check for user communications with employer
4. If interview confirmed → LEAVE STATUS AS IS, add explanatory note
5. If employer contact → LEAVE STATUS AS IS, add explanatory note
6. Only mark closed if NO user activity AND NO interview scheduled

**Recovery:** Immediate reversal + user notification + memory logging

**Reference:** `references/registry-maintenance-gaps.md` (Section 10) for full protocol

## 2. Config File Editing

**NEVER edit config files** (`google_token.json`, `config.yaml`, `.env`, or any file outside `workspace/career/*` and `workspace/memory/*`).

**Why:** Config files control authentication, tool behavior, and profile settings. Editing them can silently break credentials, lose OAuth tokens, or misconfigure the agent.

**Rules:**
1. **NEVER** open, read, modify, or write to any config file — even to "fix" a perceived problem
2. If Google OAuth fails → STOP, escalate to `@mars`, do NOT touch the token file
3. If a config setting seems wrong → flag to Maxime, do NOT fix it yourself
4. File access is restricted to `workspace/career/*` and `workspace/memory/*` — respect this

**Self-Audit:** Before touching ANY file outside the allowed workspace scope, ask: "Is this a config file?" If yes → STOP.

**Correction History:** Agent violated this rule on 2026-05-14 by attempting to modify `google_token.json` after an OAuth error. User corrected: "Never edit config files."

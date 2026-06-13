---
name: auth_recovery_pattern
description: Google OAuth token expiry / client secret missing recovery for career-operations email delivery
tags:
  - google-workspace
  - oauth
  - recovery
  - career
version: 1.1
author: Andy
---

# Google OAuth Recovery Pattern (Career Operations)

This documents the recurring Google OAuth failure pattern that blocks email delivery for career operations (job hunt digest, inbox monitoring, pipeline follow-ups).

## Symptoms

### S1. Token expired (standard)

```
error[auth]: Authentication failed: Failed to get token: Server error:
invalid_grant: Token has been expired or revoked.
```

The Google OAuth token at `~/.hermes/google_token.json` has expired and cannot auto-refresh.

### S2. Corrupted token JSON (missing `type` field)

The Google API client (`google.oauth2.credentials`) raises `ValueError` or
fails silently during `from_authorized_user_file()` because the JSON is missing
the required `"type": "authorized_user"` field.

This happens when the token file was manually created, migrated, or overwritten
without the `type` discriminator. The error typically looks like a generic
auth failure rather than an explicit "missing type" message, making it hard to
diagnose without inspecting the file directly.

### S3. Profile-relative token path mismatch

`google_api.py` resolves the token path relative to the active profile
directory, not from `~/.hermes/google_token.json`. This means:

- The script looks for the token at `~/.hermes/profiles/<profile>/google_token.json`
- A token may exist at the home path but be missing from the profile path,
  or vice versa
- If copies exist in both places, they can diverge — one may have the `type`
  field while the other doesn't
- The standalone `google_client_secret.json` may be missing, but the token
  itself may embed `client_id`/`client_secret` and still function — provided
  it has the `type` field and lives in the profile path

**Error signature:**
```
error[auth]: Authentication failed: Failed to parse authorized user credentials
from /home/mars/.hermes/profiles/career-manager/google_token.json: missing field `type`
```

The path in the error tells you which token file the script actually resolved
to. If it says `profiles/career-manager/google_token.json`, the script found
the profile-specific copy — fix that one.

## Diagnosis

Run these checks to determine the root cause:

### 1. Token expiry date

```python
import json, os
token_path = os.path.expanduser("~/.hermes/google_token.json")
if os.path.exists(token_path):
    with open(token_path) as f:
        data = json.load(f)
    print(f"Token expiry: {data.get('expiry', 'unknown')}")
    print(f"Has refresh_token: {'refresh_token' in data}")
else:
    print("TOKEN MISSING")
```

### 1.5 Token JSON structural integrity

```python
import json, os
token_path = os.path.expanduser("~/.hermes/google_token.json")
if os.path.exists(token_path):
    data = json.load(open(token_path))
    print(f"Has 'type' field: {'type' in data}")
    if 'type' in data:
        print(f"type = {data['type']}")
    print(f"Has 'refresh_token': {'refresh_token' in data}")
    print(f"Keys present: {list(data.keys())}")
else:
    print("TOKEN MISSING")
```

If the `type` field is missing, the Google API client cannot deserialize the
token. **Fix:** Add `"type": "authorized_user"` to the JSON, then re-test.

**Note:** The career-manager profile stores its token at a custom path
(`~/.hermes/profiles/career-manager/google_token.json`). Check both locations
when diagnosing a profile-specific failure.

### 1.6 Check both token locations (multi-path resolution)

When `google_api.py` errors with a path under `profiles/<name>/`, verify both
token file locations and their `type` fields:

```python
import json, os
locations = [
    os.path.expanduser("~/.hermes/google_token.json"),
    os.path.expanduser("~/.hermes/profiles/career-manager/google_token.json"),
]
for p in locations:
    if os.path.exists(p):
        data = json.load(open(p))
        print(f"EXISTS: {p}")
        print(f"  type={data.get('type', 'MISSING')}, expiry={data.get('expiry','?')[:19]}")
        print(f"  refresh_token={data.get('refresh_token', 'MISSING') is not None}")
    else:
        print(f"MISSING: {p}")
```

**Key insight:** The error message's file path tells you exactly which token
the script resolved to. Fix the file it's pointing at, not just the shared
home-directory token. Both locations may need the same `type` fix.

### 2. Client secret file

```python
secret_path = os.path.expanduser("~/.hermes/skills/productivity/google-workspace/google_client_secret.json")
print("Client secret:", "EXISTS" if os.path.exists(secret_path) else "MISSING")
```

If the client secret is missing, the token **cannot refresh** even if the expiry date hasn't been reached. This is the most likely root cause when a previously-working setup suddenly fails.

### 3. Auth check (lightweight)

```
python ${HERMES_HOME:-$HOME/.hermes}/skills/productivity/google-workspace/scripts/google_api.py gmail search "newer_than:1d" --max 1
```

Returns JSON array if healthy; raises auth error if expired/missing.

## Blocked Operations

When auth is down, these career pipeline steps are blocked:

| Operation | Affected Mission |
|---|---|
| Send job hunt digest email | Job Hunt Phase 4 |
| Check inbox for recruiter replies | Job Hunt Phase 5, Lead Tracking |
| Check Calendar for interview events | Lead Tracking Phase 4b |

## Escalation Path

1. **Do NOT attempt self-recovery** — per AGENTS.md HARD BLOCKS, Andy cannot re-auth Google Workspace.
2. **Output the exact diagnosis** to the user (token path, expiry, secret presence).
3. **Escalate to `@mars`** with:
   - The paths checked: `~/.hermes/google_token.json` and `~/.hermes/skills/productivity/google-workspace/google_client_secret.json`
   - The error message
   - Whether the client secret file is missing
4. **Do NOT proceed with the full search pipeline** if the mission involves email delivery. Output a brief summary of what's blocked and stop.

## Observed Occurrences

| Date | Token State | Client Secret | Impact |
|---|---|---|---|
| 2026-04-30 | Expired (Apr 30 10:47 UTC) | N/A | Blocked digest send after Phases 1-3 completed |
| 2026-05-05 | Missing `type` field | PRESENT | Token existed but lacked `type: authorized_user`; Google API client failed silently. Fixed by adding the field. |
| 2026-05-09 | Missing `type` field (profile-specific copy) | MISSING | Token at `profiles/career-manager/google_token.json` lacked `type` field; the shared token at `~/.hermes/google_token.json` had `type` but was ignored by profile-relative path resolution. `google_client_secret.json` also missing but token embedded credentials. |

## Expected Recovery

The fix requires @mars to:

1. **If client secret exists somewhere else**: Copy it back to `~/.hermes/skills/productivity/google-workspace/google_client_secret.json`
2. **If client secret is gone permanently**: Follow the google-workspace skill's setup steps (Steps 2-5 in its SKILL.md) to create new OAuth credentials and re-authorize
3. **If token just expired**: Delete `~/.hermes/google_token.json`, then re-run `setup.py --auth-url` → `setup.py --auth-code` flow
4. **If token is missing `type` field**: Check BOTH token locations
   (`~/.hermes/google_token.json` and
   `~/.hermes/profiles/career-manager/google_token.json`). The error message's
   file path tells you which one the script actually resolved to — fix that one
   by adding `"type": "authorized_user"`. This is a safe fix — the token itself
   is valid; the library just needs the discriminator field to deserialize it.
   No re-auth needed. If the shared `google_client_secret.json` is missing but
   the token already embeds `client_id`/`client_secret`, the token will still
   work after adding the `type` field — it just won't be able to refresh when
   it expires.

## Prevention

- Monitor token expiry before running email-dependent missions (handled by the Pre-Flight Dependency Checks section in career_job-seeking SKILL.md)
- A CRON job or heartbeat could alert if auth is down, but this is low priority — the Pre-Flight checks will catch it at mission start

# Gmail Search Patterns for Career Operations

`google_api.py` takes the **entire Gmail search query as a single quoted string argument**. Flags and operators after the search string are not supported.

## ✅ Correct Patterns

```bash
# All queries as one string:
python .../google_api.py gmail search "after:2026/05/25"
python .../google_api.py gmail search "intersect after:2026/05/25"
python .../google_api.py gmail search "from:tonya after:2026/05/01"
python .../google_api.py gmail search "is:inbox after:2026/05/25"
python .../google_api.py gmail search "subject:interview"
```

## ❌ INCORRECT (will fail with "unrecognized arguments")

```bash
# NEVER do this — query and filter as separate args:
python .../google_api.py gmail search "intersect" after:2026-05-20  # FAILS
python .../google_api.py gmail search after:2026-05-25             # FAILS
```

## Date Format

Gmail search uses **forward slashes** (`YYYY/MM/DD`) for date filters:

| Format | Works? |
|--------|--------|
| `after:2026/05/25` | ✅ Yes |
| `after:2026-05-25` | ❌ No (hyphens parsed as separate tokens) |
| `after:2026-05-25 is:inbox` | ❌ No |

## Common Career Queries

```bash
# Employer replies since last check
python .../google_api.py gmail search "after:2026/05/25 is:inbox"

# Specific company/contact
python .../google_api.py gmail search "intersect after:2026/05/20"

# Interview-related
python .../google_api.py gmail search "interview after:2026/05/01"

# Application confirmation / HR outreach
python .../google_api.py gmail search "application or thank you after:2026/05/01"
```

## Implementation Note

When interpolating `last_check` dates from memory or pipeline state, convert to `YYYY/MM/DD` format:
- Python: `datetime.now().strftime("after:%Y/%m/%d")`
- Not `%Y-%m-%d` (hyphens) — this will be parsed as separate arguments and fail.

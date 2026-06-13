---
name: kb-archiving-workflow
description: "How to archive durable career knowledge to the shared Prime Radiant KB."
version: 1.0.0
author: Maxime Baudette
---

# KB Archiving Workflow

**Detailed interview research, company intelligence, and technical specifications** should be archived to the KB for MARS curation.

## Workflow

1. **Identify archive-worthy content:** Company acquisition details, technical specifications, market context, research summaries (non-master pages).
2. **For owned master pages** (e.g. career/profile): use `kb_get_page` + `authoritative_push` (via knowledge-base skill) — server + encyclopedist handle nearly-verbatim + light edits.
3. **For other research/insights:** submit via `submit_artifact` / `kb_submit` (knowledge-base helper) to inbox for MARS compounding. Or use `kb_put_page` for small legacy.
4. **Tag in MEMORY.md:** Add brief `KB: <keywords>` (or `KB archived: <topic>` for inbox items).
5. **MARS handles curation:** Processes inbox/direct-pushes, organizes, cross-refs, commits.

## Archive-worthy Content Examples

- Company acquisition details and strategic context
- Multi-step technical procedures or workflows
- Research summaries and domain knowledge
- People (contacts, colleagues, industry relationships)
- Cross-domain insights connecting career, technical, and market factors

## Mirror in Memory

MEMORY.md should contain brief summary tags; detailed content lives in KB for discoverability and long-term reference.

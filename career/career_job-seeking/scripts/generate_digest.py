#!/usr/bin/env python3
"""
generate_digest.py — Weekly Job Hunt Digest Generator

Reads job_registry.json, writes a formatted digest to /tmp/digest_body.txt,
and can send the digest plus persist the success artifacts used by Andy's cron.
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import date
from pathlib import Path


DEFAULT_WORKSPACE_ROOT = Path("/home/mars/.hermes/profiles/career-manager/workspace")
GOOGLE_API = Path(
    "/home/mars/.hermes/profiles/career-manager/skills/productivity/google-workspace/scripts/google_api.py"
)
HERMES_PYTHON = Path("/home/mars/.hermes/hermes-agent/venv/bin/python3")
DEFAULT_RECIPIENT = "maxime+hireme@baudette.fr"
DEFAULT_FROM_HEADER = '"Andy" <maximes.butler@gmail.com>'
DEFAULT_EMAIL_TMP = Path("/tmp/digest_body.txt")
DEFAULT_STATS_TMP = Path("/tmp/digest_stats.json")
DEFAULT_POSTSCRIPT_TMP = Path("/tmp/digest_postscript.txt")

DECIDED_STATUSES = {"applied", "discarded", "passed", "closed"}

# Prefixes to strip from notes — these are enrichment/metadata lines,
# not the actual job information Maxime wants to see.
ENRICHMENT_PREFIXES = (
    "Salary enriched",
    "JD summary",
    "Verified active",
    "Closed:",
    "Notes enriched",
)

TIER_LABELS = {
    1: "OAKLAND / EAST BAY  (PRIMARY)",
    2: "BAY AREA  (SECONDARY)",
    3: "RELOCATION",
}


def registry_path(workspace_root: Path) -> Path:
    return workspace_root / "memory" / "job_registry.json"


def weekly_dir(workspace_root: Path) -> Path:
    return workspace_root / "memory" / "weekly"


def sent_flag_path(workspace_root: Path, run_date: date) -> Path:
    return weekly_dir(workspace_root) / f"{run_date.isoformat()}_digest_sent.flag"


def digest_thread_path(workspace_root: Path, run_date: date) -> Path:
    return weekly_dir(workspace_root) / f"{run_date.isoformat()}_digest_thread.json"


def load_registry(path: Path) -> dict:
    if not path.exists():
        return {"schema_version": "1.1", "last_id": 0, "offers": []}
    with path.open() as f:
        data = json.load(f)
    if isinstance(data, list):
        return {"schema_version": "1.0", "last_id": len(data), "offers": data}
    return data


def is_unreviewed(offer: dict) -> bool:
    if offer.get("maxime_score") is not None:
        return False
    if offer.get("status", "active") in DECIDED_STATUSES:
        return False
    return True


def clean_notes(raw_notes: str) -> str:
    """Strip enrichment/audit metadata lines from notes, leaving only job info.

    Removes lines that start with known enrichment prefixes (e.g. "Salary enriched
    2026-04-28: ...", "JD summary 2026-04-28: ...", "Verified active ...").
    For JD summary lines the actual summary content after the date/colon is kept.
    """
    if not raw_notes:
        return ""
    lines = raw_notes.split("\n")
    cleaned = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        is_enrichment = any(stripped.startswith(p) for p in ENRICHMENT_PREFIXES)
        if is_enrichment:
            # For JD summary lines, keep only the summary content
            # Format: "JD summary YYYY-MM-DD: summary content"
            if stripped.startswith("JD summary"):
                colon_idx = stripped.find(":", 11)  # find colon after "JD summary "
                if colon_idx > 0:
                    cleaned.append(stripped[colon_idx + 1:].strip())
            # All other enrichment lines are dropped entirely
            continue
        cleaned.append(stripped)
    return "\n".join(cleaned)


def format_offer(offer: dict) -> str:
    oid = offer.get("id", "N/A")
    title = offer.get("title", "Unknown Title")
    company = offer.get("company", "Unknown Company")
    location = offer.get("location", "Not disclosed")
    salary = offer.get("salary_range", "Not disclosed")
    match = offer.get("match_score", "N/A")
    raw_notes = offer.get("notes", "") or "New offer"
    url = offer.get("url", "N/A")

    notes = clean_notes(raw_notes)

    return (
        f"#{oid}  {title} @\n"
        f"{company}\n"
        f"  Location: {location}\n"
        f"  Match Score: {match}/10\n"
        f"  Salary: {salary}\n"
        f"  Notes: {notes}\n"
        f"URL: {url}\n"
        f"\u2014\u2014\u2014\n"
        f"#{oid}: SCORE:  \n"
        f"FEEDBACK: \n"
    )


def format_tier_section(tier_num: int, offers: list[dict], max_show: int | None = 3) -> str:
    label = TIER_LABELS.get(tier_num, f"TIER {tier_num}")
    separator = "=" * 50
    if not offers:
        return (
            f"{separator}\n"
            f"  TIER {tier_num} -- {label}\n"
            f"{separator}\n"
            f"  (no offers this week)\n"
        )

    display_offers = offers if max_show is None else offers[:max_show]

    lines = [
        separator,
        f"  TIER {tier_num} -- {label}",
        separator,
    ]
    for offer in display_offers:
        lines.append(format_offer(offer))
    return "\n".join(lines)


def load_postscript(postscript_tmp: Path | None) -> str:
    """Read the postscript file and return its content, or empty string."""
    if postscript_tmp is None or not postscript_tmp.exists():
        return ""
    postscript = postscript_tmp.read_text().strip()
    if not postscript:
        return ""
    return postscript


def build_digest(
    registry_data: dict,
    *,
    today: date,
    all_flag: bool = False,
    market_signals: str = "",
) -> tuple[str, int, int]:
    offers = registry_data.get("offers", [])
    unreviewed = [offer for offer in offers if is_unreviewed(offer)]

    def sort_key(offer: dict) -> tuple[int, str]:
        return (-offer.get("match_score", 0), offer.get("id", "999"))

    t1 = sorted([offer for offer in unreviewed if offer.get("tier") == 1], key=sort_key)
    t2 = sorted([offer for offer in unreviewed if offer.get("tier") == 2], key=sort_key)
    t3 = sorted([offer for offer in unreviewed if offer.get("tier") == 3], key=sort_key)

    total = len(offers)
    total_unreviewed = len(unreviewed)
    shortlisted = len([offer for offer in offers if (offer.get("maxime_score") or 0) >= 3])
    applied_count = len([offer for offer in offers if offer.get("status") == "applied" or offer.get("applied_date")])
    passed_discarded = len([offer for offer in offers if offer.get("status") in {"passed", "discarded"}])
    today_str = today.isoformat()
    new_this_week = len([offer for offer in offers if offer.get("discovered_date") == today_str])

    reg_t1 = len([offer for offer in offers if offer.get("tier") == 1])
    reg_t2 = len([offer for offer in offers if offer.get("tier") == 2])
    reg_t3 = len([offer for offer in offers if offer.get("tier") == 3])

    top_offer = t1[0] if t1 else t2[0] if t2 else t3[0] if t3 else None
    top_pick = (
        f"{top_offer.get('title', 'N/A')} @ {top_offer.get('company', 'N/A')} (#{top_offer.get('id', 'N/A')})"
        if top_offer
        else "None"
    )

    sections = [
        "Search Profile: Senior Power Systems Engineer, DER Integration, Grid Integration",
        "Oakland, Bay Area, Remote USA",
        "",
    ]
    if market_signals:
        sections.extend([
            market_signals,
            "",
        ])
    sections.extend([
        format_tier_section(1, t1, max_show=None if all_flag else 3),
        "",
        format_tier_section(2, t2, max_show=None if all_flag else 3),
        "",
        format_tier_section(3, t3, max_show=None if all_flag else 3),
        "",
        "-" * 50,
        "SUMMARY",
        f"  Tier 1 (Oakland / East Bay):  {reg_t1} offers in registry, top 3 shown",
        f"  Tier 2 (Bay Area):            {reg_t2} offers in registry, top 3 shown",
        f"  Tier 3 (Relocation):          {reg_t3} offers in registry, top 3 shown",
        f"  Top pick: {top_pick}",
        "",
        "REGISTRY STATS",
        f"  Total in registry   : {total} offers",
        f"  Tier 1 (Oakland/Remote): {reg_t1}   Tier 2 (Bay Area): {reg_t2}   Tier 3 (Relocation): {reg_t3}",
        f"  Awaiting your review: {total_unreviewed}",
        f"  Shortlisted (score>=3): {shortlisted}",
        f"  Applied             : {applied_count}",
        f"  Passed / discarded  : {passed_discarded}",
        f"  New this week       : {new_this_week}",
        "-" * 50,
        "=" * 50,
        "HOW TO REPLY",
        "=" * 50,
        "Only score the offers you have an opinion on --",
        "unscored offers will reappear next week.",
        "",
        "Score guide:",
        "  5  = Must apply ASAP  (Andy reminds you after 1 week if not applied)",
        "  3-4 = Should apply    -- added to shortlist",
        "  1-2 = Low priority, maybe someday",
        "  0  = Pass             (kept in registry, not surfaced again soon)",
        "  -1 = Discard permanently",
        "",
        "=" * 50,
        "Generated by Andy | Career Manager",
    ])

    return "\n".join(sections), total_unreviewed, new_this_week


def build_stats(*, run_date: date, unreviewed_count: int, new_this_week: int, body_path: Path) -> dict:
    subject = (
        f"Weekly Job Hunt - {run_date.strftime('%B')} {run_date.day:02d}, {run_date.year}"
        f" - {unreviewed_count} opportunities found"
    )
    return {
        "date": run_date.isoformat(),
        "unreviewed_count": unreviewed_count,
        "new_this_week": new_this_week,
        "subject": subject,
        "body_path": str(body_path),
        "should_send": unreviewed_count > 0,
    }


def write_debug_artifacts(*, body: str, stats: dict, email_tmp: Path, stats_tmp: Path) -> None:
    email_tmp.parent.mkdir(parents=True, exist_ok=True)
    stats_tmp.parent.mkdir(parents=True, exist_ok=True)
    email_tmp.write_text(body)
    stats_tmp.write_text(json.dumps(stats, indent=2))


def default_send_email(*, subject: str, body: str) -> dict:
    result = subprocess.run(
        [
            str(HERMES_PYTHON),
            str(GOOGLE_API),
            "gmail",
            "send",
            "--to",
            DEFAULT_RECIPIENT,
            "--subject",
            subject,
            "--body",
            body,
            "--from",
            DEFAULT_FROM_HEADER,
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "gmail send failed")

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError("gmail send returned non-JSON output") from exc

    if not payload.get("id"):
        raise RuntimeError("gmail send did not return a message id")
    return payload


def write_thread_metadata(
    *,
    workspace_root: Path,
    run_date: date,
    send_result: dict,
    recipient: str = DEFAULT_RECIPIENT,
) -> Path:
    thread_path = digest_thread_path(workspace_root, run_date)
    thread_path.parent.mkdir(parents=True, exist_ok=True)
    thread_path.write_text(
        json.dumps(
            {
                "date": run_date.isoformat(),
                "thread_id": send_result.get("threadId", ""),
                "message_id": send_result["id"],
                "sent_to": recipient,
            },
            indent=2,
        )
    )
    return thread_path


def run_digest_pipeline(
    *,
    workspace_root: Path = DEFAULT_WORKSPACE_ROOT,
    today: date | None = None,
    send_email=None,
    all_flag: bool = False,
    email_tmp: Path = DEFAULT_EMAIL_TMP,
    stats_tmp: Path = DEFAULT_STATS_TMP,
    postscript_tmp: Path | None = DEFAULT_POSTSCRIPT_TMP,
) -> dict:
    run_date = today or date.today()
    registry = load_registry(registry_path(workspace_root))
    market_signals = load_postscript(postscript_tmp)
    body, unreviewed_count, new_this_week = build_digest(
        registry, today=run_date, all_flag=all_flag, market_signals=market_signals
    )
    stats = build_stats(
        run_date=run_date,
        unreviewed_count=unreviewed_count,
        new_this_week=new_this_week,
        body_path=email_tmp,
    )
    write_debug_artifacts(body=body, stats=stats, email_tmp=email_tmp, stats_tmp=stats_tmp)

    if not stats["should_send"]:
        return {
            "status": "skipped_no_offers",
            "date": run_date.isoformat(),
            "subject": stats["subject"],
            "flag_written": False,
            "thread_path": None,
        }

    sender = send_email or default_send_email
    try:
        send_result = sender(subject=stats["subject"], body=body)
        if not isinstance(send_result, dict) or not send_result.get("id"):
            raise RuntimeError("send_email did not return a message id")
    except Exception as exc:
        return {
            "status": "email_failed",
            "date": run_date.isoformat(),
            "subject": stats["subject"],
            "flag_written": False,
            "error": str(exc),
        }

    flag_path = sent_flag_path(workspace_root, run_date)
    flag_path.parent.mkdir(parents=True, exist_ok=True)
    flag_path.write_text("")
    thread_path = write_thread_metadata(workspace_root=workspace_root, run_date=run_date, send_result=send_result)

    return {
        "status": "sent",
        "date": run_date.isoformat(),
        "subject": stats["subject"],
        "unreviewed_count": unreviewed_count,
        "new_this_week": new_this_week,
        "flag_written": True,
        "flag_path": str(flag_path),
        "thread_path": str(thread_path),
        "message_id": send_result["id"],
        "thread_id": send_result.get("threadId", ""),
    }


def main() -> None:
    result = run_digest_pipeline(all_flag="--all" in sys.argv)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()

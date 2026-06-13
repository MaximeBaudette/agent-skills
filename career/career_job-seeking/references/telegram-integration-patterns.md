# Telegram Integration Patterns for Job Access

## Purpose
Implement Telegram-integrated job access patterns for quick, actionable job hunt information delivery during active job hunt phases.

## Telegram Configuration

### Basic Setup
- **Chat ID:** 7002352930 (Maxime's home channel)
- **Thread behavior:** Use appropriate thread IDs for conversation context
- **Routing format:** `telegram:7002352930:[thread_id]` or `telegram:7002352930` for DMs

### Message Format Constraints
**CRITICAL:** Follow `references/cron-output-format.md` and communication preferences:
- **MAX 2 lines per item** — company + role + status/action needed only
- **NO salary, location, URLs, or detail keys** in outputs
- **SILENT if nothing actionable** — no pipeline health section unless thresholds breached
- **One-line TL;DR at top** if anything to report
- **NO stale item breakdowns** — just "⚠️ ~N stale items from last hunt" on one line

## Integration Patterns

### 1. Pipeline Status Requests
**Trigger:** "show pipeline", "what's my status?", "how's my job hunt going?"

**Response Pattern:**
```
Pipeline: 3 active, 1 interview scheduled
• Intersect Power: Power Systems Eng (applied 5d) → follow up Fri
• Tesla: Energy Storage Eng (interview Tue) → prep docs ready
```

**Implementation:**
1. Read `job_leads.json` for active/interview-scheduled items
2. Filter for items needing attention or high-interest
3. Format as ultra-concise bullet points
4. Send via Telegram with appropriate thread context

### 2. Lead Detail Access
**Trigger:** "tell me about #123", "what's up with Intersect Power?", "update on Tesla role"

**Response Pattern:**
```
Intersect Power: Power Systems Engineer
• Status: Applied (May 22) → follow up this week
• Next step: Technical interview prep
• Score: 4/5 (strong match)
```

**Implementation:**
1. Parse lead ID or company/role from request
2. Look up lead in `job_leads.json` and `job_registry.json`
3. Extract key details: status, next steps, score, timeline
4. Format as concise summary (2 lines max)
5. Send via Telegram with thread context

### 3. Interview Prep Access
**Trigger:** "interview prep for Tesla", "tell me about my Tuesday interview", "what should I prepare for?"

**Response Pattern:**
```
Tesla Energy Storage Eng interview (Tue)
• Focus: Grid-forming inverters, DER orchestration, safety protocols
• Questions: Team structure, deployment timeline, technical challenges
• Prep: STAR stories from grid stability projects
```

**Implementation:**
1. Identify interview from `job_leads.json` (interview_scheduled items)
2. Check for existing prep docs in `career/leads/YYYY-MM-company-role/`
3. Extract key focus areas, questions, and prep materials
4. Format as concise summary
5. Send via Telegram with appropriate timing (72h before interview)

### 4. Application Status Updates
**Trigger:** User asks about specific application status or timeline

**Response Pattern:**
```
Application Status:
• Intersect Power: Applied May 22 → waiting for response
• Tesla: Interview scheduled Tue May 28 → prep ready
• Google Cloud: High interest, not yet applied
```

**Implementation:**
1. Filter leads by status and recency
2. Group by status category (applied, interview, interest)
3. Format with timeline information
4. Include action items where needed

### 5. Proactive Reminders
**Trigger:** High-score leads not applied >7d, interviews approaching

**Response Pattern:**
```
⚠️ Action needed: 2 high-priority items
• Google Cloud: Energy Systems Eng (4/5) → apply by Fri
• Tesla: Interview prep review needed by Mon
```

**Implementation:**
1. Scan `job_leads.json` for high-score, unapplied leads
2. Check interview timelines for upcoming deadlines
3. Format as concise action items
4. Send via Telegram with urgency indicators

## Quality Standards

### Conciseness Rules
- **Absolute maximum:** 2 lines per item
- **No filler phrases:** Direct, actionable information only
- **No URLs/salary:** Protect privacy and follow preferences
- **Thread-aware:** Use context-appropriate thread IDs

### Timing Guidelines
- **Status requests:** Respond within 5 minutes
- **Interview prep:** Send 72h before scheduled interview
- **Reminders:** Send 24h before deadline, then daily until action
- **Proactive updates:** Only when genuinely actionable information

### Error Handling
- **Invalid lead references:** "No active lead found for [request]"
- **Missing information:** "Details pending for [lead] — check registry"
- **System errors:** "Pipeline check failed — retry in 5 min"

## Integration Points

### File Access Patterns
- **Leads:** `/home/mars/.hermes/profiles/career-manager/workspace/memory/job_leads.json`
- **Registry:** `/home/mars/.hermes/profiles/career-manager/workspace/memory/job_registry.json`
- **Prep docs:** `/home/mars/.hermes/profiles/career-manager/workspace/career/leads/YYYY-MM-company-role/`

### Message Routing
- **Primary channel:** Telegram chat ID 7002352930
- **Thread context:** Use conversation-appropriate thread IDs
- **Format consistency:** Follow all communication preferences exactly

## Automation Triggers
- **Job hunt completion:** Auto-send pipeline summary via Telegram
- **Interview scheduled:** Auto-send prep reminder 72h before
- **High-score lead:** Auto-reminder after 7 days unapplied
- **Pipeline staleness:** Auto-nudge after 14 days inactivity
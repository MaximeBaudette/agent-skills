# Daily Pollen Allergy Check Pitfalls & Workarounds (from 2026-05-10 cron run)

## Reverse Geocode (Step 0)
- **Pitfall:** `web_search query=\\\"reverse geocode lat lon city country\\\"` returns API docs, not location.
- **Workaround:** Use natural language: `web_search query=\\\"what city is latitude {lat} longitude {lon}\\\" num_results=5` or `\\\"{lat} {lon}\\\" city country`.
  - Example coords 47.4783,-1.7586 → \"Nantes, France\" (Nantes metro area).
- **Cron note:** `browser_navigate` fails (Camofox not running). Stick to search.
- **Alt:** web_extract `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat={lat}&lon={lon}` but may rate-limit/fail.

## Pollen Fetch (Step 1)
- **France-specific:** Dual English/French queries.
  - English: \"pollen levels {location} today\" → weather.com (High), pollen.com, accuweather.com.
  - French: \"niveaux de pollen {location} aujourd'hui\" → alert-pollen.com (Modéré), IQAir (icons: faible/low=🟢, modéré=🟠).
- **Synthesis:** ≥2 sources. Tree/Grass dominant May. Weeds/Ragweed none early season. Mold sparse (– or low).
  - Map: faible/low=🟢, modéré/moderate=🟠, élevé/high=🔴, très élevé/very high=🟠🔴.
- Sources used: pollencount.org (LOW tree), weather.com (High tree/grass), IQAir (Moderate), AccuWeather (descriptions).

## Log Append (Step 3)
- **Pitfall:** `read_file` prefixes lines: \"     1|[entry]\\n     2|\".
- **Code to clean/append:**
```python
content = '''PASTE read_file CONTENT HERE'''
lines = content.splitlines()
clean_lines = [line.split('|', 1)[1].strip() if '|' in line else line.strip() for line in lines]
log_content = '\\n\\n'.join(clean_lines)
new_entry = '[2026-05-10 08:00 PT | Nantes, France] Tree: moderate | Grass: low | Weeds: none | Mold: –'
new_content = log_content + '\\n\\n' + new_entry
print(new_content)  # copy to write_file
```
- Preserves empty lines between entries.

## Stray Logs
- Check: `search_files pattern=\\\"pollen_log.md\\\" path=\\\"/home/mars/.hermes/profiles/health-coach/\\\"`
- Canonical: `archive/pollen_log.md` only. Merge/dedupe chronologic if strays found, delete source.

# 2026-05-20 Cron Run Updates (Crescent City, CA)

## Reverse Geocode Refinement
- **Pitfall:** Even targeted queries like \"reverse geocode 41.864 -124.138\" or \"what city is at coordinates 41.8642 -124.1378\" return general API tutorials or unrelated results.
- **Workaround observed:** Fall back to approximate known location from coords (Crescent City / Del Norte County, CA area; near prior Eureka entry). Or chain 2-3 precise searches: \"41.864194 -124.137753 location\".
- Confirmed: Valid coords parsed correctly from maximes_location; no need for Oakland fallback.

## Pollen Data Fetch Adaptation
- **Pitfall:** `browser_navigate` consistently fails in cron/scheduled environments ("Cannot connect to Camofox at http://localhost:9377").
- **Primary workaround:** Use `web_extract` on authoritative pages (AccuWeather allergies-weather, pollen.com forecast) for markdown-structured allergen levels.
  - AccuWeather delivered clean table: Grass Low 🟢, Mold Low 🟢, Ragweed/Weeds Low 🟢; Tree inferred Low from context.
  - Supplemental: mypollenpal indicated Grass Moderate 🟠.
- Synthesis rule: Prioritize AccuWeather/Pollen.com for US locations; cross-check 2+ sources. Default to low/moderate in shoulder season (May) unless explicit high reported.
- Emoji mapping held: low=🟢, moderate=🟠.

## Execution Notes
- Location resolved to "Crescent City, CA" (consistent with device_tracker source).
- Log append used full-content read_file + write_file (no prefix artifacts after prior cleanup).
- Message format followed exactly; optional symptoms prompt included.
- No stray logs detected; canonical archive/ only.

## Tool Selection Lesson
- For static content pages (pollen, weather): Prefer `web_extract` over browser tools when running as cron or headless. Browser stack is unreliable outside interactive sessions.
- Always verify location first from maximes_location before assuming Oakland default.
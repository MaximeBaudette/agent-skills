# Reverse Geocoding for Health Missions

## Preferred Method for Location from Lat/Lon

Use Nominatim OpenStreetMap API via `web_extract` for reliable, free reverse geocoding without API keys.

1. Construct URL: `https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lon}&format=json` (e.g., lat=48.90035, lon=2.39512).

2. Call `web_extract urls=[\"{full_url}\"]` – returns JSON in content.

3. Parse JSON with `code_execution`:
   ```
   import json
   # Assume 'content' is the JSON string from web_extract results[0]['content']
   data = json.loads(content)
   town = data.get('address', {}).get('town') or data.get('address', {}).get('city') or data.get('address', {}).get('suburb', '') or data.get('address', {}).get('hamlet', '')
   country = data.get('address', {}).get('country', '')
   location_name = f\"{town}, {country}\" if town else f\"{data.get('display_name', '').split(',')[-1].strip()}, {country}\"  # Fallback to display_name parsing
   ```

4. If no town/city, fallback to `web_search query=\"city at {lat} {lon}\" num_results=3` and extract from titles/descriptions (e.g., \"Paris, France\" from results).

## Pitfalls
- Coordinates in suburbs (e.g., Pantin near Paris) may return suburb; for pollen, use parent city via additional search \"nearby major city to {location_name}\".
- Rate limit: Nominatim is 1 req/sec; fine for cron.
- International: Works globally, but sparse in rural areas – fallback to web_search.
- Evidence: Used successfully for 48.90035,2.39512 → \"Pantin, France\" on 2026-05-13.

## Example Code for Parsing
Save as snippet for reuse:
```
def parse_nominatim(json_str):
    import json
    data = json.loads(json_str)
    addr = data.get('address', {})
    places = [addr.get(k) for k in ['town', 'city', 'suburb', 'hamlet'] if addr.get(k)]
    town = places[0] if places else addr.get('road', '')  # Ultimate fallback
    country = addr.get('country', 'Unknown')
    return f\"{town}, {country}\" if town else data.get('display_name', '').rsplit(', ', 1)[-1]
```
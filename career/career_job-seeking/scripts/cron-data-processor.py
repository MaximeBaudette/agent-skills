#!/usr/bin/env python3
"""
Cron-safe data processing utilities for job registry maintenance.
Replaces execute_code which is blocked in cron mode.
"""

import json
import sys
from datetime import datetime, timedelta

def filter_active_offers(registry_data):
    """Filter offers with status=active"""
    return [o for o in registry_data["offers"] if o.get("status") == "active"]

def get_cadence(score):
    """Get verification cadence based on maxime_score"""
    if score is None:
        return 2  # null -> every 2d
    if score >= 4:
        return 1  # 4+ -> every 1d
    if score >= 2:
        return 7  # 2-3 -> every 7d
    if score >= 0:
        return 14  # 0-1 -> every 14d
    return None  # -1 -> never

def get_needs_verification(active_offers, today):
    """Get offers needing verification based on cadence"""
    needs_verification = []
    for o in active_offers:
        score = o.get("maxime_score")
        cadence = get_cadence(score)
        if cadence is None:
            continue  # skip -1
        
        lv = o.get("last_verified_date")
        if lv:
            try:
                lv_date = datetime.strptime(lv, "%Y-%m-%d")
            except:
                lv_date = None
        else:
            lv_date = None
        
        if lv_date is None:
            days_since = 999
        else:
            days_since = (today - lv_date).days
        
        if days_since >= cadence:
            needs_verification.append({
                "id": o["id"],
                "company": o["company"],
                "title": o["title"],
                "url": o.get("url"),
                "maxime_score": score,
                "cadence_days": cadence,
                "last_verified": lv,
                "days_since_verify": days_since,
                "salary_range": o.get("salary_range", "Not disclosed"),
                "notes": o.get("notes", "")
            })
    
    # Sort by cadence (lowest first), then by days_since (highest first)
    needs_verification.sort(key=lambda x: (x["cadence_days"], -x["days_since_verify"]))
    return needs_verification

def main():
    """Main entry point for cron data processing"""
    if len(sys.argv) < 2:
        print("Usage: python3 cron-data-processor.py <action>")
        sys.exit(1)
    
    action = sys.argv[1]
    
    # Load registry data
    try:
        with open("/home/mars/.hermes/profiles/career-manager/workspace/memory/job_registry.json", "r") as f:
            registry = json.load(f)
    except Exception as e:
        print(f"Error loading registry: {e}")
        sys.exit(1)
    
    today = datetime(2026, 6, 3)
    
    if action == "count-active":
        active_offers = filter_active_offers(registry)
        print(f"Active offers: {len(active_offers)}")
        
    elif action == "filter-needs-verification":
        active_offers = filter_active_offers(registry)
        needs_verification = get_needs_verification(active_offers, today)
        print(f"Needs verification: {len(needs_verification)}")
        for item in needs_verification[:20]:  # Limit to 20
            print(f"  #{item['id']} {item['company']} - score:{item['maxime_score']} cadence:{item['cadence_days']}d days_since:{item['days_since_verify']}d")
            
    elif action == "extract-urls":
        if len(sys.argv) < 3:
            print("Usage: python3 cron-data-processor.py extract-urls <id1,id2,id3>")
            sys.exit(1)
        
        ids = sys.argv[2].split(",")
        for offer in registry["offers"]:
            if offer.get("id") in ids:
                print(f"{offer['id']}: {offer.get('url', 'No URL')}")
                
    else:
        print(f"Unknown action: {action}")
        sys.exit(1)

if __name__ == "__main__":
    main()
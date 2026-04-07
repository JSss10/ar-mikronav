#!/usr/bin/env python3
"""
OSM Import Script - AR-Mikronavigation
Laedt Barrieren-Daten aus OpenStreetMap (Overpass API) fuer das Testgebiet
Altstadt Zuerich und schreibt sie in die Supabase barriers Tabelle.

Verwendung:
    python3 import_osm.py

Voraussetzungen:
    pip3 install requests supabase
"""

import os
import sys
import json
import requests
from datetime import datetime
from typing import Optional, List, Dict
from supabase import create_client, Client

# ============================================================
# KONFIGURATION
# ============================================================
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

# Testgebiet Altstadt Zuerich (Bounding Box)
BBOX = "47.369,8.539,47.375,8.547"

# Overpass API Endpoint
OVERPASS_URL = "https://overpass-api.de/api/interpreter"


# ============================================================
# DEFAULT-MAPPING (NFA-15: bei Unsicherheit eher warnen)
# ============================================================
KERB_HEIGHT_DEFAULTS = {
    "flush": 0,
    "lowered": 3,
    "raised": 8,
    "no": 0,
}

INCLINE_DEFAULT_PERCENT = 8.0


# ============================================================
# OVERPASS QUERY
# ============================================================
def build_overpass_query(bbox):
    return """
    [out:json][timeout:60];
    (
      way["highway"="steps"](""" + bbox + """);
      node["kerb"](""" + bbox + """);
      node["highway"="crossing"](""" + bbox + """);
      way["incline"](""" + bbox + """);
      way["surface"~"cobblestone|sett|gravel|sand|unhewn_cobblestone"](""" + bbox + """);
      way["width"](""" + bbox + """);
      way["wheelchair"="no"](""" + bbox + """);
      node["wheelchair"="no"](""" + bbox + """);
    );
    out body geom;
    """


def fetch_osm_data(query):
    print("Lade Daten aus Overpass API...")
    response = requests.post(OVERPASS_URL, data={"data": query}, timeout=120)
    response.raise_for_status()
    data = response.json()
    print("OK " + str(len(data.get('elements', []))) + " Elemente geladen")
    return data


# ============================================================
# DATEN-MAPPING: OSM -> barriers
# ============================================================
def parse_kerb(element):
    tags = element.get("tags", {})
    kerb_type = tags.get("kerb")
    if not kerb_type:
        return None
    
    if "kerb:height" in tags:
        try:
            height_str = tags["kerb:height"].replace("m", "").strip()
            height_cm = float(height_str) * 100
            value_source = "measured"
        except (ValueError, AttributeError):
            height_cm = KERB_HEIGHT_DEFAULTS.get(kerb_type, 0)
            value_source = "estimated"
    else:
        height_cm = KERB_HEIGHT_DEFAULTS.get(kerb_type, 0)
        value_source = "estimated"
    
    return {
        "type": "curb",
        "subtype": "kerb_" + kerb_type,
        "value": height_cm,
        "unit": "cm",
        "value_source": value_source,
        "lat": element.get("lat"),
        "lng": element.get("lon"),
    }


def parse_steps(element):
    tags = element.get("tags", {})
    if tags.get("highway") != "steps":
        return None
    
    step_count = tags.get("step_count")
    try:
        count = int(step_count) if step_count else None
    except ValueError:
        count = None
    
    geom = element.get("geometry", [])
    if not geom:
        return None
    
    return {
        "type": "steps",
        "subtype": None,
        "value": float(count) if count else None,
        "unit": "count",
        "value_source": "measured" if count else "estimated",
        "lat": geom[0]["lat"],
        "lng": geom[0]["lon"],
    }


def parse_incline(element):
    tags = element.get("tags", {})
    incline = tags.get("incline")
    if not incline:
        return None
    
    try:
        value = float(incline.replace("%", "").strip())
        value = abs(value)
        value_source = "measured"
    except (ValueError, AttributeError):
        value = INCLINE_DEFAULT_PERCENT
        value_source = "estimated"
    
    geom = element.get("geometry", [])
    if not geom:
        return None
    
    mid = len(geom) // 2
    return {
        "type": "incline",
        "subtype": None,
        "value": value,
        "unit": "percent",
        "value_source": value_source,
        "lat": geom[mid]["lat"],
        "lng": geom[mid]["lon"],
    }


def parse_surface(element):
    tags = element.get("tags", {})
    surface = tags.get("surface")
    if not surface or surface not in ["cobblestone", "sett", "gravel", "sand", "unhewn_cobblestone"]:
        return None
    
    geom = element.get("geometry", [])
    if not geom:
        return None
    
    mid = len(geom) // 2
    return {
        "type": "surface",
        "subtype": surface,
        "value": None,
        "unit": None,
        "value_source": "measured",
        "lat": geom[mid]["lat"],
        "lng": geom[mid]["lon"],
    }


def parse_narrow(element):
    tags = element.get("tags", {})
    width = tags.get("width")
    if not width:
        return None
    
    try:
        width_cm = float(width.replace("m", "").strip()) * 100
    except (ValueError, AttributeError):
        return None
    
    if width_cm > 200:
        return None
    
    geom = element.get("geometry", [])
    if not geom:
        return None
    
    mid = len(geom) // 2
    return {
        "type": "narrow",
        "subtype": None,
        "value": width_cm,
        "unit": "cm",
        "value_source": "measured",
        "lat": geom[mid]["lat"],
        "lng": geom[mid]["lon"],
    }


def osm_to_barriers(osm_data):
    barriers = []
    
    for element in osm_data.get("elements", []):
        parsers = [parse_kerb, parse_steps, parse_incline, parse_surface, parse_narrow]
        
        for parser in parsers:
            result = parser(element)
            if result and result.get("lat") and result.get("lng"):
                barriers.append({
                    "type": result["type"],
                    "subtype": result["subtype"],
                    "value": result["value"],
                    "unit": result["unit"],
                    "location": "POINT(" + str(result["lng"]) + " " + str(result["lat"]) + ")",
                    "value_source": result["value_source"],
                    "source": "osm",
                    "source_id": str(element.get("id", "")),
                    "source_tags": element.get("tags", {}),
                    "is_active": True,
                })
    
    return barriers


# ============================================================
# SUPABASE IMPORT
# ============================================================
def import_to_supabase(barriers):
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("WARNUNG: SUPABASE_URL und SUPABASE_SERVICE_KEY muessen als Env-Variablen gesetzt sein")
        sys.exit(1)
    
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("\nSchreibe " + str(len(barriers)) + " Barrieren in Supabase...")
    
    batch_size = 100
    for i in range(0, len(barriers), batch_size):
        batch = barriers[i:i + batch_size]
        try:
            result = supabase.table("barriers").insert(batch).execute()
            print("OK Batch " + str(i // batch_size + 1) + ": " + str(len(batch)) + " Eintraege")
        except Exception as e:
            print("FEHLER in Batch " + str(i // batch_size + 1) + ": " + str(e))
    
    print("\nOK Import abgeschlossen!")


# ============================================================
# MAIN
# ============================================================
def main():
    print("=" * 60)
    print("OSM Import - AR-Mikronavigation")
    print("Testgebiet: Altstadt Zuerich (" + BBOX + ")")
    print("=" * 60)
    
    query = build_overpass_query(BBOX)
    osm_data = fetch_osm_data(query)
    
    print("\nParse OSM-Daten...")
    barriers = osm_to_barriers(osm_data)
    
    type_counts = {}
    source_counts = {"measured": 0, "estimated": 0}
    for b in barriers:
        type_counts[b["type"]] = type_counts.get(b["type"], 0) + 1
        source_counts[b["value_source"]] = source_counts.get(b["value_source"], 0) + 1
    
    print("\nOK " + str(len(barriers)) + " Barrieren extrahiert:")
    for btype, count in type_counts.items():
        print("  - " + btype + ": " + str(count))
    print("\nDatenqualitaet:")
    print("  - measured: " + str(source_counts['measured']))
    print("  - estimated: " + str(source_counts['estimated']))
    
    backup_file = "barriers_osm_" + datetime.now().strftime('%Y%m%d_%H%M%S') + ".json"
    with open(backup_file, "w", encoding="utf-8") as f:
        json.dump(barriers, f, indent=2, ensure_ascii=False)
    print("\nOK Backup gespeichert: " + backup_file)
    
    confirm = input("\nIn Supabase importieren? (y/n): ")
    if confirm.lower() == "y":
        import_to_supabase(barriers)
    else:
        print("Import abgebrochen.")


if __name__ == "__main__":
    main()

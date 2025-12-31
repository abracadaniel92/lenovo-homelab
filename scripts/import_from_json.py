#!/usr/bin/env python3
"""
Import recipes from JSON to KitchenOwl database.
Run this INSIDE the KitchenOwl container.

Usage:
    docker cp parsed_recipes.json kitchenowl:/data/
    docker cp import_from_json.py kitchenowl:/data/
    docker exec kitchenowl python3 /data/import_from_json.py
"""
import sqlite3
import json
import re
from datetime import datetime

DB_PATH = "/data/database.db"
JSON_PATH = "/data/parsed_recipes.json"

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Get household ID
cursor.execute("SELECT id FROM household LIMIT 1")
result = cursor.fetchone()
if not result:
    print("ERROR: No household found")
    exit(1)
household_id = result[0]
now = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')

# Helper functions
def find_or_create_tag(name):
    cursor.execute("SELECT id FROM tag WHERE household_id = ? AND LOWER(name) = LOWER(?)", 
                   (household_id, name.strip()))
    result = cursor.fetchone()
    if result:
        return result[0]
    cursor.execute("INSERT INTO tag (name, household_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                   (name.strip(), household_id, now, now))
    conn.commit()
    return cursor.lastrowid

def find_or_create_item(name):
    name = name.strip()
    if not name or len(name) < 2:
        return None
    cursor.execute("SELECT id FROM item WHERE household_id = ? AND LOWER(name) = LOWER(?)", 
                   (household_id, name))
    result = cursor.fetchone()
    if result:
        return result[0]
    cursor.execute("INSERT INTO item (name, household_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                   (name, household_id, now, now))
    conn.commit()
    return cursor.lastrowid

# Load recipes
with open(JSON_PATH) as f:
    recipes = json.load(f)

print(f"Importing {len(recipes)} recipes...")

imported = 0
skipped = 0

for recipe in recipes:
    # Check if exists
    cursor.execute("SELECT id FROM recipe WHERE household_id = ? AND name = ?",
                   (household_id, recipe['name']))
    if cursor.fetchone():
        skipped += 1
        continue
    
    # Build description
    desc_parts = []
    if recipe.get('meal_type'):
        desc_parts.append(f"[{recipe['meal_type']}]")
    if recipe.get('workout_tag'):
        desc_parts.append(f"[{recipe['workout_tag']}]")
    if recipe.get('calories_info'):
        desc_parts.append(f"\n\n{recipe['calories_info']}")
    if recipe.get('instructions'):
        desc_parts.append(f"\n\n{recipe['instructions']}")
    
    description = ' '.join(desc_parts[:2]) + ''.join(desc_parts[2:])
    
    # Insert recipe
    cursor.execute("""
        INSERT INTO recipe (name, description, created_at, updated_at,
            household_id, visibility, server_curated, server_scrapes,
            suggestion_score, suggestion_rank)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (recipe['name'], description, now, now, household_id, 'PRIVATE', 0, 0, 0, 0))
    
    recipe_id = cursor.lastrowid
    
    # Add tags
    for tag_name in [recipe.get('workout_tag'), recipe.get('meal_type')]:
        if tag_name:
            tag_id = find_or_create_tag(tag_name)
            try:
                cursor.execute("INSERT INTO recipe_tags (recipe_id, tag_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                               (recipe_id, tag_id, now, now))
            except sqlite3.IntegrityError:
                pass  # Tag already linked
    
    # Add ingredients (filter out prep steps)
    prep_indicators = ['измешајте', 'мешајте', 'ставете', 'додајте', 'наредете', 'поделете',
        'сервирајте', 'оставете', 'печете', 'варете', 'пржете', 'загрејте',
        'исечете', 'сечете', 'излупете', 'исчистете', 'измијте',
        'во сад', 'во тава', 'во чинија', 'во рерна', 'на оган',
        'подготовка', 'припрема', 'приготви', 'минути', 'часа', 'секунди']
    
    added_items = set()  # Track items already added to this recipe
    
    for ing in recipe.get('ingredients', []):
        # Skip prep steps
        ing_lower = ing.lower()
        if any(p in ing_lower for p in prep_indicators) or len(ing) > 100:
            continue
        if ing.endswith(':') and len(ing) < 50:
            continue
        
        # Extract item name
        item_name = re.sub(r'^[\d\s\.\,\-/]+', '', ing)
        item_name = re.sub(r'^\d+[\-–/]\d+\s*', '', item_name)
        item_name = re.sub(r'^(г|гр|кг|мл|ml|l|лажица|лажици|чаша|канче|пола|малку|малу)\s+', '', item_name, flags=re.IGNORECASE)
        item_name = item_name.strip()
        if len(item_name) < 2:
            item_name = ing
        
        item_id = find_or_create_item(item_name)
        if item_id and item_id not in added_items:
            try:
                cursor.execute("""
                    INSERT INTO recipe_items (recipe_id, item_id, description, created_at, updated_at, optional)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (recipe_id, item_id, ing, now, now, 0))
                added_items.add(item_id)
            except sqlite3.IntegrityError:
                pass  # Item already linked
    
    conn.commit()
    imported += 1
    if imported % 50 == 0:
        print(f"  Imported {imported}...")

print(f"\n✅ DONE: Imported {imported}, Skipped {skipped}")


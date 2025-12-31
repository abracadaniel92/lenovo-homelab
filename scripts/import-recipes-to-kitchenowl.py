#!/usr/bin/env python3
"""
Import recipes from Word documents to KitchenOwl
Supports Macedonian language recipes

Format expected:
- Day marker: "Ден X: |Workout Name|"
- Meal type: "ПОЈАДОК:", "РУЧЕК:", "ВЕЧЕРА:", "УЖИНА:", etc.
- Recipe name follows meal type on same line
- "Состојки" section with ingredients (lines starting with – or -)
- "Начин на припрема" section with instructions
- "Калориска вредност" marks end of recipe (with calories/macros)

Usage:
    # Parse and output JSON (dry run)
    python3 import-recipes-to-kitchenowl.py /path/to/recipes.docx --dry-run
    
    # Import to KitchenOwl (must run inside container or with DB access)
    python3 import-recipes-to-kitchenowl.py /path/to/recipes.docx
"""

import os
import sys
import json
import re
from pathlib import Path
from datetime import datetime

try:
    from docx import Document
except ImportError:
    print("ERROR: python-docx not installed. Install with: pip install python-docx")
    sys.exit(1)


def parse_recipes_from_docx(doc_path):
    """
    Parse multiple recipes from a Word document.
    
    Returns list of recipe dicts with:
    - name: Recipe name
    - meal_type: ПОЈАДОК, РУЧЕК, ВЕЧЕРА, УЖИНА, etc.
    - workout_tag: Workout name from day marker
    - ingredients: List of ingredient strings
    - instructions: Preparation instructions
    - calories_info: Calorie/macro information
    """
    try:
        doc = Document(doc_path)
    except Exception as e:
        print(f"ERROR: Could not read {doc_path}: {e}")
        return []

    # Split paragraphs by internal newlines to get individual lines
    lines = []
    for para in doc.paragraphs:
        text = para.text.strip()
        if text:
            for line in text.split('\n'):
                line = line.strip()
                if line:
                    lines.append(line)
    
    if not lines:
        return []

    recipes = []
    current_recipe = None
    current_workout = None
    current_section = None  # 'ingredients', 'instructions', 'calories'
    
    # Simple snacks to skip (single fruit/food items that don't need a recipe)
    SKIP_SNACKS = {
        'банана', 'јаболко', 'портокал', 'мандарина', 'грозје', 'киви',
        'круша', 'праска', 'кајсија', 'слива', 'диња', 'лубеница',
        'јапонско јаболко', 'нар', 'смоква', 'боровинки', 'малини',
        'јагоди', 'цреши', 'вишни', 'ананас', '2 киви', '1 јаболко',
        '1 банана', '2 банани', 'протеинско пудингче', 
        'протеинско пудингче или ред црно чоколадо',
    }
    
    # Patterns
    day_pattern = re.compile(r'^Ден\s*\d+\s*:\s*\|([^|]+)\|', re.IGNORECASE)
    meal_pattern = re.compile(r'^(ПОЈАДОК|РУЧЕК|ВЕЧЕРА|УЖИНА|ДЕСЕРТ|СНЕК)\s*:\s*(.+)$', re.IGNORECASE)
    ingredients_pattern = re.compile(r'^(Состојки|Ингредиенти|Ingredients)', re.IGNORECASE)
    instructions_pattern = re.compile(r'^(Начин на припрема|Приготовка|Подготовка|Instructions)', re.IGNORECASE)
    calories_pattern = re.compile(r'^(Калориска вредност|Калории|Calories)', re.IGNORECASE)
    
    for line in lines:
        # Check for day marker with workout
        day_match = day_pattern.match(line)
        if day_match:
            current_workout = day_match.group(1).strip()
            continue
        
        # Check for meal type + recipe name
        meal_match = meal_pattern.match(line)
        if meal_match:
            # Save previous recipe if exists
            if current_recipe and current_recipe['name']:
                recipes.append(current_recipe)
            
            meal_type = meal_match.group(1).upper()
            recipe_name = meal_match.group(2).strip()
            
            # Skip simple snacks (single fruit/food items)
            if recipe_name.lower() in SKIP_SNACKS:
                print(f"  ⏭️  Skipping simple snack: {recipe_name}")
                current_recipe = None
                current_section = None
                continue
            
            current_recipe = {
                'name': recipe_name,
                'meal_type': meal_type,
                'workout_tag': current_workout,
                'ingredients': [],
                'instructions': '',
                'calories_info': ''
            }
            current_section = None
            continue
        
        # Check for section headers
        if ingredients_pattern.match(line):
            current_section = 'ingredients'
            continue
        
        if instructions_pattern.match(line):
            current_section = 'instructions'
            continue
        
        if calories_pattern.match(line):
            current_section = 'calories'
            continue
        
        # Process content based on current section
        if current_recipe:
            if current_section == 'ingredients':
                ingredient = line.strip()
                # Remove bullet point
                if ingredient.startswith('–') or ingredient.startswith('-'):
                    ingredient = ingredient[1:].strip()
                if ingredient and len(ingredient) > 1:
                    current_recipe['ingredients'].append(ingredient)
            
            elif current_section == 'instructions':
                if current_recipe['instructions']:
                    current_recipe['instructions'] += '\n' + line
                else:
                    current_recipe['instructions'] = line
            
            elif current_section == 'calories':
                # Calorie line - save and end recipe
                current_recipe['calories_info'] = line
                if current_recipe['name']:
                    recipes.append(current_recipe)
                current_recipe = None
                current_section = None
    
    # Don't forget the last recipe if not ended with calories
    if current_recipe and current_recipe['name']:
        recipes.append(current_recipe)
    
    return recipes


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    input_path = Path(sys.argv[1])
    dry_run = '--dry-run' in sys.argv
    
    if not input_path.exists():
        print(f"ERROR: Path does not exist: {input_path}")
        sys.exit(1)
    
    # Find Word documents
    if input_path.is_file():
        doc_files = [input_path]
    else:
        doc_files = list(input_path.glob("*.docx")) + list(input_path.glob("*.doc"))
    
    if not doc_files:
        print(f"ERROR: No Word documents found in {input_path}")
        sys.exit(1)
    
    print(f"Found {len(doc_files)} Word document(s)")
    
    all_recipes = []
    
    for doc_file in doc_files:
        print(f"\n{'='*50}")
        print(f"Processing: {doc_file.name}")
        print('='*50)
        
        recipes = parse_recipes_from_docx(doc_file)
        
        if not recipes:
            print("  No recipes found")
            continue
        
        print(f"  Found {len(recipes)} recipe(s)")
        
        for r in recipes:
            print(f"    - {r['name']} ({r.get('meal_type', 'N/A')}, {len(r['ingredients'])} ing)")
        
        all_recipes.extend(recipes)
    
    print(f"\n{'='*50}")
    print(f"Total: {len(all_recipes)} recipes parsed")
    print('='*50)
    
    if dry_run:
        # Output JSON
        output_file = '/tmp/parsed_recipes.json'
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(all_recipes, f, ensure_ascii=False, indent=2)
        print(f"\nDry run - saved to {output_file}")
        print("To import, copy to container and run import script:")
        print("  docker cp /tmp/parsed_recipes.json kitchenowl:/data/")
        print("  docker exec kitchenowl python3 /data/import_script.py")
        return
    
    # Import to database
    try:
        import sqlite3
    except ImportError:
        print("ERROR: sqlite3 not available")
        sys.exit(1)
    
    DB_PATH = "/data/database.db"  # Inside container
    if not os.path.exists(DB_PATH):
        # Try host path
        DB_PATH = "/mnt/ssd/docker-projects/kitchenowl/data/database.db"
    
    if not os.path.exists(DB_PATH):
        print(f"ERROR: Database not found. Run inside container or use --dry-run")
        sys.exit(1)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get household ID
    cursor.execute("SELECT id FROM household LIMIT 1")
    result = cursor.fetchone()
    if not result:
        print("ERROR: No household found. Create one in KitchenOwl first.")
        sys.exit(1)
    
    household_id = result[0]
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')
    
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
    
    imported = 0
    skipped = 0
    
    for recipe in all_recipes:
        # Check if exists
        cursor.execute("SELECT id FROM recipe WHERE household_id = ? AND name = ?",
                       (household_id, recipe['name']))
        if cursor.fetchone():
            print(f"  Skip (exists): {recipe['name']}")
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
                cursor.execute("INSERT INTO recipe_tags (recipe_id, tag_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                               (recipe_id, tag_id, now, now))
        
        # Add ingredients
        for ing in recipe['ingredients']:
            # Extract item name (remove quantities)
            item_name = re.sub(r'^[\d\s\.\,\-/]+', '', ing)
            item_name = re.sub(r'^\d+[\-–/]\d+\s*', '', item_name)
            item_name = re.sub(r'^(г|гр|кг|мл|ml|l|лажица|лажици|чаша|канче|пола|малку|малу)\s+', '', item_name, flags=re.IGNORECASE)
            item_name = item_name.strip()
            if len(item_name) < 2:
                item_name = ing
            
            item_id = find_or_create_item(item_name)
            if item_id:
                cursor.execute("""
                    INSERT INTO recipe_items (recipe_id, item_id, description, created_at, updated_at, optional)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (recipe_id, item_id, ing, now, now, 0))
        
        conn.commit()
        print(f"  ✅ {recipe['name']} ({len(recipe['ingredients'])} ingredients)")
        imported += 1
    
    conn.close()
    
    print(f"\n{'='*50}")
    print(f"IMPORT COMPLETE")
    print(f"  Imported: {imported}")
    print(f"  Skipped: {skipped}")
    print('='*50)


if __name__ == "__main__":
    main()

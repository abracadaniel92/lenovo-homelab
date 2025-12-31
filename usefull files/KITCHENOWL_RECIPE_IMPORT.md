# KitchenOwl Recipe Import Guide

## Overview

Import Macedonian Word documents (.docx) containing recipes into KitchenOwl.

**Features:**
- Parses multiple recipes from single documents
- Extracts meal types (ПОЈАДОК, РУЧЕК, ВЕЧЕРА, УЖИНА, СНЕК, ДЕСЕРТ)
- Extracts workout/day tags from "Ден X: |Workout Name|" patterns
- Filters out preparation steps from ingredients
- Skips simple snacks (банана, јаболко, etc.) to preserve images for real recipes
- Handles duplicates automatically

## Quick Import

### Step 1: Parse Documents to JSON
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"
python3 import-recipes-to-kitchenowl.py /path/to/documents/ --dry-run
```

### Step 2: Copy to Container
```bash
docker cp /tmp/parsed_recipes.json kitchenowl:/data/
docker cp /tmp/import_from_json.py kitchenowl:/data/
```

### Step 3: Import (Optional: Clear First)
```bash
# Clear existing recipes (optional)
docker exec kitchenowl python3 -c "
import sqlite3
conn = sqlite3.connect('/data/database.db')
cursor = conn.cursor()
cursor.execute('DELETE FROM recipe_items')
cursor.execute('DELETE FROM recipe_tags')
cursor.execute('DELETE FROM planner')
cursor.execute('DELETE FROM recipe')
conn.commit()
print('Cleared recipes')
"

# Run import
docker exec kitchenowl python3 /data/import_from_json.py
```

### Step 4: Restart
```bash
docker restart kitchenowl
```

## Document Format Expected

The parser expects Word documents with this structure:

```
Ден 1: |Military FIT|

ПОЈАДОК: Recipe Name Here
Состојки
– ingredient 1
– ingredient 2
Начин на припрема
Step 1...
Step 2...
Калориска вредност
Калории: 350kcal | Протеини: 25g | ...

УЖИНА: Another Recipe
...
```

## Skipped Items

The following simple snacks are automatically skipped:
- банана, јаболко, портокал, мандарина, грозје, киви
- круша, праска, кајсија, слива, диња, лубеница
- јапонско јаболко, нар, смоква, боровинки, малини
- јагоди, цреши, вишни, ананас
- протеинско пудингче (standalone)

## Filtered Ingredients

Lines containing these words are filtered out of ingredients:
- Preparation verbs: измешајте, ставете, додајте, печете, варете, пржете
- Location words: во сад, во тава, во рерна
- Time words: минути, часа, секунди
- Section headers: подготовка, припрема
- Lines longer than 100 characters
- Lines ending with `:` (sub-headers)

## Cleanup Commands

### Remove Bad Ingredients (Prep Steps)
```bash
docker exec kitchenowl python3 -c "
import sqlite3
import re
conn = sqlite3.connect('/data/database.db')
cursor = conn.cursor()

prep_indicators = ['измешајте', 'мешајте', 'ставете', 'додајте', 'наредете', 
    'поделете', 'сервирајте', 'оставете', 'печете', 'варете', 'пржете', 
    'загрејте', 'исечете', 'сечете', 'излупете', 'во сад', 'во тава', 
    'подготовка', 'припрема', 'минути', 'часа']

cursor.execute('SELECT recipe_id, item_id, description FROM recipe_items')
items = cursor.fetchall()
deleted = 0
for recipe_id, item_id, desc in items:
    desc_lower = desc.lower()
    if any(p in desc_lower for p in prep_indicators) or len(desc) > 100:
        cursor.execute('DELETE FROM recipe_items WHERE recipe_id = ? AND item_id = ?', 
                       (recipe_id, item_id))
        deleted += 1
conn.commit()
print(f'Removed {deleted} bad ingredients')
"
docker restart kitchenowl
```

### Remove Simple Snack Recipes
```bash
docker exec kitchenowl python3 -c "
import sqlite3
conn = sqlite3.connect('/data/database.db')
cursor = conn.cursor()

skip_snacks = ['банана', 'јаболко', 'портокал', 'мандарина', 'грозје', 'киви',
    'протеинско пудингче', 'детокс салата', 'јагоди', 'цреши', 'диња', 'лубеница']

cursor.execute('''
    SELECT r.id, r.name FROM recipe r
    LEFT JOIN recipe_items ri ON r.id = ri.recipe_id
    GROUP BY r.id HAVING COUNT(ri.item_id) <= 1
''')
for recipe_id, name in cursor.fetchall():
    if any(s in name.lower() for s in skip_snacks):
        cursor.execute('DELETE FROM recipe_items WHERE recipe_id = ?', (recipe_id,))
        cursor.execute('DELETE FROM recipe_tags WHERE recipe_id = ?', (recipe_id,))
        cursor.execute('DELETE FROM planner WHERE recipe_id = ?', (recipe_id,))
        cursor.execute('DELETE FROM recipe WHERE id = ?', (recipe_id,))
        print(f'Deleted: {name}')
conn.commit()
"
docker restart kitchenowl
```

## Database Location

- **Container path**: `/data/database.db`
- **Host path**: `/mnt/ssd/docker-projects/kitchenowl/data/database.db`

## Troubleshooting

### "attempt to write a readonly database"
Stop KitchenOwl first:
```bash
docker stop kitchenowl
# ... do operations ...
docker start kitchenowl
```

### Recipes not showing
Check visibility is set to 'PRIVATE' (uppercase):
```bash
docker exec kitchenowl python3 -c "
import sqlite3
conn = sqlite3.connect('/data/database.db')
cursor = conn.cursor()
cursor.execute(\"UPDATE recipe SET visibility = 'PRIVATE' WHERE visibility = 'private'\")
conn.commit()
print('Fixed visibility')
"
```

### Check recipe count
```bash
docker exec kitchenowl python3 -c "
import sqlite3
conn = sqlite3.connect('/data/database.db')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM recipe')
print(f'Total recipes: {cursor.fetchone()[0]}')
"
```

## Last Import Stats (Dec 31, 2025)

- **Documents processed**: 17 Word files
- **Total recipes imported**: 294
- **Ingredient links**: 2,373
- **Tags created**: 20 (workout types + meal types)
- **Unique items**: 2,770
- **Duplicates skipped**: 20
- **Simple snacks skipped**: ~30

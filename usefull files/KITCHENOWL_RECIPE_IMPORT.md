# KitchenOwl Recipe Import Guide

## Overview

Import Macedonian Word documents (.docx) containing recipes into KitchenOwl.

**Script location**: `scripts/import-recipes-to-kitchenowl.py`

**Features:**
- Parses multiple recipes from single documents
- Extracts meal types (ПОЈАДОК, РУЧЕК, ВЕЧЕРА, УЖИНА, СНЕК, ДЕСЕРТ)
- Extracts workout/day tags from "Ден X: |Workout Name|" patterns
- Separates spices from ingredients (moved to description)
- Captures vegan calorie variants (Калории ВЕГЕ)
- Skips simple snacks (банана, јаболко, etc.)
- Handles duplicates automatically

## Quick Import

### Full Import (Recommended)

```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"

# Import from a single document
python3 import-recipes-to-kitchenowl.py ~/Downloads/"Recipe Document.docx"

# Import from multiple documents
python3 import-recipes-to-kitchenowl.py ~/Downloads/*.docx

# Dry run (parse only, don't import)
python3 import-recipes-to-kitchenowl.py ~/Downloads/*.docx --dry-run
```

### Clear and Reimport

```bash
# Stop KitchenOwl first
cd /home/docker-projects/kitchenowl
docker compose stop kitchenowl

# Clear existing recipes
python3 << 'EOF'
import sqlite3
conn = sqlite3.connect('/home/docker-projects/kitchenowl/data/database.db')
cursor = conn.cursor()
cursor.execute("DELETE FROM recipe_tags")
cursor.execute("DELETE FROM recipe_items")
cursor.execute("DELETE FROM recipe")
conn.commit()
print("✅ Cleared all recipes")
conn.close()
EOF

# Reimport
cd "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"
python3 import-recipes-to-kitchenowl.py ~/Downloads/*.docx

# Restart KitchenOwl
cd /home/docker-projects/kitchenowl
docker compose start kitchenowl
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
Калории ВЕГЕ: 320kcal | Протеини: 20g | ...  (optional vegan variant)

УЖИНА: Another Recipe
...
```

## Recipe Structure in KitchenOwl

Each imported recipe has:
- **Name**: Recipe title (e.g., "ЈАЈЦА НА ТУРСКИ НАЧИН")
- **Items**: Ingredients list (spices excluded)
- **Description**: 
  - Preparation method
  - Spices section (if any)
  - Calorie info (regular + vegan variant if present)
- **Tags**: Meal type + workout day (e.g., "ПОЈАДОК", "Military FIT")

## Skipped Items

### Simple Snacks (Auto-skipped)
These are skipped to preserve image slots for real recipes:
- банана, јаболко, портокал, мандарина, грозје, киви
- круша, праска, кајсија, слива, диња, лубеница
- јапонско јаболко, нар, смоква, боровинки, малини
- јагоди, цреши, вишни, ананас
- протеинско пудингче (standalone)

### Spices (Moved to Description)
These are separated from ingredients:
- сол, бибер, куркума, кари, оригано
- цимет, ванила, какао, босилек
- мирудии, зачини

## Database Location

| Location | Path |
|----------|------|
| Container | `/data/database.db` |
| Host | `/home/docker-projects/kitchenowl/data/database.db` |

## Troubleshooting

### "attempt to write a readonly database"
Stop KitchenOwl first:
```bash
docker compose stop kitchenowl
# ... do operations ...
docker compose start kitchenowl
```

### Recipes not showing
Ensure visibility is 'PRIVATE' (uppercase):
```bash
python3 -c "
import sqlite3
conn = sqlite3.connect('/home/docker-projects/kitchenowl/data/database.db')
cursor = conn.cursor()
cursor.execute(\"UPDATE recipe SET visibility = 'PRIVATE' WHERE visibility = 'private'\")
conn.commit()
print('Fixed visibility')
"
```

### Check recipe count
```bash
python3 -c "
import sqlite3
conn = sqlite3.connect('/home/docker-projects/kitchenowl/data/database.db')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM recipe')
print(f'Total recipes: {cursor.fetchone()[0]}')
"
```

### View sample recipe
```bash
python3 -c "
import sqlite3
conn = sqlite3.connect('/home/docker-projects/kitchenowl/data/database.db')
cursor = conn.cursor()
cursor.execute('SELECT name, description FROM recipe LIMIT 1')
r = cursor.fetchone()
if r:
    print(f'Name: {r[0]}')
    print(f'Description: {r[1][:500]}...')
"
```

## Import Stats

| Metric | Value |
|--------|-------|
| Current recipes | 27 |
| Last import | January 2026 |
| Source docs | Word documents from Downloads |

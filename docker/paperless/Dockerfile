# Paperless upstream omits DATABASES["default"]["TIME_ZONE"], so Django always
# runs SET TIME ZONE "UTC" when USE_TZ is true — ignoring PAPERLESS_TIME_ZONE.
# Some PostgreSQL builds reject "UTC"; Etc/UTC works. Mirror env into DATABASES.
FROM ghcr.io/paperless-ngx/paperless-ngx:latest

USER root
RUN python3 - <<'PY'
from pathlib import Path

import re

# v2: settings.py + _parse_db_settings(); v3+: settings/__init__.py + parse_db_settings(DATA_DIR)
src = Path("/usr/src/paperless/src/paperless")
path = next(p for p in (src / "settings" / "__init__.py", src / "settings.py") if p.exists())
text = path.read_text()
if 'DATABASES["default"]["TIME_ZONE"]' in text:
    raise SystemExit(0)
m = re.search(r"^DATABASES = _?parse_db_settings\(.*\)\n", text, re.M)
if not m:
    raise SystemExit("patch anchor not found")
needle = m.group(0)

extra = needle + """
# Django DB backend uses DATABASES["default"]["TIME_ZONE"] for PostgreSQL SET TIME ZONE.
# If omitted, Django sends "UTC" regardless of global TIME_ZONE / PAPERLESS_TIME_ZONE.
if os.getenv("PAPERLESS_DBHOST"):
    DATABASES["default"]["TIME_ZONE"] = os.getenv("PAPERLESS_TIME_ZONE", "UTC")
"""
path.write_text(text.replace(needle, extra, 1))
PY

USER paperless

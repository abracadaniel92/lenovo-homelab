# Paperless upstream omits DATABASES["default"]["TIME_ZONE"], so Django always
# runs SET TIME ZONE "UTC" when USE_TZ is true — ignoring PAPERLESS_TIME_ZONE.
# Some PostgreSQL builds reject "UTC"; Etc/UTC works. Mirror env into DATABASES.
FROM ghcr.io/paperless-ngx/paperless-ngx:latest

USER root
RUN python3 - <<'PY'
from pathlib import Path

path = Path("/usr/src/paperless/src/paperless/settings.py")
text = path.read_text()
needle = "DATABASES = _parse_db_settings()\n"
if 'DATABASES["default"]["TIME_ZONE"]' in text:
    raise SystemExit(0)
if needle not in text:
    raise SystemExit("patch anchor not found")

extra = needle + """
# Django DB backend uses DATABASES["default"]["TIME_ZONE"] for PostgreSQL SET TIME ZONE.
# If omitted, Django sends "UTC" regardless of global TIME_ZONE / PAPERLESS_TIME_ZONE.
if os.getenv("PAPERLESS_DBHOST"):
    DATABASES["default"]["TIME_ZONE"] = os.getenv("PAPERLESS_TIME_ZONE", "UTC")
"""
path.write_text(text.replace(needle, extra, 1))
PY

USER paperless

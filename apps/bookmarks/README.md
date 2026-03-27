# Bookmarks → Mattermost

Flask app: POST a URL (and optional note) to a Mattermost webhook. Used for the "Mobile Bookmark → Slack" workflow (bookmarks.gmojsoski.com).

## Endpoints

- `GET /` – Health + simple HTML form to submit a bookmark.
- `POST /bookmark` – Submit a bookmark. Accepts **JSON** or **form** body.

### POST /bookmark

**JSON body (recommended):**
```json
{
  "url": "https://example.com/article",
  "note": "Optional description",
  "emoji": "🔗",
  "token": "your_secret_token"
}
```

**Form body:** `url`, `note`, `emoji`, `token` (same names).

**Accepted URL fields:** `url`, `link`, or `bookmark_url` (so clients using different names still work).

## Config (env)

| Variable | Required | Description |
|----------|----------|-------------|
| `MATTERMOST_WEBHOOK_URL` | Yes | Mattermost incoming webhook URL |
| `BOOKMARKS_SECRET_TOKEN` | If you want auth | Client must send matching `token` |

Set in `.env` in the app directory, or via systemd `EnvironmentFile`.

## Deploy (server)

```bash
# Copy from repo to app dir (adjust paths if your repo is elsewhere)
cp -r "Pi-version-control/apps/bookmarks/"* /mnt/ssd/apps/bookmarks/
# Or: /home/apps/bookmarks if that's your symlink target

# Ensure .env exists with MATTERMOST_WEBHOOK_URL and optionally BOOKMARKS_SECRET_TOKEN
# Restart service
sudo systemctl restart bookmarks.service
```

## Local run

```bash
cd apps/bookmarks
python3 -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
export MATTERMOST_WEBHOOK_URL=https://...
export BOOKMARKS_SECRET_TOKEN=your_token
python secure_slack_bookmarks.py
```

Open http://localhost:5000 and use the form, or `curl -X POST http://localhost:5000/bookmark -H "Content-Type: application/json" -d '{"url":"https://example.com","token":"your_token"}'`.

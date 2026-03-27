"""
Slack/ Mattermost Bookmarks - POST a URL (+ optional note) to a webhook.
Accepts JSON (any Content-Type), form data, query params, or raw URL body.
"""
from flask import Flask, request, jsonify, render_template_string
import requests
import os
import re
import sys
import json as json_mod

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

app = Flask(__name__)

MATTERMOST_WEBHOOK_URL = os.environ.get(
    "MATTERMOST_WEBHOOK_URL",
    os.environ.get("SLACK_WEBHOOK_URL", ""),
)
SECRET_TOKEN = os.environ.get("BOOKMARKS_SECRET_TOKEN", "")

URL_RE = re.compile(r"^https?://[^\s]+$", re.IGNORECASE)


def _is_valid_url(s):
    if not s or not isinstance(s, str):
        return False
    return bool(URL_RE.match(s.strip()))


def _get_input():
    """Extract (url, note, emoji, token) from any request format."""
    raw_body = request.get_data(as_text=True)

    print(f"[DEBUG] Content-Type: {request.content_type}", file=sys.stderr, flush=True)
    print(f"[DEBUG] Raw body: {raw_body[:500]!r}", file=sys.stderr, flush=True)

    # Try to parse JSON from body regardless of Content-Type
    json_data = None
    try:
        json_data = request.get_json(force=True, silent=True)
    except Exception:
        pass
    if not isinstance(json_data, dict):
        json_data = None

    # Also try manual parse in case Flask's parser fails
    if json_data is None and raw_body and raw_body.strip().startswith("{"):
        try:
            json_data = json_mod.loads(raw_body)
            if not isinstance(json_data, dict):
                json_data = None
        except Exception:
            pass

    print(f"[DEBUG] JSON parsed: {json_data}", file=sys.stderr, flush=True)
    print(f"[DEBUG] Form data: {dict(request.form) if request.form else 'EMPTY'}", file=sys.stderr, flush=True)
    print(f"[DEBUG] Query args: {dict(request.args) if request.args else 'EMPTY'}", file=sys.stderr, flush=True)

    # Merge all sources into one dict (JSON + form + query)
    data = {}
    if json_data:
        data.update(json_data)
    if request.form:
        data.update(request.form.to_dict(flat=True))
    if request.args:
        data.update(request.args.to_dict(flat=True))

    print(f"[DEBUG] Merged data: {data}", file=sys.stderr, flush=True)

    # Find URL: try known keys (case-insensitive), then any value that looks like a URL
    url = None
    for key in ("url", "URL", "Url", "link", "Link", "LINK",
                "bookmark_url", "Bookmark URL", "text", "Text",
                "content", "Content", "input", "Input", "Shortcut Input"):
        if key in data and data[key] not in (None, ""):
            url = str(data[key]).strip()
            break

    # Case-insensitive fallback
    if not url:
        for k, v in data.items():
            if isinstance(k, str) and k.lower() in ("url", "link", "text", "content", "input"):
                if v not in (None, ""):
                    url = str(v).strip()
                    break

    # Any value that looks like a URL
    if not url:
        for v in data.values():
            if isinstance(v, str) and _is_valid_url(v):
                url = v.strip()
                break

    # iOS Shortcuts bug: URL ends up as a dict KEY instead of a value
    if not url:
        for k in data.keys():
            if isinstance(k, str) and _is_valid_url(k):
                url = k.strip()
                break

    # Fallback: raw body IS the URL (plain text body)
    if not url and raw_body:
        stripped = raw_body.strip()
        if _is_valid_url(stripped):
            url = stripped
        elif "\n" not in stripped and "://" in stripped:
            for part in stripped.split():
                if _is_valid_url(part):
                    url = part
                    break

    note = ""
    emoji = "🔗"
    token = None
    for key in ("note", "Note", "description", "Description"):
        if key in data and data[key] not in (None, ""):
            note = str(data[key])
            break
    for key in ("emoji", "Emoji"):
        if key in data and data[key] not in (None, ""):
            emoji = str(data[key])
            break
    for key in ("token", "Token", "TOKEN"):
        if key in data and data[key] not in (None, ""):
            token = str(data[key])
            break

    print(f"[DEBUG] Result: url={url!r}, note={note!r}, token={'***' if token else None}", file=sys.stderr, flush=True)
    return url, note, emoji, token


@app.route("/")
def index():
    return render_template_string(INDEX_HTML), 200


@app.route("/bookmark", methods=["POST"])
def bookmark():
    url, note, emoji, token = _get_input()

    if not SECRET_TOKEN and not MATTERMOST_WEBHOOK_URL:
        return jsonify({"error": "Server misconfigured: missing webhook or token"}), 500

    if SECRET_TOKEN and token != SECRET_TOKEN:
        return jsonify({"error": "Unauthorized"}), 401

    if not url:
        return jsonify({"error": "URL is required"}), 400

    if not _is_valid_url(url):
        return jsonify({"error": "Invalid URL (use http:// or https://)"}), 400

    if not MATTERMOST_WEBHOOK_URL:
        return jsonify({"error": "Webhook not configured"}), 500

    message = f"{emoji} {note}\n{url}" if note else f"{emoji} {url}"

    try:
        resp = requests.post(
            MATTERMOST_WEBHOOK_URL,
            json={"text": message},
            timeout=10,
        )
        resp.raise_for_status()
        return jsonify({"status": "success"}), 200
    except requests.exceptions.RequestException as e:
        return jsonify({"error": str(e)}), 500


@app.route("/health")
def health():
    return jsonify({"status": "ok", "service": "bookmarks"}), 200


INDEX_HTML = """<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bookmarks</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 420px; margin: 2rem auto; padding: 0 1rem; }
    h1 { font-size: 1.25rem; }
    label { display: block; margin-top: 0.75rem; font-weight: 500; }
    input { width: 100%; padding: 0.5rem; margin-top: 0.25rem; box-sizing: border-box; }
    button { margin-top: 1rem; padding: 0.5rem 1rem; background: #0b5cff; color: white; border: none; border-radius: 6px; cursor: pointer; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .msg { margin-top: 1rem; padding: 0.5rem; border-radius: 6px; }
    .err { background: #fee; color: #c00; }
    .ok { background: #efe; color: #060; }
  </style>
</head>
<body>
  <h1>Bookmarks</h1>
  <form id="f">
    <label>URL <em>(required)</em></label>
    <input type="url" name="url" id="url" placeholder="https://..." required>
    <label>Note (optional)</label>
    <input type="text" name="note" id="note" placeholder="Short description">
    <label>Token</label>
    <input type="password" name="token" id="token" placeholder="Secret token">
    <button type="submit" id="btn">Send</button>
  </form>
  <div id="msg"></div>
  <script>
    document.getElementById("f").onsubmit = async function(e) {
      e.preventDefault();
      var btn = document.getElementById("btn"), msg = document.getElementById("msg");
      btn.disabled = true; msg.textContent = ""; msg.className = "";
      var u = document.getElementById("url").value.trim();
      if (!u) { msg.textContent = "URL is required"; msg.className = "msg err"; btn.disabled = false; return; }
      try {
        var r = await fetch("/bookmark", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ url: u, note: document.getElementById("note").value.trim(), token: document.getElementById("token").value || undefined })
        });
        var j = await r.json();
        msg.textContent = r.ok ? "Sent!" : (j.error || r.statusText);
        msg.className = r.ok ? "msg ok" : "msg err";
      } catch (err) { msg.textContent = err.message; msg.className = "msg err"; }
      btn.disabled = false;
    };
  </script>
</body>
</html>
"""

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

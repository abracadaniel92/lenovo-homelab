#!/usr/bin/env python3
"""Check every feed in feeds.opml still resolves and returns items.

Boards kill their RSS without warning (RemoteOK returned 410 Gone), and FreshRSS
shows a silent-but-empty feed the same as a quiet one. Run this when the jobs
category looks suspiciously calm. Exit 1 if anything is dead.

    python3 check-feeds.py
"""
import re
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"}
OPML = Path(__file__).with_name("feeds.opml")


def item_count(url):
    body = urllib.request.urlopen(
        urllib.request.Request(url, headers=UA), timeout=25
    ).read().decode("utf-8", "replace")
    # ponytail: regex, not a parse — several of these feeds carry undefined HTML
    # entities that strict XML rejects but FreshRSS's SimplePie happily eats.
    # Upgrade to lxml's recover mode only if a count ever looks wrong.
    return len(re.findall(r"<(item|entry)[\s>]", body))


def main():
    feeds = [
        (o.get("text"), o.get("xmlUrl"))
        for o in ET.parse(OPML).getroot().iter("outline")
        if o.get("xmlUrl")
    ]
    assert feeds, f"no feeds found in {OPML}"
    print(f"{len(feeds)} feeds in {OPML.name}\n")

    bad = []
    for name, url in feeds:
        err = None
        for _ in range(2):  # one retry: hnrss 502s intermittently
            try:
                n = item_count(url)
                print(f"  {'ok   ' if n else 'EMPTY'} {n:>4}  {name}")
                err = None if n else "returned 0 items"
                break
            except Exception as e:  # noqa: BLE001 — any failure is a dead feed
                err = str(e)
                time.sleep(2)
        if err:
            print(f"  FAIL       {name}: {err}")
            bad.append(name)

    print("\n" + ("all feeds live" if not bad else f"BROKEN: {', '.join(bad)}"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

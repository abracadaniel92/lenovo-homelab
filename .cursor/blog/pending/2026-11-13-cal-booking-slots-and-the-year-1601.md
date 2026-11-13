# Why my booking page replayed 425 years of daylight saving time

**Angle:** A self-hosted Cal.com booking page took 10-106 s to show free slots. Fixing the obvious cause (a slow Outlook feed) left 4 s, and a CPU profile traced that to Outlook timezone rules that start in 1601.

**Story beats:**
- Caddy access log pins it to one request: `slots/getSchedule` at 10.4 s and 106.7 s, everything else under 0.4 s
- 0% CPU and no DB queries while waiting = a network timeout; open sockets point at Microsoft. The Outlook ICS feed (480 KB) took ~100 s per download during a Microsoft slowdown, and Cal fetches it on every page load
- Fix 1: download once a day at 06:00, serve it from a busybox container on Cal's private Docker network (no published port, the feed holds private events), keep yesterday's copy if a download fails, ntfy alert if it is 48 h old
- Still 4 s, and flat whether you ask for 1 day or 2 months, at 100-165% CPU: so not waiting, not slot math
- CPU profile of the live Next.js server (`kill -USR1` + inspector): 3.4 of 4.3 s in ical.js recurrence iteration, from the ICS feed code
- Each recurring event alone expands in ~1 ms; the real cost is Cal building a new `ICAL.Timezone` per event, and Outlook's VTIMEZONE says `DTSTART:16010101`, so every event replays DST transitions from 1601
- Fix 2: one `sed` line moves the rule start to 2020. 5.2 s -> 0.83 s, offered slots identical (385/385, and 196/196 across the March 2027 DST switch)
- End result: 10-106 s -> ~1.1 s through the public URL

**Evidence:** lemongrab log 2026-11-13, both Cal.com entries; commits 7383278, 82faab4.

**Public check:** Leave out: the Outlook ICS feed URL, ntfy topic, internal IPs, Credential/SelectedCalendar IDs, and employer/Outlook calendar names.

**Outline:**
1. The symptom: a booking page that loads fast and then shows its calendar after 10 s, sometimes 106 s
2. Finding the one slow request in the Caddy log, and why 0% CPU means "waiting on someone"
3. Caching the Outlook feed safely: daily copy, private container, keep-last-good, staleness alert
4. The 4 s that did not depend on the date range, and profiling a live Next.js server
5. 1601: how Outlook timezones and a per-event `ICAL.Timezone` add up to 3.4 s, and the one-line fix
6. Proving it changed nothing: identical slots, including across DST

**Effort:** post

**Priority:** next

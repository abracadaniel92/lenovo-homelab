# Troubleshooting Log & Known Issues

This log documents specific issues encountered on the server and their fixes.

## [2026-09-26] B2 offsite: encrypted, on a systemd timer, and monitored

**Date:** 2026-09-26
**Action:** Implemented the fix specified in the "Backblaze offsite audit"
entry below, all three gaps, via a one-off setup script run by the user.
**Result:** ✅ **Offsite copies are now client-side encrypted, the sync alerts
on failure, and the health check watches B2 hourly.**

### 🔧 What changed

- **Gap 2 (encryption):** new rclone crypt remote `b2-crypt` over a NEW bucket
  `Goce-Lenovo-crypt` (standard filename + directory name encryption). Current
  files at `b2-crypt:current/`, superseded at `b2-crypt:superseded/YYYY-MM-DD`.
  Key lives only in goce's `~/.config/rclone/rclone.conf`; user saved an
  off-box copy.
- **Gap 1 (silent failure):** `sync-backups-to-b2.service` (`User=goce`,
  `OnFailure=notify-failure@%n.service`, `TimeoutStartSec=4h`) + `.timer`
  (03:00, `Persistent=true`). The `0 3 * * *` line was removed from goce's
  crontab (backup at `~/crontab.bak-*`). The script no longer uses sudo and
  exits non-zero on failure.
- **Monitoring:** `scripts/health.d/60-offsite-freshness.sh`, one recursive
  `rclone lsf` per run, alarms if a service's newest offsite copy is older than
  `MAX_AGE_HOURS` + 24h, or if B2 cannot be listed at all. It stays quiet until
  the timer is enabled. Self-check: `scripts/test-offsite-freshness.sh`.
- **Gap 3 (growth):** bucket lifecycle `daysFromHidingToDeleting=1` (every
  `--backup-dir` move leaves a hidden version, B2 otherwise keeps them
  forever); the sync script purges `superseded/` day folders older than 90
  days, by folder name, not file mtime.

Unit files are written by the setup script into `/etc/systemd/system/`, not
kept in `systemd/`.

### 💻 Commands

```bash
sudo bash /opt/homelab/scripts/setup-b2-encrypted-sync.sh
```

### ✅ Verification

- Round trip: `vaultwarden-20260926-020001.tar.gz` downloaded through
  `b2-crypt` is byte-identical (`cmp`) to the local archive
- Raw bucket listing contains no service names or `.tar.gz`
- `b2-crypt:current`: 478 objects, 469.7 MiB, includes the fixed
  `linkwarden-20260926-193030.tar.gz` (closes the audit's "Immediate note")
- Health check: `Offsite freshness: all services within their max age`
- `systemctl list-timers`: next run Sun 2026-09-27 03:00; `crontab -l` has no
  sync line

### ⏭️ Still open

- Old **plaintext** buckets `Goce-Lenovo` and `Goce-Lenovo-superseded` still
  exist as a fallback. Delete with `rclone purge` once the off-box key copy is
  confirmed. They still hold the readable TravelSync OAuth credentials.
- After the 2026-09-27 03:00 run: `systemctl status sync-backups-to-b2.service`
  should show `Result=success`.

### 📍 Files involved

- `scripts/sync-backups-to-b2.sh` → `/usr/local/bin/sync-backups-to-b2.sh`
- `scripts/setup-b2-encrypted-sync.sh` (new)
- `scripts/health.d/60-offsite-freshness.sh`, `scripts/test-offsite-freshness.sh` (new)
- `/etc/systemd/system/sync-backups-to-b2.{service,timer}` (new, live only)
- Docs: `common-commands.md`, `infrastructure-summary.md`, `backup-strategy.md`

**Status**: ✅ Implemented and verified. Old plaintext buckets pending deletion.

## [2026-09-26] Backblaze offsite audit: copies are good, but the sync can fail silently

**Date:** 2026-09-26
**Action:** Audited the B2 offsite copies: verified one end to end by
downloading and opening it, then checked how the sync is scheduled and
monitored.
**Result:** ⚠️ **Copies verified good. Monitoring is not.** The nightly sync is
a plain user cron, so a failure is silent and nothing checks the offsite copies
are current. **Fix specified below, NOT yet implemented.**

### ✅ What was verified (the good news)

Downloaded `vaultwarden-20260926-020001.tar.gz` from B2 and opened it:

```bash
rclone copy b2-backup:Goce-Lenovo/vaultwarden/vaultwarden-20260926-020001.tar.gz /tmp/b2test/
md5sum /tmp/b2test/<file> /mnt/ssd/backups/vaultwarden/<file>
```

- **md5 identical** to the local copy (`90a299e6...`)
- Extracts, `PRAGMA integrity_check` = ok, **603 ciphers**, newest entry
  `2026-09-25 12:58`, `rsa_key.pem` present
- `/var/log/rclone-sync.log` shows 03:00 runs completing successfully on
  2026-09-23, 24, 25 and 26
- All 5 services present in `b2-backup:Goce-Lenovo/`, 454 objects, 437 MiB

So the data that is up there is real and restorable.

### 🔍 Gap 1 (the important one): a failed sync is silent

`crontab -l` (user `goce`):

```
0 3 * * * /usr/local/bin/sync-backups-to-b2.sh
```

It is **not a systemd unit**, so the `notify-failure@.service` notifier
installed earlier today does not cover it. The script does capture the exit
code and log "completed with warnings", but nothing reads that log. There is no
`MAILTO` in `/etc/crontab` either.

Worse, **no `health.d/` module looks at B2 at all**. `50-backup-freshness.sh`
only checks local archives. So the offsite copy could stop updating and every
signal on the box would still read green. That is the same failure class as the
2026-01-28 outage: the thing that would report the problem is not watching.

### 🔍 Gap 2: nothing is encrypted before upload

`rclone config show b2-backup` reports `type = b2`, not `crypt`. Backblaze
encrypts at rest on their side, but the archives are uploaded as-is.

- **Vaultwarden is fine.** Ciphers are encrypted client-side and the key never
  leaves the user's devices, so the vault is opaque to Backblaze.
- **TravelSync is the concern.** Its archive contains `credentials.json` and
  `token.pickle`, which are live **Google OAuth credentials**, readable.
- Nextcloud database contents, and (as of today) Postgres role password hashes
  from the new globals dump, are also readable.

Judgement call, not an obvious bug. Client-side encryption adds a key that, if
lost, makes every offsite copy unrecoverable.

### 🔍 Gap 3: the superseded bucket grows forever

`Goce-Lenovo-superseded` (created 2026-09-25 when `--backup-dir` turned the
sync from a mirror into an archive) has no lifecycle rule. 6 objects /
3.1 MiB today, so not urgent, but unbounded.

### 📌 The fix that is needed

**1. Move the sync off cron onto a systemd timer** so it inherits the existing
failure notifier and becomes visible in `systemctl list-timers`.

- New `systemd/sync-backups-to-b2.service` + `.timer` (daily 03:00).
- Service needs `User=goce`: rclone's config lives in that user's home, which
  is why the current script wraps everything in `sudo -u goce`.
- Attach `OnFailure=notify-failure@%n.service`, the same way
  `repair-silent-failures.sh` step 4 does for the other units, and add it to
  that script's unit loop so it is idempotent.
- Remove the `0 3 * * *` line from the `goce` crontab in the same change, or
  the sync runs twice.

**2. Add `scripts/health.d/60-offsite-freshness.sh`**, modelled on
`50-backup-freshness.sh`: for each `backup.d/*.conf`, list the matching prefix
in `b2-backup:Goce-Lenovo/<service>/` and alarm if the newest object is older
than `MAX_AGE_HOURS` (plus a grace margin, since the offsite copy is by
definition behind the local one).

- Use `rclone lsjson --files-only` and read `ModTime`, rather than parsing
  `lsf` output.
- The health check runs as **root**, rclone config belongs to **goce**, so it
  must call `sudo -u goce rclone`.
- B2 list calls are class B transactions and cheap, but one listing per service
  per hour is still ~120 calls/day. Consider a single recursive `lsjson` of the
  bucket instead of one call per service.
- Leave a self-check next to `test-backup-freshness.sh`.

**3. Optional, decide separately:** an `rclone crypt` remote layered over
`b2-backup` for Gap 2, and a B2 lifecycle rule for Gap 3.

### ⚠️ Immediate note

The **Linkwarden copy in B2 is still the broken pre-fix archive** (no database)
until the 03:00 sync on 2026-09-27 uploads
`linkwarden-20260926-193030.tar.gz`. Confirm after that run:

```bash
sudo -u goce rclone lsf b2-backup:Goce-Lenovo/linkwarden/ | sort | tail -3
```

### 📍 Files involved

- `scripts/sync-backups-to-b2.sh` (and its deployed copy
  `/usr/local/bin/sync-backups-to-b2.sh`)
- `/var/log/rclone-sync.log`, `goce` crontab
- To create: `systemd/sync-backups-to-b2.{service,timer}`,
  `scripts/health.d/60-offsite-freshness.sh`

**Status**: ⚠️ Audit complete, copies proven good, **fix not implemented**.
Picked up from the CLI next session.

## [2026-09-26] Restore drills for all 5 services: Linkwarden had no database in its backups

**Date:** 2026-09-26
**Action:** Extended the restore drill from Vaultwarden to all five backed-up
services. Building it exposed two real defects, both fixed.
**Result:** ✅ **ALL 5 RESTORE DRILLS PASS.** Linkwarden backups had been
shipping with **no database at all** for ~8 months; fixed and re-run. Nextcloud
backups could not restore onto a fresh server; fixed and re-run.

### 🔍 Finding 1: Linkwarden backups contained no bookmarks (data loss risk)

`linkwarden.conf` listed `SUBDIRS="data pgdata meili_data"`, but:

- `pgdata` is `drwx------ 70 root`, and backups run as `goce`. tar could not
  read a single file inside it.
- `TAR_DIR` in `backup-engine.sh` ran **the same tar twice** with `2>/dev/null`
  and ended in `|| true`, so it could not fail.

Every archive therefore shipped `data/` and an empty shell of `meili_data/`,
and **no database**. Linkwarden keeps links, tags, collections and users in
Postgres, so a restore would have produced page snapshots with nothing pointing
at them. The archive was 16 MB, fresh, valid gzip, and passed the new `.ok`
verification, because the tar really was a valid tar. **This is precisely the
gap a restore drill exists to close.**

At the time of discovery the live DB held **7 bookmarks and 1 user**, none of
which were in any backup.

Tarring a live `pgdata` would have been wrong even if readable: it is a torn
copy of a running database. Switched to a new `PG_DUMP_AND_DIRS` type that runs
`pg_dump` through the container.

`meili_data` was dropped from the backup. Its `.mdb` files are root-owned and
were never really captured either, and it is a Meilisearch index derived from
the Postgres data, so it is rebuildable. Trade-off recorded in the conf: after
a restore, search may be empty until Linkwarden reindexes.

`TAR_DIR` now fails loudly. The duplicate retry and `|| true` are gone.

### 🔍 Finding 2: Nextcloud backups could not restore onto a fresh server

The drill loaded the dump into a clean Postgres and it aborted:

```
ERROR:  role "oc_contact@gmojsoski.com" does not exist
```

`pg_dump` emits `ALTER TABLE ... OWNER TO <role>` and `GRANT` for roles it
**never creates**; only `pg_dumpall --globals-only` carries role definitions.
The dump contained **0** `CREATE ROLE` statements while depending on 2 roles.

Restoring into the existing container would have worked, since the roles are
already there. Restoring after losing the machine, which is the case backups
exist for, would have failed until someone hand-created the roles.

Both Postgres backup types now capture a globals dump alongside, asserted
non-empty (`grep -q "CREATE ROLE"`). Applies to Nextcloud and Linkwarden.

### ✅ Implementation

| File | Change |
|---|---|
| `scripts/restore-drill.sh` | **New.** All 5 services, `restore-drill.sh [service]` |
| `scripts/restore-drill-vaultwarden.sh` | **Deleted**, superseded by the above |
| `scripts/backup-engine.sh` | New `PG_DUMP_AND_DIRS` type; `TAR_DIR` fails loudly; both PG types capture `pg_dumpall --globals-only` |
| `scripts/backup.d/linkwarden.conf` | `TAR_DIR` → `PG_DUMP_AND_DIRS`, dropped `pgdata`/`meili_data` |

Two bugs in the drill harness itself, both worth remembering:

- **`pg_isready` lies.** The official Postgres image runs initdb against a
  temporary server on the same socket, then restarts. `pg_isready` *and* a real
  `select 1` both answer yes against that temporary server, so the dump load
  died halfway with `connection to server on socket ... failed`. Fixed by
  waiting for the image's own `init process complete` log line first.
- Assertions were written `test && ok || bad`, which reports a false pass if
  `ok()` returns non-zero. Replaced with `want_*` if/else helpers.

### 🧪 Verification

```bash
bash scripts/restore-drill.sh     # ALL RESTORE DRILLS PASSED
```

```
vaultwarden  603 passwords restored, HTTP 200 in 2s, matches live
nextcloud    126 tables, 2 users, config.php has instanceid/passwordsalt/secret
travelsync   db integrity ok, credentials.json + token.pickle present
kitchenowl   integrity ok, 27 tables, alembic version present
linkwarden   7 bookmarks, 1 user, dump loads into a clean postgres
```

All 5 newest archives carry a `.ok` sidecar. `test-health-modules.sh` 11/11 and
`test-backup-freshness.sh` 7/7 still pass.

### 📝 Lessons learned

- **Three layers of verification caught none of this.** Archive-read-at-write,
  `.ok` sidecar and hourly freshness all passed a Linkwarden backup with no
  database. They check the container, not the contents. Only a restore checks
  the contents.
- **Error suppression is how backups die.** `2>/dev/null` plus `|| true` turned
  a total failure into a daily success for eight months. Same root shape as the
  2026-01-28 outage.
- **A backup that restores in place is not a backup that restores.** Nextcloud
  would have restored fine onto the existing server and failed on a new one.
  Test against a *clean* target or the test proves nothing.
- Permission mismatches are a recurring theme here: Nextcloud's `config.php`
  (2026-09-25), Linkwarden's `pgdata` and `meili_data` (today). Anything the
  `goce` user cannot read is silently absent unless asserted.

### 📌 Open items

1. **Linkwarden archives older than `linkwarden-20260926-192441.tar.gz` have no
   database** and should not be trusted. They age out under retention. The same
   applies to the B2 copies until the 03:00 sync runs.
2. Backup archives are mode 644 and now include Postgres role password hashes.
   Consistent with existing posture (the dumps already held user hashes), but
   worth tightening.
3. No drill for FreshRSS, which still has no `backup.d` conf at all.

### 📍 Files involved

- `scripts/restore-drill.sh`, `scripts/backup-engine.sh`,
  `scripts/backup.d/linkwarden.conf`
- Archives: `/mnt/ssd/backups/{vaultwarden,nextcloud,travelsync,kitchenowl,linkwarden}/`

**Status**: ✅ All five services proven restorable. Re-run after any upgrade to
one of them, and monthly otherwise.

## [2026-09-26] Proved the alert chain and the Vaultwarden backup actually work

**Date:** 2026-09-26
**Action:** Sent a live test alert through the real notification path, and ran
the first Vaultwarden restore drill. Saved the drill as
`scripts/restore-drill-vaultwarden.sh`.
**Result:** ✅ Both passed. Mattermost accepted the alert (HTTP 200), and the
newest backup restored into a working vault with **603 of 603 ciphers**.

### 🔍 Background

Everything in this repo alerts to one Mattermost webhook, and until today the
engine discarded the POST result, so nobody knew whether alerts arrived. The
log's last recorded send attempts were **failures in January** (HTTP 400, then
502) and nothing had sent since, because no alert condition had fired.

Backups had the same shape of doubt. `backup-engine.sh` now verifies each
archive as it writes it and `50-backup-freshness.sh` asserts the `.ok` sidecar
hourly, but **readable is not restorable.** Neither catches a backup missing
`rsa_key.pem`, or a schema the current image refuses to open. No one had ever
restored one.

### ✅ Implementation

1. **Test alert.** Sent through the engine's own `send_slack_notification`
   rather than `test-mattermost-webhook.sh`, so the thing proven is the path
   real alerts take, not a second copy of the logic. Returned 0 (HTTP 200).
2. **Restore drill.** Newest archive extracted to a temp dir, booted in a
   throwaway container, compared against live, then torn down.
3. Saved as `scripts/restore-drill-vaultwarden.sh`, safe to run on production:
   throwaway container name, temp data dir, port 8077, `trap` cleanup on
   `EXIT INT TERM`. Never touches the live container, its data dir, or 8082.

```bash
bash scripts/restore-drill-vaultwarden.sh
```

### 🧪 Verification

```
1. Extract        archive extracts, db.sqlite3 present, rsa_key.pem present
2. Contents       603 ciphers, 1 user, 8 folders, newest 2026-09-25 12:58
3. Boot           HTTP 200 after 2s, 0 errors in startup log
4. vs live        restored 603 / live 603, counts match
RESTORE DRILL PASSED
```

Live container confirmed still `Up 26 hours (healthy)` afterwards, temp dirs
removed, no leftover containers.

### 📝 Lessons learned

- **An untested backup is a hypothesis.** Three layers of verification were
  added today (archive read at write time, `.ok` sidecar, hourly freshness) and
  none of them would have caught a missing `rsa_key.pem`. Only restoring does.
- **`rsa_key.pem` is the quiet one.** The archive looks complete without it and
  restores to a vault that serves fine, but every session token and
  2FA-remember device is invalidated. It is asserted explicitly for that reason.
- **Test the real path, not a copy.** `test-mattermost-webhook.sh` exists, but
  passing it would only prove that script works. The engine's own function is
  what pages you at 3am.
- The January failures show this webhook **has** broken before. Delivery is now
  checked and logged (same-day fix), so the next failure is visible instead of
  silent.

### 📍 Files involved

- `scripts/restore-drill-vaultwarden.sh` (new)
- `scripts/health-check-engine.sh` (`send_slack_notification`, used as-is)
- Archive under test: `/mnt/ssd/backups/vaultwarden/vaultwarden-20260926-020001.tar.gz`

**Status**: ✅ Both chains proven end to end. Re-run the drill after any
Vaultwarden upgrade, and roughly monthly otherwise. The other four services
still have no restore drill.

## [2026-09-26] Audit of the health-check modular migration: the probe could not see 5xx

**Date:** 2026-09-26
**Action:** Audited every check in `enhanced-health-check.sh` (612 lines)
against `health-check-engine.sh` + its 6 modules, after the entry below found
that the one ported guard had kept its name and lost its behaviour. Fixed six
findings.
**Result:** ✅ **LIVE** (repo edits deploy via `/opt/homelab`).
`test-health-modules.sh` 11/11, `test-backup-freshness.sh` 7/7.

### 🔍 Finding 1: the HTTP probe reported 404 and 502 as healthy

`check_service_http()` in the engine was:

```bash
curl -s --connect-timeout "$timeout" "$url" > /dev/null
return $?
```

`curl` exits 0 for any response that arrives, so **only a refused connection
registered as down**. Measured against live Caddy:

| probe | actual | engine said | monolith said |
|---|---|---|---|
| Caddy root | 200 | HEALTHY | HEALTHY |
| Caddy 404 path | 404 | **HEALTHY** | down |
| closed port | 000 | down | down |

Caddy's documented failure mode here is serving 502s (entries 2026-01-04,
2026-01-06, 2026-01-08), so `10-caddy.sh`'s auto-restart **could never fire for
the outage it exists to fix**. Also affected TravelSync and Bookmarks in
`30-services.sh`. Now compares the status code, accepting 2xx/3xx.

### 🔍 Finding 2: a hung service hung the health check forever

The probe passed `--connect-timeout` but no `--max-time`, so a service that
accepted the connection and never answered made curl wait indefinitely. The
unit had `TimeoutStartUSec=infinity`. A hang is not a failure, so `OnFailure=`
never fires: the notifier installed yesterday could not have caught it. That is
a fresh silent-death path with the same signature as the eight-month outage.
Fixed at both layers: `--max-time` on the probe, `TimeoutStartSec=600` in the
drop-in.

### 🔍 Finding 3: alerts were sent without checking they arrived

The engine did `curl -s -X POST ... > /dev/null` and discarded the result, so a
rotated webhook or a Mattermost outage silenced every alert with no trace. The
monolith verifies HTTP 200 and body `ok`. The engine also built its JSON by
string interpolation, so one quote or backslash in a message produced invalid
JSON that Mattermost rejects, silently. `notify-unit-failure.sh` already used
`json.dumps` for exactly this reason. Both fixed.

### 🔍 Findings 4 and 5: two checks simply absent

`20-cloudflared.sh` **never checked cloudflared**, only whether gmojsoski.com
answered from outside. A dead tunnel was caught indirectly by the external
probe, whose response is to run the heavyweight `fix-external-access.sh`
instead of starting the container. The monolith restarts it directly. Restored.

No module checked the **Docker daemon**. The monolith starts it and waits.
Restored as `ensure_docker()`, with a bounded 15s wait rather than the
monolith's `until docker ps; do sleep 2; done`, which spins forever if the
daemon never returns and takes the health check with it.

### 🔍 Finding 6: backup integrity verification was never running

`verify-backups.sh` does `tar -tzf` integrity plus size sanity plus age. Its
only caller is the monolith, and `/var/log/backup-verification.log` **does not
exist**, so it has never run. `50-backup-freshness.sh` replaced it with
mtime-only.

**Not fixed by restoring the call.** That script hardcodes
`kitchenowl-*.tar.gz`, but KitchenOwl backups are `.db` (`TYPE="FILE"`), so
reviving it produces an immediate false "backup missing" alert, plus duplicate
age alerts on thresholds that conflict with `backup.d/*.conf`.

Implemented instead as the upgrade path `50-backup-freshness.sh` already named:
`backup-engine.sh` verifies the artifact it just wrote (`tar -tzf`, or
`PRAGMA integrity_check` for SQLite) and drops a `.ok` sidecar; the freshness
module reports any newest archive lacking one. Verification runs **before**
retention cleanup, so pruning can never run on the back of a failed backup,
which is how the 2026-09-25 Vaultwarden archives were lost. One pass over a
file just built, rather than re-reading every archive 24 times a day.

Backfilled across all existing archives: **18 verified, 0 corrupt.**

### ✅ Monolith empty-alert bug fixed too (same day, on request)

`enhanced-health-check.sh:490` had the identical `local` at top level, so
`make health` also sent the `@all` external-access alert empty. Fixed with the
user's explicit approval, which the file's READ-ONLY note requires.

Guarded structurally rather than by one more example-specific case:
`test-health-modules.sh` now scans **every** health script for `local` outside
a function, so a third instance cannot appear. Verified to flag lines 490 and
491 of the pre-fix file and stay silent on the fixed one.

22 pre-existing shellcheck warnings surfaced once the file was touched
(pre-commit only lints files a commit changes, and this one had not been
changed since the hook was added). Declared via a file-level directive rather
than swept: rewriting 22 lines of live recovery logic inside a change approved
for one bug is what the read-only rule exists to prevent. **7 of them are
SC2164**, `cd <dir>` with no `|| exit` immediately before
`docker compose restart`, so a missing directory means the restart runs in
whatever the current directory happens to be. That warrants its own pass.

### 📌 Three divergent copies of the health check

Found while checking whether the fix needed mirroring to `/usr/local/bin`:

| Copy | State |
|---|---|
| `scripts/enhanced-health-check.sh` | Current. What `make health` runs, so the fix is already live for that path |
| `/usr/local/bin/enhanced-health-check.sh` | **Stale, 2026-01-16.** Still carries the empty-alert bug. Nothing in systemd or cron invokes it |
| heredoc inside `scripts/permanent-auto-recovery.sh` | A third, older copy embedded in a one-shot installer that is not scheduled. Running it would overwrite `/usr/local/bin` with an ancient version |

Not deployed to `/usr/local/bin` on purpose: nothing executes that path any
more, and mirroring would keep three copies alive instead of resolving them.
CLAUDE.md still lists it as a hand-mirrored file. Consolidating needs a
decision, and deleting anything needs confirmation.

Also still open, all lower severity: no HTTP checks for Jellyfin (8096),
Nextcloud (8081), Linkwarden (8090) or Planning Poker (3000); no 80% disk
warning tier; memory and disk log nothing when healthy; the `:5000` conflict is
detected but not resolved where the monolith kills the squatting PID; per-hour
alert throttling was lost, so a sustained condition notifies every run; modules
share the engine's shell, so variables leak between them.

### 🧪 Verification

```bash
bash scripts/test-health-modules.sh     # 11/11
bash scripts/test-backup-freshness.sh   # 7/7
shellcheck scripts/health-check-engine.sh scripts/health.d/*.sh scripts/backup-engine.sh
```

Findings 1 and 6 were confirmed against the committed code before fixing: the
old probe calls a real 404 HEALTHY, and the old freshness module stays quiet
for an unverified archive. The probe assertions run against a throwaway
`python3 -m http.server` so they exercise real status codes.

## [2026-09-26] Review of the 2026-09-25 repair: two more checks that could never fire

**Date:** 2026-09-26
**Action:** Reviewed yesterday's automation repair. The repair itself verified
clean; the review found two guards inside the newly re-armed health check that
were incapable of reporting a failure.
**Result:** ✅ **LIVE** (repo edits deploy instantly via `/opt/homelab`).
Self-check `scripts/test-health-modules.sh`, 5/5 pass.

### ✅ Yesterday's repair verified

Independently re-checked, all confirmed: health check running hourly (all 6
modules), all 5 backups ran 02:00 today off the repaired cron, B2 sync ran 03:00
with `--backup-dir` and created the `Goce-Lenovo-superseded` bucket, freshness
self-check 6/6. The WAL fix is real: today's Vaultwarden archive holds **603
ciphers, newest `2026-09-25 12:58`, `integrity_check ok`, `rsa_key.pem`
present**, exact agreement with the live DB, against the 598/7-weeks-stale
archive the old `DOCKER_TAR` produced.

### 🔍 Finding 1: the tunnel 127.0.0.1 guard was a no-op

`check_config_integrity()` in `health-check-engine.sh` grep'd
`/etc/caddy/config.d/*.caddy`. **That path does not exist on the host** (Caddy's
configs live in the container and the repo), so the glob never matched, nothing
was ever logged, and the guard reported healthy by doing nothing. The invariant
it is supposed to protect (tunnel `service:` URLs must be `localhost:8080`,
never `127.0.0.1:8080`) was therefore unguarded in production.

The monolithic `enhanced-health-check.sh` still has the real version, pointed at
`~/.cloudflared/config.yml`. The modular rewrite kept the name and lost the
behaviour (`# Optional: Auto-fix logic can be added here`).

Now checks the cloudflared config. **Detect-and-alert, not the monolith's silent
`sed -i`**: that file is append-only/sacred, and an in-place edit does not take
effect until cloudflared restarts, so the quiet auto-fix left the running tunnel
broken while looking resolved. Live config verified clean (0 occurrences), so
the newly-live check starts quiet.

### 🔍 Finding 2: the @all outage alert was being sent empty

`health.d/20-cloudflared.sh` assigned its alert title and body with `local` at
module top level. Modules are `source`d at the engine's top level, not inside a
function, and bash refuses `local` there: it errors and assigns nothing. So the
single most critical alert in this homelab, external access down, pages
`@all`, went out **with an empty title and an empty body**. Dropped `local`.
Its `FIX_SCRIPT` path was also the literal space-containing repo path; routed
via `/opt/homelab`.

Both are the same shape as the 2026-01-28 outage and were re-armed by yesterday's
repair rather than introduced by it.

### 📍 Changes

| File | Change |
|---|---|
| `scripts/health-check-engine.sh` | `check_config_integrity` now checks `~/.cloudflared/config.yml`; header corrected (it claimed to be a staged refactor "NOT yet wired up in production" while being the production ExecStart) |
| `scripts/health.d/20-cloudflared.sh` | Dropped `local`; `FIX_SCRIPT` routed via `/opt/homelab` |
| `scripts/test-health-modules.sh` | **New.** 6 assertions covering both defects |
| `scripts/repair-silent-failures.sh` | `docker-containers-start.service` added to the `OnFailure=` loop; VERIFY now prints the run's actual log block instead of the hardcoded "should have fired for the 5 stale services", which was true on the first run and wrong on every re-run of a script that is meant to be idempotent |

Follow-up in the same session: `check_config_integrity` now logs a verdict on
the healthy path too. It was silent when passing, and in the log that is
indistinguishable from never having run, which is the exact ambiguity that hid
the 2026-01-28 outage for eight months. `50-backup-freshness.sh` already got
this right. Covered by the 6th assertion.

### 🧪 Verification

```bash
bash scripts/test-health-modules.sh          # PASS, 6/6
shellcheck -S error scripts/health-check-engine.sh scripts/health.d/20-cloudflared.sh
grep -c "127.0.0.1:8080" ~/.cloudflared/config.yml   # 0, guard starts quiet
```

Each assertion was confirmed to fail against the pre-fix code, not just pass
against the new code.

### 📌 Open items

1. **`docker-containers-start.service` drop-in is in the repo but NOT deployed.**
   Needs `sudo bash /opt/homelab/scripts/repair-silent-failures.sh` (idempotent).
   It is still in a `failed` state and is the only failing unit without a notifier.
2. **`make health` and the hourly timer run different scripts.** The Makefile
   runs `enhanced-health-check.sh` (612 lines), systemd runs
   `health-check-engine.sh` + 6 modules. Not yet ported, so not covered hourly:
   `check_caddyfile_integrity` (the gzip/mobile-download guard from 2026-01-08),
   `check_udp_buffers`, the docker-daemon check, HTTP checks for Jellyfin /
   Nextcloud / Linkwarden, the 80% disk warning tier, and per-hour alert
   throttling. Deliberately NOT "fixed" by repointing the Makefile: that would
   have reduced what a human sees rather than increasing what runs hourly.
   Finding 1 suggests the rest of the port needs auditing for the same
   name-kept-behaviour-lost defect, not just completing.
3. `Goce-Lenovo-superseded` has no lifecycle rule: a new dated folder daily,
   forever. 3.1 MiB / 6 objects today, so not urgent.
4. FreshRSS still has no `backup.d/*.conf` (carried over from yesterday). Newest
   archive 2026-08-16, 41 days old, and invisible to the freshness alarm.

## [2026-09-25] A space in the repo path silently killed health checks, backups and auto-recovery for 8 months

**Date:** 2026-09-25
**Action:** Repaired the automation layer via `scripts/repair-silent-failures.sh`,
introduced a space-free `/opt/homelab` path, and moved failure alerting
out-of-band so the next silent death is loud.
**Result:** ✅ **LIVE.** Health check running hourly again, all 5 backups
verified fresh, auto-recovery re-armed (it restarted `gokapi` on its first run).

### 🔍 Symptom

No symptom. That is the finding. Nothing alerted, nothing appeared broken, and
`systemctl list-timers` showed a recent `LAST` timestamp for
`enhanced-health-check.timer`, which read as healthy. The unit was firing on
schedule and failing instantly every time.

Discovered incidentally while verifying a Vaultwarden backup (entry below): the
"latest" archive was dated 2026-01-28.

### 🔍 Root cause

The repo lives at `/home/goce/Desktop/Cursor projects/Pi-version-control`.
**That path contains a space.** Every unquoted reference to it stopped
resolving, and because several callers were written at different times against
the same unquoted path, they all died within days of each other:

| System | Failure | Dead since |
|---|---|---|
| `enhanced-health-check.service` (+ Caddy/cloudflared auto-recovery) | `203/EXEC` hourly | 2026-01-28 |
| Backup cron, all 5 services | never executed | 2026-01-17 |
| `healthcheck-watchdog.sh` (5-min root cron) | file does not exist | unknown |
| Watchtower, all 36 containers | panics nightly, cannot reach docker daemon | 2026-03-27 |
| `docker-containers-start.service` | `203/EXEC` | 2026-09-07 |
| `slack-goatcounter-weekly.service` | exit 3 | 2026-09-20 |

Smoking gun: a **zero-byte file `/home/goce/Desktop/Cursor` dated 2026-01-17**.
Cron split the backup line on the space, so the `>>` redirect target became the
bare word `/home/goce/Desktop/Cursor` and cron created it.

**The design flaw that hid it for 8 months:** every alert in this homelab was
emitted *by* `health-check-engine.sh`. When that script stopped executing, the
component responsible for reporting outages was itself the outage. A monitor
that can only report failures it survives is not a monitor.

### 🔧 Changes

Live and repo, via `sudo bash scripts/repair-silent-failures.sh` (idempotent):

1. **`/opt/homelab` → symlink to the repo.** Space-free path; everything now
   points through it so this bug class cannot recur.
2. **`notify-failure@.service`** installed, attached via `OnFailure=` drop-ins to
   `enhanced-health-check`, `hdd-health-check`, `slack-goatcounter-weekly`,
   `portfolio-update`. systemd fires `OnFailure=` even when `ExecStart` never
   got off the ground, which is precisely the failure mode that hid this one.
3. **Health check `ExecStart` fixed via drop-in**, resetting `ExecStart=` first
   so systemd replaces rather than appends. The original unit file was not
   edited (`systemd/` is read-only core per CLAUDE.md).
4. **`/etc/crontab` backed up and rewritten** through `/opt/homelab`; dead
   `healthcheck-watchdog.sh` line removed.
5. **`scripts/health.d/50-backup-freshness.sh`** (new): alarms when any service's
   newest backup exceeds `MAX_AGE_HOURS`. Self-check:
   `scripts/test-backup-freshness.sh`, 6/6 pass.
6. **`scripts/backup-all-critical.sh`**: dropped `set -e`, which had been
   aborting the run after the *first* service, so 4 of 5 were skipped even when
   cron did fire. Now collects failures and exits non-zero so `OnFailure=` fires.
7. **`scripts/sync-backups-to-b2.sh`**: added `--backup-dir`. Offsite was a
   mirror, so any local deletion or truncation propagated to B2 within 24 hours
   and destroyed the only offsite copy. It is now an archive.
8. **Nextcloud config backup fixed.** `config.php` is `640 www-data:www-data`
   and backups run as `goce`, so the host-side `tar` failed every night, was
   swallowed by `2>/dev/null`, and shipped a 45-byte empty archive with exit 0.
   The engine now reads it through the container (`CONFIG_CONTAINER`) and
   **hard-fails if the archive does not contain the file**. Without
   `passwordsalt`/`secret`/`instanceid` a restored instance cannot decrypt
   anything, so an empty config archive is a failed backup, not a warning.

### ✅ Verification

```bash
systemctl show -p Result --value enhanced-health-check.service   # success
systemctl list-timers enhanced-health-check.timer                # next fire scheduled
grep backup-all-critical /etc/crontab                            # routed via /opt/homelab
tail -20 /var/log/enhanced-health-check.log                      # all 6 modules executed
```

- First run executed all 6 modules and **auto-recovered `gokapi`**, which had
  been down with nobody watching.
- Freshness alarm fired on first run naming exactly the 4 stale services, and
  correctly omitted Vaultwarden (backed up earlier the same day). It went quiet
  after all 5 were re-run.
- Nextcloud config archive: 906 bytes, contains `config.php`, all three of
  `instanceid` / `passwordsalt` / `secret` present.
- KitchenOwl now takes an online SQLite snapshot instead of a live `cp`.

### 📌 Open items

1. **Watchtower removed** 2026-09-25, repo and server. See below. ✅ Closed.
2. `docker-containers-start.service` (`203/EXEC`) and the missing
   `healthcheck-watchdog.sh` still need real diagnosis. Deliberately not
   bundled into the repair script.
3. `/mnt/ssd/backups/freshrss/` has archives but **no `backup.d/*.conf`**, so it
   is outside both the backup run and the freshness alarm. Newest is 2026-08-16.
4. The freshness alarm checks **mtime only**. A backup that runs and produces
   garbage still reads as fresh. Upgrade path: a `.ok` sidecar written after a
   content assertion. The Nextcloud fix in change 8 is the pattern to follow.

### 🗑️ Watchtower removed

Third instance of the same theme in one day: `docker ps` reported Watchtower as
**`Up 2 weeks (healthy)`**. The healthcheck only proves the process is alive.
The scheduled update job panicked inside a goroutine that `robfig/cron` recovers,
so the container stayed up and green while doing nothing. Last completed run:
`Session done Failed=0 Scanned=32 Updated=1` on **2026-03-27**.

`containrrr/watchtower` 1.7.1 is unmaintained and predates Docker Engine 29.8.1
(API 1.56). Rather than pin an API version to keep an abandoned image talking to
a modern daemon, it was removed. It held a **root docker socket on the host
running the password manager**, which is a poor trade for an updater that had
not updated anything in six months.

Replacement: **Renovate** (already configured) opens PRs for image bumps, and
tags get pinned so updates are reviewed rather than applied silently at 2 AM.
Nothing regressed, because nothing had been updating.

Repo side: `docker/watchtower/` deleted, README service-table row removed (with
explicit user approval, that table is append-only), `make update` converted to a
signpost. `com.centurylinklabs.watchtower.*` labels left in place on other
services: they are inert with no Watchtower running, and removing them would
touch several unrelated services' compose files for no behavioural gain.

**Server side: done 2026-09-25.**

```bash
cd /mnt/ssd/docker-projects/watchtower && docker compose down
rm -rf /mnt/ssd/docker-projects/watchtower /home/docker-projects/watchtower
```

(The two live dirs held only a `docker-compose.yml`, no data. The copy under
`/home/docker-projects/` was a stale duplicate.)

Verified after teardown: container and both dirs gone, 35 containers running
(36 minus Watchtower), no service disrupted. The
`com.centurylinklabs.watchtower.*` labels left on other services are inert.

### 📝 Lessons learned

1. **A monitor that can only report failures it survives is not a monitor.**
   Every alert here was emitted *by* `health-check-engine.sh`. When that stopped
   executing, the reporter and the outage were the same component. `OnFailure=`
   fires even when `ExecStart` never got off the ground, which is exactly the
   case that was invisible. Alerting must be out-of-band from the thing it
   watches.

2. **"Green" is not "working". Check the function, not the process.** Three
   separate systems in one day reported healthy while doing nothing:
   `systemctl list-timers` showed a recent `LAST` for a unit failing instantly
   on every fire; `docker ps` showed Watchtower `Up 2 weeks (healthy)` while its
   job panicked in a recovered goroutine; the Nextcloud backup exited 0 while
   shipping an empty config archive. Liveness checks measure the wrapper.

3. **`|| log "warning"` on a failed command is a silent failure.** The Nextcloud
   config tar failed every night for eight months behind `2>/dev/null` and a
   friendly warning. If the artifact is required for recovery, assert on the
   artifact and exit non-zero. Warnings in an unread log are not signals.

4. **Verify backups by restoring/inspecting them, never by their existence.**
   The archive was present, recent-looking and the right shape. It was 7 weeks
   stale (WAL race) and, for Nextcloud, missing the secrets needed to decrypt
   anything. `ls` proves nothing; row counts and `PRAGMA integrity_check` do.

5. **Never put a space in an infrastructure path.** One space took out four
   systems on the same day because each caller was independently unquoted. The
   fix is a space-free symlink, not auditing every quote forever.

6. **`set -e` in a loop over services is a hazard.** It aborted
   `backup-all-critical.sh` after the first of five, so even successful cron
   runs only ever backed up Vaultwarden. Collect failures, continue, exit
   non-zero at the end.

7. **Offsite `rclone sync` is a mirror, not a backup.** It faithfully
   replicated local destruction within 24 hours. `--backup-dir` is what makes
   it an archive.

8. **A symlink that makes deployment easy makes accidental deployment easy.**
   Introducing `/opt/homelab` means `git checkout` on the server is now a
   deploy; this bit during this very session. Documented in `CLAUDE.md`.

### 📍 Files involved

**Repo**
- `scripts/backup-engine.sh` — `is_sqlite()`, `sqlite_snapshot()`, `SQLITE_TAR`
  type, SQLite-aware `FILE` type, container-side config read + hard assert
- `scripts/backup-all-critical.sh` — removed `set -e`, derived `SCRIPT_DIR`
- `scripts/backup.d/vaultwarden.conf`, `scripts/backup.d/nextcloud.conf`
- `scripts/health.d/50-backup-freshness.sh` — new alarm
- `scripts/test-backup-freshness.sh` — its self-check (outside `health.d/` on
  purpose: the engine sources every `*.sh` there)
- `scripts/notify-unit-failure.sh`, `systemd/notify-failure@.service` — new
- `scripts/repair-silent-failures.sh` — the idempotent root-side repair
- `scripts/sync-backups-to-b2.sh` — `--backup-dir`
- `Makefile` (`update` target), `README.md` (service table), `CLAUDE.md`
- `docker/watchtower/` — deleted

**Live (server)**
- `/opt/homelab` → symlink to the repo working tree
- `/etc/systemd/system/notify-failure@.service`
- `/etc/systemd/system/enhanced-health-check.service.d/override.conf`
- `/etc/systemd/system/{hdd-health-check,slack-goatcounter-weekly,portfolio-update}.service.d/onfailure.conf`
- `/etc/crontab` (backed up to `/etc/crontab.bak-<timestamp>`)
- `/usr/local/bin/sync-backups-to-b2.sh`
- `/mnt/ssd/docker-projects/watchtower/`, `/home/docker-projects/watchtower/` — removed

### 🚚 Landed

`feature/repair-silent-automation-failures` → `develop` (PR #86) → `main`
(PR #87); `CLAUDE.md` deploy rule via PR #88. Server working tree returned to
`main` and verified afterwards, per the new rule.

**Status**: ✅ **RESOLVED.** Health check hourly and passing, failure alerting
out-of-band, all 5 backups fresh and content-verified, offsite is an archive,
Watchtower gone. Four follow-ups remain open (see above).

## [2026-09-25] Vaultwarden 1.35.1 → 1.37.3: iOS autofill save crash, and a silently truncating backup

**Date:** 2026-09-25
**Action:** Updated Vaultwarden from 1.35.1 (Dec 2025) to 1.37.3 after the iOS
client began crashing on every password save. Discovered mid-update that
`scripts/backup-engine.sh` had been producing incomplete Vaultwarden archives.
**Result:** ✅ **LIVE.** 1.37.3 / web-vault 2026.7.0, 603 ciphers intact,
`vault.gmojsoski.com` 200 internal and external. Backup defect logged as open.

### 🔍 Symptom

Bitwarden iOS autofill extension 2026.9.0 (SDK 3.0.0) threw on saving a login:

```
DecodingError.typeMismatch: Expected value of type String.
Path: data. Debug description: Expected to decode String but found a dictionary instead.
```

Crash timestamp `2026-09-25T14:57:59+02:00`. The user read this as "the save
failed". It had not.

### 🔍 Root cause

Client/server API skew. Server logs put the crash **two seconds after a
successful write**:

```
14:57:49  POST /identity/connect/token  => 200
14:57:57  POST /api/ciphers             => 200 OK    <- save succeeded
14:57:59  (client crash)
14:58:04  POST /api/ciphers             => 200 OK    <- user retry, also succeeded
```

The client crashed decoding the *response* to a write that had already
committed. Confirmed in the DB: two rows, both 550 bytes, 7 seconds apart. Each
failed save left a **duplicate vault entry**. A similar cluster on 2026-09-19
(three saves in 26s) shows this had been happening for at least a week.

The running build was 1.35.1 / web-vault 2025.12.1, roughly 9 months and 6
releases behind. Upstream release notes are explicit:

- **1.37.0** "required for support with clients with version 2026.7.0+"
- **1.37.2** "required for support with clients with version 2026.8.0+"

Client was 2026.9.0. The container never auto-updated because its compose
carries `com.centurylinklabs.watchtower.enable=false`; the tag was `:latest`
but the image had not been re-pulled. 1.35.4 through 1.37.0 also carry roughly
15 security advisories (SSRF, cross-org access, policy bypass, CSRF, cipher
access, collection permissions).

### ⚠️ Discovered mid-update: backup-engine.sh silently truncates WAL-mode SQLite

The mandatory pre-update backup produced an archive that was **missing seven
weeks of data**:

| | ciphers | newest entry |
|---|---|---|
| Live DB | 603 | 2026-09-25 12:58 |
| `vaultwarden-20260925-171212.tar.gz` | 598 | 2026-08-03 06:46 |

`backup-engine.sh` `DOCKER_TAR` stops the container, then tars `db.sqlite3`
with `EXCLUDES="*.sqlite3-shm *.sqlite3-wal"`. This assumes SQLite's shutdown
checkpoint has folded the WAL into the main file before `tar` reads it. **It
races.** The whole stop/tar/start sequence logged inside a single second and
`tar` captured the pre-checkpoint file (mtime `Sep 7`, 1048576 bytes) while the
424 KB WAL holding the recent writes was excluded by pattern. The checkpoint
landed afterwards.

This affects every WAL-mode SQLite service using `DOCKER_TAR`. Not fixed in
this session (surgical-isolation rule). The fix is to drop the container-stop
dance in favour of SQLite's online backup API, which reads through the WAL:

```python
sqlite3.connect('file:db.sqlite3?mode=ro', uri=True).backup(sqlite3.connect(dest))
```

Also noted: backups had not run since **2026-01-28**, and today's run then
pruned two of the three surviving archives under a retention policy that
assumes regular runs. The backup timer/cron needs checking.

### 📍 Changes

- **Live** `/home/docker-projects/vaultwarden/docker-compose.yml`: image pinned
  `vaultwarden/server:latest` → `vaultwarden/server:1.37.3`. Pinned rather than
  left floating so the version is reproducible and an update is a deliberate act.
- **Repo** `docker/vaultwarden/docker-compose.yml`: same pin mirrored.
- No env var changes, no manual migrations. Upstream documents none for this range.

### 🖥️ Commands

```bash
# verified pre-upgrade snapshot (NOT backup-engine.sh, see above)
cd /home/docker-projects/vaultwarden/data
python3 -c "import sqlite3; s=sqlite3.connect('file:db.sqlite3?mode=ro',uri=True); \
  d=sqlite3.connect('/mnt/ssd/backups/vaultwarden/preupgrade-db.sqlite3'); s.backup(d); d.close()"
# bundled with rsa_key.pem -> vaultwarden-preupgrade-1.35.1-20260925.tar.gz

cd /home/docker-projects/vaultwarden
sed -i 's|vaultwarden/server:latest|vaultwarden/server:1.37.3|' docker-compose.yml
docker compose pull && docker compose up -d
```

### 🧪 Verification

- `docker exec vaultwarden /vaultwarden --version` → `1.37.3` / Web-Vault `2026.7.0` ✅
- Startup log clean, `Rocket has launched`, no migration errors ✅
- Container healthcheck → `healthy` ✅
- Data intact post-upgrade: 603 ciphers, 1 user, newest `2026-09-25 12:58` ✅
- `curl localhost:8082/` → 200, `/api/config` returns correct environment URLs ✅
- `curl https://vault.gmojsoski.com/` → 200 ✅
- `./scripts/verify-services.sh` → 10 green; the 2 reds are the known
  decommissioned `budget` and `css` ✅

### 📝 Notes / open items

> **Update, same day, later:** the two items below marked ✅ were resolved within
> hours by the automation-repair entry at the top of this log. The original text
> is kept as written (this log is append-only); the markers record the outcome.

- **Duplicate vault entries** exist from the failed-looking saves (at minimum the
  2026-09-25 pair, likely more from 2026-09-19). Needs a manual pass in the vault.
  ⏳ **Still open.**
- **`backup-engine.sh` WAL race** (above) is unfixed and affects other services.
  ✅ **Resolved**: new `SQLITE_TAR` type plus a SQLite-aware `FILE` type. Verified
  603/603 ciphers with `integrity_check ok`.
- **Backups not running since 2026-01-28**; timer/cron unverified.
  ✅ **Resolved**: root cause was the space in the repo path breaking the cron
  line. Cron rewritten via `/opt/homelab`; all 5 services verified fresh; a
  freshness alarm now catches a recurrence within 48h.
- **`ADMIN_TOKEN` is plain text.** 1.37.3 now warns about this on every start:
  `You are using a plain text ADMIN_TOKEN which is insecure.` Fix is
  `vaultwarden hash` to generate an Argon2 PHC string.
- **Repo compose drift:** `docker/vaultwarden/docker-compose.yml` carries an
  `SSO_ENABLED: "true"` OIDC block that is **not** present on the live container,
  plus placeholder secrets. The repo file is aspirational for SSO. Left alone
  deliberately; reconciling it is separate work.

### 📝 Lessons learned

1. **"It failed" from a user can mean "it succeeded and then crashed".** The
   iOS client reported a save error; the server logs showed the write committing
   two seconds *before* the crash. The client choked decoding the response. Read
   the server timeline before trusting the client's account of what happened,
   and check for side effects: every "failed" save left a real duplicate entry.
2. **Pinning `:latest` is not pinning.** The container had been running the same
   image for nine months while `:latest` moved on, so "we're on latest" was true
   and meaningless. Pin explicit tags and let Renovate propose bumps.
3. **Client/server API skew is a real breakage class for self-hosted services.**
   Vaultwarden tracks upstream Bitwarden clients; its release notes say which
   server version a given client requires. Worth checking before assuming a bug.
4. **A version-skew incident is a good moment to test a backup**, which is the
   only reason the eight-month backup outage was found at all.

### 📍 Files involved

- `/home/docker-projects/vaultwarden/docker-compose.yml` (live) — image pinned
  `vaultwarden/server:1.37.3`
- `docker/vaultwarden/docker-compose.yml` (repo) — mirrored the pin
- `/mnt/ssd/backups/vaultwarden/vaultwarden-preupgrade-1.35.1-20260925.tar.gz`
- `scripts/backup.d/vaultwarden.conf` — `DOCKER_TAR` → `SQLITE_TAR`

**Status**: ✅ **RESOLVED.** 1.37.3 live and healthy, web-vault 2026.7.0,
603 ciphers intact, `vault.gmojsoski.com` 200 internal and external, iOS saves
working. Two follow-ups open: duplicate vault entries, plaintext `ADMIN_TOKEN`.

## [2026-09-25] Cal follow-up: Google Calendar + Meet, public privacy policy, Koalendar cutover

**Date:** 2026-09-25
**Action:** Connected Google Calendar and Google Meet to Cal, published a
privacy policy at `gmojsoski.com/privacy`, repointed the portfolio's
"Book a call" links from Koalendar to Cal, and corrected four docs that
prescribed a destructive tunnel-config copy.
**Result:** ✅ **LIVE.** Three Google accounts connected, Meet links generating,
`verify-services.sh` now 10 green (the 2 reds remain the known decommissioned
`budget` and `css`).

> **Supersedes** a note in the entry below ("Added Cal (scheduling)..."), which
> recorded that `cal.gmojsoski.com` was deliberately left out of
> `verify-services.sh`. It has since been added, with the status check widened
> to accept 307. See "verify-services.sh" under Changes.

### 🔍 Why

The base install from the previous entry had no calendar connected, so Cal could
not see existing busy times and would happily double-book. Three discoveries
shaped the work.

**1. Google Meet is driven by an env var, not the admin UI.** Cal's admin app
screen (`/settings/admin/apps/calendar`) writes OAuth keys straight to the DB,
which is enough for Google Calendar but NOT for Meet. `scripts/seed-app-store.ts`
seeds **both** apps from `process.env.GOOGLE_API_CREDENTIALS`:

```js
const { client_secret, client_id, redirect_uris } = JSON.parse(process.env.GOOGLE_API_CREDENTIALS).web;
await createApp("google-calendar", ...);
await createApp("google-meet", ...);   // same credentials, both seeded together
```

Setting the credentials only through the admin UI leaves `google-meet` absent
with no error explaining why. The env var is the correct route; the seeder runs
on every container start, so the apps are re-seeded automatically.

**2. Meet links come from the Google Calendar adapter, so the destination
calendar must be Google.** `googlecalendar/lib/CalendarService.ts:228` attaches
`conferenceData` only when the event is created through that adapter. The
destination calendar was initially iCloud (`apple_calendar`), which would have
produced bookings labelled "Google Meet" with no link and no error. Switched to
`contact@gmojsoski.com`. Conflict checking is unaffected by this: all 8 selected
calendars, iCloud included, still block availability. Only the calendar that
*receives* bookings must be Google, and it also becomes the Meet host.

**3. Publishing the OAuth app is not optional.** Google expires refresh tokens
after **7 days** for External apps left in "Testing", and the failure is silent:
calendar sync just stops. Publishing requires a reachable privacy policy, which
is why the page below exists. Publishing does **not** retroactively extend
already-issued tokens, so all three connections were disconnected and
reconnected after publishing (credential ids went 3/4/5 → 8/9/10, confirming
fresh grants).

### 📍 Changes

| File | Change |
|---|---|
| `docker/calcom/.env` (gitignored) | Added `GOOGLE_API_CREDENTIALS` (single-line JSON, `web` wrapper) |
| `docker/calcom/.env.example` | Documented the variable and the admin-UI trap |
| `docker/caddy/config.d/05-legal.caddy` | **New.** Serves `gmojsoski.com/privacy` inline |
| `scripts/verify-services.sh` | Appended `cal.gmojsoski.com`; widened status check to accept 307 |
| `.cursor/skills/add-homelab-service/SKILL.md`, `SERVICE_ADDITION_CHECKLIST.md`, `docs/how-to-guides/setup.md`, `docker/freshrss/README.md` | Removed the `cp cloudflare/config.yml ~/.cloudflared/config.yml` instruction |
| `portfolio_v2` (separate repo, commit `6e62086`) | Koalendar → `cal.gmojsoski.com/gmojsoski` in Hero, Footer, Rails |

**Why the privacy policy is NOT in the site build:** `scripts/update-portfolio.sh`
syncs with `rsync -av --delete`, so any file placed in `/srv/site` is destroyed
at the next `make portfolio-update`. Serving it from `config.d/` makes it
independent of the portfolio_v2 build. The snippet is numbered `05-` because
`config.d/*.caddy` is imported in glob order and `handle` blocks are
first-match-wins: it must sort before `10-gmojsoski-home`, whose `try_files`
would otherwise 404 the path. Verified surviving a real deploy.

**Cloudflare mangled the contact email.** Cloudflare's Email Address Obfuscation
rewrote the page's `mailto:` into a `/cdn-cgi/l/email-protection` stub that only
resolves once its injected script runs, and the page's CSP (`default-src 'none'`)
blocks that script, so the address rendered blank. Fixed by writing the `@` as
the HTML entity `&#64;`, which slips past the obfuscator and needs no JavaScript.

### 🧪 Verification

```bash
docker exec calcom-postgres psql -U calcom -d calcom -tAc \
  "select slug from \"App\" where slug like 'google%';"       # google-calendar, google-meet
docker exec calcom-postgres psql -U calcom -d calcom -tAc \
  "select integration, \"externalId\" from \"DestinationCalendar\";"  # google_calendar -> contact@
curl -sL -o /dev/null -w "%{http_code}\n" https://gmojsoski.com/privacy        # 200
curl -s https://gmojsoski.com/ | grep -c koalendar                            # 0
./scripts/verify-services.sh                                                  # cal -> 307 ✅
```

Portfolio rebuild after `npm audit fix` produced **byte-identical** output
(`index-CsZvMiw-.css`, `index-CX9H2fW9.js` unchanged), proving the dependency
bumps altered nothing shipped, so no redeploy was required.

### 💡 Lessons

- **Cal's admin apps UI and `GOOGLE_API_CREDENTIALS` are not equivalent.** Use
  the env var. The UI silently gives you Calendar without Meet.
- **A published-but-unverified Google app is the correct end state** for a
  personal instance. The "Google hasn't verified this app" screen is permanent
  and harmless; formal verification wants a demo video and weeks of review, and
  buys nothing under 100 users. Token lifetime depends on *published vs testing*,
  **not** on *verified vs unverified*.
- **Do not upload an OAuth app logo.** Uploading one forces mandatory
  verification. The consent screen works fine without it.
- **Anything served from `gmojsoski.com` that is not part of portfolio_v2 must
  live outside `/srv/site`**, or `rsync --delete` will silently eat it.
- Cal answers **307 on every path**, so any health check expecting a bare 200 or
  302 will report it down while it is perfectly healthy.

### 📁 Files Involved

- `docker/calcom/.env` (gitignored), `docker/calcom/.env.example`
- `docker/caddy/config.d/05-legal.caddy` (new)
- `scripts/verify-services.sh`
- `.cursor/skills/add-homelab-service/SKILL.md`, `SERVICE_ADDITION_CHECKLIST.md`,
  `docs/how-to-guides/setup.md`, `docker/freshrss/README.md`
- `portfolio_v2`: `src/components/{Hero,Footer,Rails}.tsx`, `package-lock.json`

## [2026-09-25] Added Cal (scheduling) at cal.gmojsoski.com, and found repo/live tunnel config drift

**Date:** 2026-09-25
**Action:** New Docker stack (`calcom` + `calcom-postgres`) on port 8101, Caddy
route, Cloudflare tunnel ingress. Networking change, so `verify-services.sh` was
run.
**Result:** ✅ **LIVE.** `https://cal.gmojsoski.com` resolves to the first-run
setup wizard (HTTP 200 after redirects). No regressions: the 2 reds in
`verify-services.sh` are the pre-existing decommissioned `budget` and `css`.

### 🔍 Why

User asked to self-host `github.com/calcom/cal.diy`. Two findings changed the
plan before any config was written:

1. **`cal.diy` is the renamed `cal.com` repo**, not a new project (same repo id,
   created 2021-03-22, 48k stars). It is the rebrand to fully-MIT with the
   enterprise code stripped.
2. **Docker Hub `calcom/cal.diy` has zero tags**, even though upstream's own
   `docker-compose.yml` points at `calcom.docker.scarf.sh/calcom/cal.diy`.
   The published image is `calcom/cal.com`, whose newest tag `v6.2.0`
   (2026-03-01) is also the newest GitHub release. So the prebuilt image costs
   nothing in freshness. Building from source instead would have been a Turbo
   monorepo build needing a 6 GB Node heap on 4 cores, for the same version.

The prebuilt image is safe behind a custom domain because the Dockerfile bakes
`http://NEXT_PUBLIC_WEBAPP_URL_PLACEHOLDER` and `scripts/start.sh` rewrites it
from the runtime env on every boot.

### 📍 Changes

Upstream's compose was trimmed: **Redis**, the **v2 API** and **Prisma Studio**
were all dropped. None are needed for personal scheduling, and upstream's own
comment notes Prisma Studio is an unauthenticated DB browser that should not be
exposed in production.

| File | Change |
|---|---|
| `docker/calcom/docker-compose.yml` | New. Web on 8101, Postgres container-internal (no host port) |
| `docker/calcom/.env` | New, gitignored. Secrets + Gmail SMTP |
| `docker/calcom/.env.example` | New. Committed template, no secrets |
| `docker/caddy/config.d/50-utilities.caddy` | Appended `@cal` handle block |
| `cloudflare/config.yml` + `~/.cloudflared/config.yml` | Appended ingress, **edited separately, not copied** (see Notes) |
| `README.md`, `docs/reference/port-map.md` | Appended service row / port 8101 |

Postgres data bind-mounts to `/home/docker-projects/calcom/postgres` (NVMe,
161 GB free), matching where the other stacks live. Note that
`/mnt/ssd/docker-projects` is a **symlink** to `/home/docker-projects`, so the
two paths in older docs are the same filesystem, and neither is on root.

```bash
docker pull calcom/cal.com:v6.2.0            # 8.05 GB unpacked
cd docker/calcom && docker compose up -d      # first boot: prisma migrate deploy + seed-app-store
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
cd docker/caddy && docker compose restart caddy
cd docker/cloudflared && docker compose restart
```

### 🧪 Verification

```bash
curl -I http://localhost:8101                                  # 307 -> /auth/login
curl -H "Host: cal.gmojsoski.com" http://localhost:8080        # 307, Caddy routing OK
curl -sL https://cal.gmojsoski.com                             # 200, <title>Setup | Cal.com</title>
./scripts/verify-services.sh                                   # 9 green, 2 known reds
```

Both containers report `healthy`. After the SMTP values were filled in and the
container recreated, the `EMAIL_FROM environment variable is not set` warning
stopped appearing in the logs.

### ⚠️ Notes

- **Repo and live tunnel configs have drifted. Do NOT run the
  `cp cloudflare/config.yml ~/.cloudflared/config.yml` step that
  `.cursor/skills/add-homelab-service/SKILL.md` (step 6) and
  `SERVICE_ADDITION_CHECKLIST.md` both prescribe.** As of today the live file
  has `portfolio.gmojsoski.com`, `daka-dragan.mk` and `www.daka-dragan.mk`
  which the repo copy lacks, while the repo still lists the decommissioned
  `files.` and `shopping.` hosts. That copy would have removed three working
  production hostnames. The ingress block was inserted into each file
  independently instead, above the `# Catch-all (must be last)` line. Backup
  kept at `~/.cloudflared/config.yml.bak-pre-cal`. All three at-risk hostnames
  were re-checked afterwards and still answer (200 / 301 / 200). **The skill
  and the checklist still need correcting.**
- **`cal.gmojsoski.com` was deliberately NOT added to `verify-services.sh`.**
  The script accepts only 200 or 302 (line 15), and Cal answers 307 on every
  path from a Next.js locale redirect, resolving to 200 only when followed.
  Adding it as-is would produce a permanent false red. Widening the check to
  accept 307 edits existing logic in an append-only-protected file, so it was
  left for the user to decide.
- DNS needed no work: `cal.gmojsoski.com` already resolved via an existing
  wildcard record.
- Benign startup log noise, safe to ignore: `Missing VAPID keys` (web push is
  off, optional) and `getDeploymentKey ... Signature token not found` (an
  enterprise licence probe with nothing behind it on the MIT build).

## [2026-08-16] FreshRSS subscriptions reset to jobs + cybersecurity only

**Date:** 2026-08-16
**Action:** Deleted 8 of 9 feeds and imported a curated 15-feed OPML, on
lemongrab (live). No networking change — no Caddy, tunnel, port or DNS edit,
so `verify-services.sh` was not required.
**Result:** ✅ **LIVE.** 16 feeds, 0 in error state, container healthy,
`https://rss.gmojsoski.com` → 302 (normal login redirect).

### 🔍 Why

FreshRSS replaces running `career-ops`' job scanner as a scheduled homelab
service. That evaluation (`career-ops/docs/gig-scanning/README.md`, separate
repo) measured 8 relevant postings in 14 days — too thin to justify a new
container, a CV on the server and a nightly local-LLM batch, when an already
deployed aggregator with a cron and a UI covers the same need.

### 📍 Changes

Backup taken first, to `/mnt/ssd/backups/freshrss/20260816-105412/`:

| Artifact | Purpose |
|---|---|
| `subscriptions-before.opml` | Native FreshRSS export — 9 feeds, the rollback artifact |
| `db.sqlite` | Raw copy — `PRAGMA integrity_check` = ok, 9 feeds / 2044 entries |

Removed (all except The Hacker News): FreshRSS releases, TIME.mk, TLDR,
BBC News, Al Jazeera, Seeking Alpha, Yahoo Finance, MarketWatch — 1844 entries
and the now-empty `Finance`, `News`, `Tech` categories. Category `id=1`
(`Uncategorized`, the FreshRSS default) was kept even though it emptied.

Added from `docker/freshrss/feeds.opml` via `cli/import-for-user.php`:
6 job boards, 5 `hnrss.org` gig-thread feeds, and 4 cybersecurity feeds into
the existing `Cybersecurity` category.

```bash
# backup
docker exec freshrss php /var/www/FreshRSS/cli/export-opml-for-user.php --user gmojsoski > subscriptions-before.opml
docker cp freshrss:/var/www/FreshRSS/data/users/gmojsoski/db.sqlite ./db.sqlite
# import (deletion was a PDO transaction — no delete-feed CLI exists in 1.29.1)
docker cp docker/freshrss/feeds.opml freshrss:/tmp/feeds.opml
docker exec freshrss php /var/www/FreshRSS/cli/import-for-user.php --user=gmojsoski --filename=/tmp/feeds.opml
docker exec freshrss php /var/www/FreshRSS/cli/actualize-user.php --user=gmojsoski
```

### 🧪 Verification

`actualize-user.php` fetched 15 feeds / 397 new articles, 0 errors. Per-feed
entry counts matched `docker/freshrss/check-feeds.py`, which had measured every
feed independently beforehand — so the counts were confirmed by two paths.

### ⚠️ Notes

- `cli/db-backup.php` takes **no** `--user` flag (unlike the other CLI scripts);
  the raw `docker cp` of `db.sqlite` is the reliable backup.
- FreshRSS 1.29.1 has no delete-feed CLI. Deletion was raw SQL in one
  transaction. `entry` has `ON DELETE CASCADE` on `id_feed`, but SQLite needs
  `PRAGMA foreign_keys=ON` per connection — the deletes were issued explicitly
  rather than relying on it.
- Job boards retire RSS without warning (RemoteOK now returns 410), and FreshRSS
  renders a dead feed exactly like a quiet one. Run
  `python3 docker/freshrss/check-feeds.py` when the Jobs category looks calm.
- "The Hacker News" here is `thehackernews.com`, an infosec outlet — **not**
  news.ycombinator.com. The `Jobs — HN` feeds are the latter.

## [2026-08-09] gmojsoski.com blog URLs served the homepage (Caddy try_files), plus a real 404 page

**Date:** 2026-08-09
**Action:** Diagnosed four Google Search Console non-indexing reports. Fixed the
Caddy `try_files` rule that made every blog URL serve the homepage, added a
`www` to apex 301, and added a real 404 page with a real 404 status.
**Result:** ⏳ **NOT LIVE YET. Repo-only prep, prepared on the Windows dev
clone.** Verified locally against the real homelab `Caddyfile` and the real
`dist/`. Apply on lemongrab per
[the runbook](../how-to-guides/gmojsoski-404-and-canonical-fix.md).

### 🔍 Root Cause

The live `docker/caddy/config.d/10-gmojsoski-home.caddy` had
`try_files {path} /index.html`, missing `{path}/index.html`. The portfolio
prerenders `/blog` and each `/blog/<slug>` to its own `index.html`, so without
that rule all of them fell through to the `/index.html` fallback and answered
**200 with the homepage**. Confirmed against production:

```
/blog                                -> title "Goce Mojsoski · Product & Delivery", canonical /
/blog/react-ssr-without-a-framework  -> title "Goce Mojsoski · Product & Delivery", canonical /
/blog/<slug>/index.html              -> correct title and canonical
```

The build was healthy the whole time and the prerendered files were on disk.
Only URL resolution was broken, so nothing in the portfolio repo looked wrong.
All 11 sitemap URLs resolved to one page declaring `canonical: /`, which is what
Search Console reported as "Duplicate without user-selected canonical" and
"Duplicate, Google chose different canonical than user". Present since the blog
launched on 2026-08-08.

Also found: `www.gmojsoski.com` answered 200 instead of redirecting, and the
`/index.html` catch-all meant no URL on the site ever returned 404, so every
stale link was a soft 404. "Page with redirect" is just the `http` to `https`
301 and is expected.

### ✅ Changes Made (repo mirror; live still pending)

1. **`docker/caddy/config.d/10-gmojsoski-home.caddy`**
   - `try_files {path} {path}/index.html` (added the middle rule, **removed** the
     `/index.html` fallback so a miss reaches the error handler)
   - Split `www.gmojsoski.com` out of the host matcher into its own
     `redir https://gmojsoski.com{uri} permanent` handler
   - `@html` cache matcher widened from `/index.html` to `/ /index.html /blog /blog/*`
2. **`docker/caddy/Caddyfile`** ⚠️ **global file.** Added a host-matched 404
   branch inside the existing `handle_errors`, serving `/404.html` for
   `gmojsoski.com` only; other hosts keep `respond "{err.status_code} ..."`.
   It cannot live in the `config.d` snippet: `handle_errors` is a site-level
   directive and Caddy rejects the config if it is nested inside `handle`.
   Security headers are repeated inside it because an error route inherits none.
3. **`portfolio_v2`** (separate repo, its own commit): new `NotFound.tsx`,
   router returns `notfound` for unmatched paths, `prerender.mjs` emits
   `dist/404.html` as `noindex` with no canonical, no JSON-LD and excluded from
   `sitemap.xml`, `vite preview` mirrors the server for misses, and `DEPLOY.md`
   no longer claims `try_files` is optional (that note is what let this ship).

### 🧪 Verification (local, against the real config)

Ran the actual homelab `Caddyfile` plus `config.d` locally against the real
`dist/`, adapted only for host and port:

```
/                                      200  Goce Mojsoski · Product & Delivery
/blog                                  200  Blog · Goce Mojsoski
/blog/react-ssr-without-a-framework    200  Adding server-side rendering to a React portfolio...
/blog/react-ssr-without-a-framework/   200  (same)
/typo-page                             404  Page not found · Goce Mojsoski
/css/old-style.css                     404  Page not found · Goce Mojsoski
/blog/no-such-post                     404  Page not found · Goce Mojsoski
/index.html                            200  Goce Mojsoski · Product & Delivery
```

- 404 response carries CSP, HSTS, X-Content-Type-Options, Referrer-Policy,
  Permissions-Policy, and `Server` is still suppressed ✅
- `www` host 301s preserving the path ✅
- Another host's miss still returns plain-text `404 Not Found`, not the
  portfolio page ✅
- With `404.html` absent (old build + new config) a miss still returns a 404
  status, no 500 ✅
- `caddy validate` clean on the full adapted config ✅
- Portfolio side: `npm run lint` and `npm run build` clean; `404.html` is
  `noindex`, has no canonical or JSON-LD, and is not in `sitemap.xml` (11 URLs) ✅

### 📍 Follow-up on the server

1. `make portfolio-update` **first** (the build carries `404.html`), then edit the
   live Caddy config, `caddy validate`, `caddy reload`.
2. Re-run the verification commands in the runbook against production.
3. Search Console: **Validate Fix** on both "Duplicate" reports. Export the URL
   lists for "Not found (404)" and "Page with redirect" before acting; they are
   most likely stale old-portfolio paths that now correctly answer 404.

### ⚠️ Notes

- **Two governance flags** raised in the runbook: the `Caddyfile` change is a
  global-file change, and the `10-gmojsoski-home.caddy` change modifies existing
  lines rather than appending. Both were unavoidable and both need sign-off.
- The regression test for this class of bug is the **`<title>`/canonical** check,
  not the status code. The broken state returned 200 for every URL.

**Status**: ⏳ Prepared and locally verified. Pending apply on lemongrab.

## [2026-07-28] Decommissioned Gokapi (files) + KitchenOwl (shopping) after usage audit

**Date:** 2026-07-28
**Action:** Retired two unneeded services identified in a service audit. Data volumes preserved (fully reversible).
**Result:** `files.gmojsoski.com` and `shopping.gmojsoski.com` removed from public ingress (both now tunnel 404). All other services healthy.

### 🔍 Background
- Audit compared 35 running containers + 3 systemd apps against public routes and per-app DB activity.
- User confirmed **Gokapi** (file sharing, systemd) and **KitchenOwl** (recipes/shopping, Docker) as no longer needed; all remaining services are used daily via iOS apps and were kept.
- A prior entry ([2026-06-16]) shut down KitchenOwl once before; it had since been restarted. This is the final decommission.
- Two earlier "0 usage" readings during the audit (GoatCounter, Gokapi file count) were **measurement artifacts** — GoatCounter prunes raw `hits` after aggregating, and `sudo`-based host reads failed silently once cached creds expired. Ground truth came from live URL curls + container DB queries.

### ✅ Live changes (lemongrab, user-run with sudo)
1. `sudo systemctl disable --now gokapi` — service stopped + disabled. `gokapi.sqlite` and `/mnt/ssd/apps/gokapi-data/` left on disk.
2. `docker compose -f /mnt/ssd/docker-projects/kitchenowl/docker-compose.yml down` — container removed, data volume (`/mnt/ssd/docker-projects/kitchenowl/data`) kept.
3. Removed `files.gmojsoski.com` + `shopping.gmojsoski.com` hostnames from `~/.cloudflared/config.yml`.
4. Restarted **Caddy** and **cloudflared**.

### 📝 Repo changes (VCS mirror)
- Dropped KitchenOwl + Gokapi rows from `README.md` service table; removed Gokapi from the systemd-managed line.
- Removed `files.gmojsoski.com` from `scripts/verify-services.sh` SUBDOMAINS (was reporting a permanent false failure).
- Removed `@files` block from `docker/caddy/config.d/30-storage.caddy` and `@shopping` block from `docker/caddy/config.d/50-utilities.caddy`.

### 🧪 Verification
- `https://files.gmojsoski.com` → 404, `https://shopping.gmojsoski.com` → 404 ✅
- Daily-driver services (Immich, Nextcloud, Paperless, Vaultwarden, Linkwarden, FreshRSS, Jellyfin, Mattermost, root site) all 200/302 ✅
- `caddy validate` → Valid configuration ✅

### 📝 Notes
- **Live Caddy still contains the `@files`/`@shopping` handle blocks** (root-owned; user opted not to edit them live). Harmless — the tunnel no longer routes those hostnames. The **repo mirror has them removed**, so a future config redeploy will drop them.
- Data volumes retained for both — re-enable the service / re-`compose up` to restore.
- **DNS:** `files`/`shopping` CNAMEs may still exist in Cloudflare from before; safe to delete manually.
- **Outline** (local-only wiki, stale Jan-2026 docs mirror) was reviewed in the same audit and left running by user choice.

---

## [2026-07-28] Rolled back monitoring trio trial (Scrutiny, self-hosted ntfy, Beszel)

**Date:** 2026-07-28
**Action:** Tore down a brief live trial of the prepared monitoring trio stacks. Notifications stay on **Uptime Kuma → ntfy app** (ntfy.sh), not a self-hosted ntfy instance.
**Result:** All three stacks stopped; ingress and runtime data removed. Compose stubs remain in repo for optional future use.

### 🔍 Background
- Compose files were added 2026-07-06 (`1532215`, repo-only prep).
- Stacks were started briefly on lemongrab 2026-07-28 during an agent session (~14:12–14:26), then reverted in git (`9aa39f3`).
- User confirmed only Uptime Kuma mobile notifications are wanted — self-hosted ntfy not needed.

### ✅ Live changes (lemongrab)
1. `docker compose down` in `docker/scrutiny`, `docker/beszel`, `docker/ntfy` (profiles: `monitoring`).
2. Removed `@ntfy` block from `docker/caddy/config.d/50-utilities.caddy`; removed `ntfy.gmojsoski.com` ingress from `~/.cloudflared/config.yml` and repo `cloudflare/config.yml`.
3. Restarted **Caddy** and **cloudflared**.
4. Deleted runtime data: `docker/ntfy/{cache,lib}`, `docker/scrutiny/{config,influxdb}`, `docker/beszel/beszel_data` (via ephemeral Alpine container — files were root-owned from Docker).

### 🧪 Verification
- No containers named `scrutiny`, `ntfy`, `beszel`, or `beszel-agent` ✅
- Ports `8084`, `8085`, `8086`, `45876` free ✅
- `https://ntfy.gmojsoski.com` → tunnel catch-all **404** (no backend) ✅
- Bookmarks security fix (`6613b56`) unaffected ✅

### 📝 Notes
- **DNS:** `ntfy.gmojsoski.com` CNAME may still exist in Cloudflare from the trial; safe to delete manually if desired.
- **Repo:** `docker/{scrutiny,ntfy,beszel}/` compose stubs and `docs/how-to-guides/add-monitoring-trio.md` kept as optional future reference.

## [2026-06-18] gmojsoski.com migrated to portfolio_v2 (Vite + React build pipeline)

**Date:** 2026-06-18
**Action:** Replaced the legacy vanilla HTML portfolio with the brutalist rebuild from [portfolio_v2](https://github.com/abracadaniel92/portfolio_v2). Updated homelab deploy scripts and Caddy so production serves a Vite `dist/` build instead of a flat source tree.
**Result:** `gmojsoski.com` live on commits `b788767` (initial cutover) and `fefd8c3` (lab section header). `make portfolio-update` pulls, builds, and rsyncs successfully.

### ✅ Changes Made
1. **`scripts/update-portfolio.sh`**
   - Repo path: `portfolio/portfolio` → `portfolio_v2` (`/home/goce/Desktop/Cursor projects/portfolio_v2`)
   - Flow: `git pull` → `npm ci` (falls back to `npm install`) → `npm run build` → `rsync -av --delete dist/` → `/mnt/ssd/docker-projects/caddy/site`
   - Loads nvm if `node`/`npm` not on PATH; always rebuilds on each run (no early exit when git is up to date)
2. **`Makefile` — `portfolio-update`**
   - Messaging updated for build + deploy; reminds to reload Caddy when the site snippet changes
3. **`docker/caddy/config.d/10-gmojsoski-home.caddy`**
   - SPA fallback: `try_files {path} /index.html`
   - Security headers (HSTS, CSP, Referrer-Policy, Permissions-Policy, `-Server`)
   - Cache: long-lived `/assets/*`, `no-cache` for `index.html`; removed blanket `no-store` on all responses
4. **`docker/caddy/site/README.md`** — documents new source repo and deploy flow

### 📍 Deploy / rollback
- **Deploy:** `make portfolio-update` (or `portfolio-update` wrapper if installed)
- **Log:** `/var/log/portfolio-update.log`
- **Rollback:** Point Caddy `root` at the old `portfolio/portfolio` tree and rsync that repo instead (legacy site still on GitHub at `abracadaniel92/portfolio`)

### 📝 Notes
- **Analytics:** GoatCounter (`analytics.gmojsoski.com`) intentionally omitted from v2; re-add requires CSP updates per `portfolio_v2/DEPLOY.md`
- **Social preview:** OG image path changed from `/images/og-image.png` to `/og-image.png` (1200×630); re-scrape LinkedIn/Facebook after major hero changes
- **Global script:** `/usr/local/bin/update-portfolio.sh` may still be the old version if copied previously — `make portfolio-update` uses the repo script under `Pi-version-control/scripts/`
- **Caddy reload** (after snippet edits): `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

### 📍 Files Involved
- `scripts/update-portfolio.sh`, `Makefile`, `docker/caddy/config.d/10-gmojsoski-home.caddy`, `docker/caddy/site/README.md`
- Source: `/home/goce/Desktop/Cursor projects/portfolio_v2` → GitHub `abracadaniel92/portfolio_v2`
- Live: `/mnt/ssd/docker-projects/caddy/site` (container mount `/srv/site`)

**Status**: ✅ Live — deploy pipeline verified 2026-06-18

---

## [2026-06-17] Three USB HDDs failed (end-of-life) — decommissioned disk1/disk2/disk_old + mergerfs pool

**Date:** 2026-06-17
**Symptom:** Storage investigation found that of the external drives `fstab` expects, only `/mnt/ssd_1tb` was mounted. `/mnt/disk1`, `/mnt/disk2`, `/mnt/disk_old` and the mergerfs pool `/mnt/storage` were all unmounted; Kiwix was serving zero content.
**Result:** Confirmed all three old USB HDDs have reached end-of-life and died. Repointed the one affected service (Kiwix) onto the healthy 1TB and decommissioned the dead mounts. No other service lost data.

### 🔍 Root Cause (from `/var/log/hdd-health-check.log`)
- **disk2 = /dev/sdb**: SMART pre-failure for days — `Reallocated_Sector_Count = 4424` (06-12 → 06-14), then **dropped to 0 bytes / unreadable on ~2026-06-15** (USB bridge RTL9201 still enumerates at USB 2.0, but the drive returns no capacity). Dead.
- **disk1 / disk_old**: no longer electrically enumerated (nothing on the USB 3.0 bus) — physically disconnected/dead.
- All three were old spinning USB drives; classic end-of-life (gradual sector remapping → hard failure). `nofail` in fstab meant the box kept booting normally, hiding the loss.

### 📊 What survived vs lost
- **Healthy:** `/dev/sda` 1TB WD (`WD10SPZX`) → `/mnt/ssd_1tb`, SMART PASSED, 127G/916G used. Holds **Immich library** + **stirling-pdf** data. (Internal drive is a ~477GB NVMe, not 1TB.)
- **Immich:** already migrated off the dead mergerfs pool to `/mnt/ssd_1tb` previously — safe.
- **Lost:** Kiwix `.zim` archives (on the dead pool — freely re-downloadable) and anything that lived only on disk1/disk_old (contents unknown; drives unreadable). User accepted the loss.

### ✅ Solution Applied (on-box, no sudo)
1. **Kiwix repointed** off the dead pool: `docker/kiwix/docker-compose.yml` volume `/mnt/storage/kiwix-data` → `/mnt/ssd_1tb/kiwix-data`; `docker compose up -d` recreated the container on the healthy drive. Serves content again once `.zim` files are re-added.
2. **Repo health script** `scripts/health.d/40-disk-smart.sh`: `USB_DISK_MOUNTS` reduced to `( "/mnt/ssd_1tb" )` (dropped disk1/disk2/disk_old).

### 📌 Pending user actions (need sudo)
1. **Remove dead fstab entries** (backup first):
   ```bash
   sudo cp /etc/fstab /etc/fstab.bak-2026-06-17
   sudo sed -i '\#/mnt/disk1#d; \#/mnt/disk2#d; \#/mnt/disk_old#d; \#/mnt/storage#d' /etc/fstab
   sudo systemctl daemon-reload
   ```
   (Removes the 3 disk UUID mounts + the `fuse.mergerfs /mnt/storage` line; leaves `/mnt/ssd_1tb` intact.)
2. **Optional cosmetic:** `sudo rmdir /mnt/disk1 /mnt/disk2 /mnt/disk_old /mnt/storage /mnt/old_ssd`
3. **Deployed health script** `/usr/local/bin/hdd-health-check.sh` (root-owned) still lists the dead disks — it only logs harmless "not mounted — skipping" lines now; update it to match the repo when convenient.
4. **Full SMART detail (read-only, safe):** `sudo smartctl -a /dev/sda` (confirm 1TB healthy); `/dev/sdb` is dead — don't write to it; image with `ddrescue` only if recovery is wanted.

### 📍 Files Involved
- `docker/kiwix/docker-compose.yml`, `scripts/health.d/40-disk-smart.sh`, `/etc/fstab` (user), `/usr/local/bin/hdd-health-check.sh` (user)

**Status**: ✅ Service impact resolved (Kiwix healthy); fstab/health-script cleanup pending user sudo.

---

## [2026-06-16] Decommissioned budget + css services; shut down shopping (KitchenOwl)

**Date:** 2026-06-16
**Action:** Retired two services completely and powered down a third for possible future use.
**Result:** `budget`/`css` → HTTP 404 externally (fully removed); `shopping` → 502 (intentionally stopped, ready to revive). No collateral impact — `vault`/`immich` etc. still 200, tunnel re-registered all 4 connections.

### ✅ Implementation
**budget.gmojsoski.com — Actual Budget — REMOVED COMPLETELY**
1. `docker stop actual-budget && docker rm actual-budget`; `docker rmi actualbudget/actual-server:latest`
2. Removed `@budget` block from `docker/caddy/config.d/50-utilities.caddy` (was → `172.17.0.1:5006`)
3. Removed ingress entry from **both** `cloudflare/config.yml` (repo) and `/home/goce/.cloudflared/config.yml` (live)
4. Deleted compose dir `docker/actual-budget/`
5. **Data backed up** before removal: `/home/goce/actual-budget-data-backup-20260616-222617.tar.gz` (28K, from `/home/actual-budget`)

**css.gmojsoski.com — Centar Srbija Stil — REMOVED COMPLETELY**
1. `docker stop centar-srbija-stil && docker rm centar-srbija-stil`; `docker rmi centar-srbija-stil-centar-srbija-stil`
2. Deleted `docker/caddy/config.d/15-centar-srbija-stil.caddy` (was → `172.17.0.1:8084`); removed ingress from both cloudflared configs
3. Deleted compose dir `docker/centar-srbija-stil/`. Stateless (no data volume) — nothing to back up.

**shopping.gmojsoski.com — KitchenOwl — SHUT DOWN ONLY (preserve for future)**
1. `docker stop kitchenowl` — data (`/mnt/ssd/docker-projects/kitchenowl`), compose, Caddy block, and tunnel route all **left intact**.
2. Disabled its Uptime-Kuma monitor (id 10, `active=0`) so it doesn't alert while intentionally off.
3. **Revive with:** `docker start kitchenowl` then re-enable Kuma monitor id 10 (`active=1`).

### 🧪 Verification
- `budget.gmojsoski.com` → 404, `css.gmojsoski.com` → 404, `shopping.gmojsoski.com` → 502 (expected), `vault`/`immich` → 200.
- `actual-budget` & `centar-srbija-stil` containers gone; `kitchenowl` exited; cloudflared 4 connections registered on new config.

### 📝 Pending user actions (sudo / dashboard)
- Delete root-owned data dir: `sudo rm -rf /home/actual-budget` (then remove the backup tarball once confident).
- Delete the public DNS CNAME records for `budget` and `css` in the **Cloudflare dashboard** (they currently 404 via the tunnel catch-all).

### 📍 Files Involved
- `cloudflare/config.yml` + `/home/goce/.cloudflared/config.yml` (live), `docker/caddy/config.d/50-utilities.caddy`, deleted: `docker/caddy/config.d/15-centar-srbija-stil.caddy`, `docker/actual-budget/`, `docker/centar-srbija-stil/`

**Status**: ✅ Done on-box; data dir deletion + dashboard DNS pending user.

---

## [2026-06-16] Services "going up and down" — root-caused to tunnel + ISP reconnect (not the apps)

**Date:** 2026-06-16
**Symptom:** Multiple public services appeared to drop and recover throughout the day. Question: internet issue or something broken?
**Result:** Root-caused to **three independent network-layer causes — none of them the apps or hardware.** Containers had 9-day uptimes, 0 restarts, no OOM; host had 20 GB RAM free, disk 22%, 0% packet loss to 1.1.1.1.

### 🔍 Root Causes
1. **Cloudflare tunnel on QUIC dropping chronically.** Logs full of `failed to dial to edge with quic: timeout: no recent network activity` + `Failed to refresh DNS local resolver ... i/o timeout`. 9–25 drop events/day. Since every public service funnels through one tunnel → Caddy, a tunnel blip flaps *everything* at once.
2. **Daily ~15:08 total outage = ISP/router forced WAN reconnect.** All services returned **530 together** for ~60–90s, then recovered together. No host cron/timer fires then. The drop time **drifts ~12–15s later each day** (06-12 15:08:01 → 06-16 15:08:51) — the fingerprint of a ~24h interval lease/PPPoE re-auth, not a wall-clock job. **102 of all tunnel-drop events fell in the 15:0x bucket** (next-biggest cluster: 22) — the single largest contributor.
3. **Random single-service daytime drops** were only two services: **Mattermost** (transient 502s; container otherwise healthy — slow web-root responses) and **Daka Dragan** (a dead local container, exited 2026-05-28 on a bad `nginx.conf` bind-mount; obsolete since the site moved to Netlify — the Kuma monitor correctly tracks the Netlify site).

### ✅ Solution Applied
1. **Tunnel QUIC → HTTP/2:** added `protocol: http2` to `/home/goce/.cloudflared/config.yml` (live) and `cloudflare/config.yml` (repo); `docker compose restart cloudflared`. Stops the UDP-path drops this ISP/router mishandles.
2. **Uptime-Kuma tolerance:** all active monitors set `maxretries=3`, `retry_interval=60` (was `maxretries=2`, and **Mattermost + Daka Dragan were `maxretries=0`** → alarmed on first failed probe). Gives ~3 min tolerance so the daily reconnect and transient blips no longer false-alarm. DB backed up first; Kuma restarted to load config.
3. **Mattermost probe hardened:** Kuma monitor (id 15) URL changed from `https://mattermost.gmojsoski.com` (heavy web root) → `https://mattermost.gmojsoski.com/api/v4/system/ping` (fast JSON 200). No container healthcheck added — the image lacks `sh`/`curl`/`wget`, so any healthcheck would be unreliable; the external probe is the correct layer.
4. **Removed dead `daka-dragan` container** (`docker rm daka-dragan`).

### 🧪 Verification
- After HTTP/2 switch: `Initial protocol http2`, 4 × `Registered tunnel connection protocol=http2`; `vault`/`immich` → 200, `jellyfin` → 302.
- Kuma config persisted across restart (all 15 monitors `maxretries=3`); Mattermost probe green on `/api/v4/system/ping` (200).

### 📝 Lessons Learned
- **One tunnel = one shared point of failure.** When all services 530 *simultaneously*, look at the tunnel/WAN/DNS, not the apps. Isolated single-service drops point at that one app.
- **QUIC vs ISP/router:** cloudflared defaults to QUIC (UDP/7844); some routers/ISPs throttle or time out long-lived UDP. `protocol: http2` is the standard fix and was decisive here.
- **A daily time that drifts a few seconds/day is an interval timer (ISP/PPPoE lease), not a cron** (which fires on the exact wall-clock second).
- **`maxretries=0` monitors cry wolf** on any transient blip — give every monitor retry tolerance.
- The live cloudflared config (`~/.cloudflared/config.yml`) is **separate** from the repo copy — must edit both.

### 📍 Files Involved
- `/home/goce/.cloudflared/config.yml` (live) + `cloudflare/config.yml` (repo) — `protocol: http2`
- Uptime-Kuma DB (`/mnt/ssd/docker-projects/uptime-kuma/data/kuma.db`) — monitor retry settings + Mattermost probe URL; backups: `kuma.db.bak-20260616-221655`, `kuma.db.bak-mm-*` (inside container)

### 📌 Pending user actions (off-box / sudo)
- **Real fix for the 15:08 drop:** reschedule the router's forced daily reconnect to off-hours (~04:00), or ask ISP to disable forced re-auth. User accepted the reconnect and chose to only make Kuma tolerant of it.
- Broken safety net: root crontab has `*/5 * * * * root /usr/local/bin/healthcheck-watchdog.sh` but that script **does not exist** (fails silently every 5 min). Remove the line via `sudo crontab -e`. (Active auto-recovery is the hourly `enhanced-health-check.timer`, which runs on the hour and so misses the 15:08 window — no amplification.)

**Status**: ✅ On-box fixes applied & verified; router reschedule + cron cleanup pending user.

---

## [2026-06-08] Knowledge-MCP weekly refresh disabled (index frozen on current data)

**Date:** 2026-06-08
**Context:** The `knowledge-mcp` index no longer needs weekly re-pulls; decision to freeze it on the current data.
**Action (live):** `sudo systemctl disable --now knowledge-mcp-weekly-refresh.timer` on lemongrab — removed the `timers.target.wants` symlink; timer now `disabled` + `inactive`. No cron backup existed.
**Repo:** Removed `systemd/knowledge-mcp-weekly-refresh.{service,timer}` and `scripts/deploy-knowledge-mcp-weekly-refresh.sh`; updated `docs/how-to-guides/mcp-knowledge-server.md` to manual-only refresh.
**Result:** `knowledge-mcp` keeps serving the current data unchanged (`/sse` → 200). Manual refresh still available via `mcp_server/scripts/weekly-knowledge-refresh.sh`.
**Optional cleanup:** the now-disabled unit files remain installed — `sudo rm /etc/systemd/system/knowledge-mcp-weekly-refresh.{service,timer} && sudo systemctl daemon-reload`.


---

## [2026-05-09] daka-dragan.mk: Docker → Netlify; Cloudflare Tunnel hostname removed

**Date:** 2026-05-09
**Context:** Static/marketing site `daka-dragan.mk` (and `www`) was hosted in Docker behind Caddy + Cloudflare Tunnel; it is **migrated to Netlify**.
**Public:** DNS/TLS handled by Cloudflare → Netlify (tunnel route for these hostnames **deleted**).
**Docker:** Container may remain **stopped** (image/compose retained if ever needed again).
**Repo:** Removed tunnel ingress from **cloudflare/config.yml**; deleted **docker/caddy/config.d/16-daka-dragan.caddy** and **docker/daka-dragan/** (compose, nginx, Dockerfile); dropped related **.gitignore** entries.
**Live follow-through:** Sync Caddy config to the server (or pull) and **`docker compose restart caddy`** (or equivalent) so the Pi no longer loads the removed snippet. Remove/stop any leftover **daka-dragan** container on the host if still present.

---

## [2026-05-03] Containerd data migrated from root to /home

**Date:** 2026-05-03
**Symptom:** Root partition (`/dev/nvme0n1p2`, 101G) at **98% usage** (2GB free). `/var/lib/containerd` was 76GB on root despite Docker data root already being on `/home/docker-data`.
**Action:** Migrated containerd data from `/var/lib/containerd` (root) to `/home/containerd` (`/dev/nvme0n1p3`, 368G) using rsync + symlink approach.
**Changes:**
- **scripts/migrate-containerd-to-home.sh** [NEW]: Migration script — stops docker/containerd, rsyncs data, renames old dir, creates symlink, restarts services, verifies.
- **Live**: `/var/lib/containerd` is now a symlink → `/home/containerd`. Old data (`/var/lib/containerd.old`) removed by user after verification.
**Commands run:**
- `sudo bash scripts/migrate-containerd-to-home.sh` (rsync ~76GB, ~13 min)
- `sudo rm -rf /var/lib/containerd.old` (user confirmed containers healthy first)
**Verification:**
- Docker: RUNNING ✅
- Containerd: RUNNING ✅
- All containers came back up (20+ containers listed)
- Symlink in place: `/var/lib/containerd -> /home/containerd`
- Root partition freed ~76GB (98% → ~24%)
**Result:** Root partition space reclaimed. `/home` now at 42% (146G/368G used).

---

## [2026-05-03] Paperless-ngx: crash loop — PostgreSQL rejects session timezone `UTC`

**Date:** 2026-05-03
**Symptom:** `paperless-webserver` exited / restarted during init; logs showed `django.db.utils.DataError: invalid value for parameter "TimeZone": "UTC"` when Django opened a DB connection to the shared Nextcloud Postgres (`nextcloud-postgres`).

**Cause:**
- On this Postgres instance, `SELECT count(*) FROM pg_timezone_names` is **0**, and `SET TIME ZONE 'UTC'` fails while **`SET TIME ZONE 'Etc/UTC'`** succeeds (same for `'GMT'`).
- Paperless sets global `TIME_ZONE` from `PAPERLESS_TIME_ZONE`, but **Django sets the PostgreSQL session timezone from `DATABASES["default"]["TIME_ZONE"]`**. Paperless does not set that key, so it stays `None` and Django always runs **`SET TIME ZONE 'UTC'`** for PostgreSQL when `USE_TZ` is true — **ignoring** `PAPERLESS_TIME_ZONE`. Changing only `.env` is not enough.

**Fix (live stack under `/home/docker-projects/paperless`):**
1. **`Dockerfile`** — extend `ghcr.io/paperless-ngx/paperless-ngx:latest` and patch `/usr/src/paperless/src/paperless/settings.py` immediately after `DATABASES = _parse_db_settings()` so that when `PAPERLESS_DBHOST` is set,
   `DATABASES["default"]["TIME_ZONE"] = os.getenv("PAPERLESS_TIME_ZONE", "UTC")`.
2. **`docker-compose.yml`** — `webserver` uses `build: .` and image tag `paperless-webserver:local` (instead of pulling upstream image only).
3. **`.env`** — `PAPERLESS_TIME_ZONE=Etc/UTC` (valid for `SET TIME ZONE` on this server; avoids the broken `'UTC'` name).

**Verification:**
- Container completes init: migrations OK, Granian listening; no timezone traceback in logs.
- HTTP check: `curl` to `127.0.0.1:8097` may reset on some hosts; **`http://172.17.0.1:8097/`** or the public URL (`https://paperless.gmojsoski.com`) works when the app is up.

**Rebuild after upstream image updates:**
`docker compose build --pull webserver && docker compose up -d webserver`

---

## [2026-04-26] Android emulator + ws-scrcpy service addition (local only)

**Date:** 2026-04-26
**Action:** Added Docker-based Android emulator stack with browser control via ws-scrcpy. **Local/LAN access only** — no Cloudflare tunnel or Caddy reverse proxy. Public exposure was deliberately skipped (no `android.gmojsoski.com`).
**Storage:** Persistent emulator data and ADB keys under `/home/docker-projects/android-emulator/` (root filesystem avoided per storage rules).
**Changes:**
- **docker/android-emulator/docker-compose.yml:** New stack — `halimqarroum/docker-android:api-33-playstore` (KVM-accelerated, Play Store image) and `shmayro/scrcpy-web` (`ws-scrcpy`) on host port `8233`. ADB exposed only on `127.0.0.1:5555`.
- **docker/android-emulator/.env.example:** Runtime tunables (image variant, memory/cores, animation flags, storage paths).
- **docker/android-emulator/README.md:** Start, access, iOS-via-LAN usage notes, optional APK export script.
- **README.md:** Added Android Emulator (`<device-ip>:8233`) to running services table and directory tree.
**Access:**
- Browser (server): `http://localhost:8233`
- Browser (LAN devices, incl. iOS Safari): `http://<device-ip>:8233`
- ADB (host only): `adb connect 127.0.0.1:5555`
**Notes:**
- Requires `/dev/kvm`. First boot can take several minutes; recommended ≥ 8 GB RAM.
- If you later want public access, the standard service-addition checklist applies: add a Caddy `@android_emulator` block, add `android.gmojsoski.com` to `cloudflare/config.yml`, and add the subdomain to `scripts/verify-services.sh`.

---

## [2026-04-23] Stirling PDF local-only deployment (1TB internal SSD)

**Date:** 2026-04-23
**Action:** Added Stirling PDF as a Docker service for local/LAN access only (no Cloudflare subdomain).
**Storage:** Persistent paths mapped to internal 1TB SSD under `/mnt/ssd_1tb/stirling-pdf/`.
**Changes:**
- **docker/stirling-pdf/docker-compose.yml:** New service using `stirlingtools/stirling-pdf:latest`, `restart: unless-stopped`, host port `8095:8080`.
- **Volumes:** `/mnt/ssd_1tb/stirling-pdf/{trainingData,config,customFiles,logs,pipeline}` mapped into container.
- **docker/stirling-pdf/README.md:** Added local access and management instructions.
- **README.md:** Added Stirling PDF to running services and directory tree.
**Result:** Service is available locally at `http://localhost:8095/login` and on LAN at `http://<server-ip>:8095/login`.

---

## [2026-03-27] System Boot Hangs Without USB HDDs Attached

**Date:** 2026-03-27
**Action:** Added `nofail` to fstab for the mergerfs pool to allow system boot without USB HDDs.
**Symptoms:** Unplugging the 1TB or 2TB USB drives could cause the OS to hang on boot or enter Emergency Mode because the `/mnt/storage` mergerfs pool depended on them without a `nofail` flag.
**Fix:**
- Checked `/etc/fstab` and verified individual USB HDDs already had the `nofail` flag.
- Added `nofail` to the `fuse.mergerfs` entry (`/mnt/storage`) to prevent it from halting boot.
**Result:** The system will gracefully timeout (90s) and continue booting into the OS even if the USB HDDs are unplugged.

---

## [2026-03-12] Actual Budget added (budget.gmojsoski.com)

**Date:** 2026-03-12
**Action:** Installed Actual Budget (personal finance) with subdomain budget.gmojsoski.com.
**Storage:** Data on NVMe at `/home/actual-budget` (per user preference).
**Changes:**
- **docker/actual-budget/**: docker-compose (port 5006, volume /home/actual-budget), README.
- **Caddy:** `config.d/50-utilities.caddy` — `@budget` host budget.gmojsoski.com → reverse_proxy 172.17.0.1:5006.
- **Cloudflare:** Added budget.gmojsoski.com to ingress in `cloudflare/config.yml`; applied to ~/.cloudflared and restarted Caddy + cloudflared.
- **scripts/verify-services.sh:** Added budget.gmojsoski.com to SUBDOMAINS.
- **README.md:** Actual Budget in services table and directory tree.
**Result:** https://budget.gmojsoski.com live after config copy and Caddy/cloudflared restart.

---

## [2026-03-09] HDD monitoring, health-check interval, and deploy (session summary)

**Date:** 2026-03-09
**Summary of changes made in this session:**

1. **Mattermost webhook for health alerts**
   - Added `scripts/health_webhook_url` (user-provided URL).
   - Added `**/health_webhook_url` to `.gitignore` so the URL is not committed.

2. **Health check timer: 3 min → 1 hour**
   - Updated all references from “every 3 minutes” to “every hour”.
   - Files: `scripts/permanent-auto-recovery.sh`, `scripts/fix-health-check-timer.sh`, `scripts/verify-health-check.sh`, README, `usefull files/MONITORING_AND_RECOVERY.md`, `usefull files/HEALTH_CHECK_STATUS.md`, `docs/reference/infrastructure-diagram.md`, `scripts/deploy-health-check.sh`, `restart services/LAB_COMMANDS.md`.
   - On production, apply with: update `/etc/systemd/system/enhanced-health-check.timer` to `OnUnitActiveSec=1h`, then `sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer`.

3. **USB HDD SMART check – standalone daily run**
   - **`scripts/hdd-health-check.sh`**: Wrapper that sources `health.d/40-disk-smart.sh`; uses `/var/log/hdd-health-check.log`.
   - **`systemd/hdd-health-check.service`** and **`systemd/hdd-health-check.timer`**: Timer runs daily at 11:00.
   - **`scripts/deploy-hdd-health-check.sh`**: Deploys script, module, webhook, and systemd units; derives repo path from script location.
   - **`scripts/verify-health-check-interval.sh`**: Verifies enhanced-health-check timer interval and next run.
   - HDD check runs **once per day** (not with the main health check). The “💾 USB HDDs health” Mattermost summary (status + space per disk) is sent **only on Sunday**; failure/warning alerts are sent immediately on any run.

4. **`health.d/40-disk-smart.sh`**
   - Added per-disk space (used/free) and one summary line per disk (OK / pre-failure / FAILED / not mounted).
   - Summary notification gated to Sunday 11:00 (day=7, hour=11, minute<5).

5. **`systemd/hdd-health-check.service` fix**
   - Removed invalid `WantedBy=multi-user.target` from `[Unit]` (belongs only in `[Install]`).
   - After pulling, re-copy to `/etc/systemd/system/` and run `sudo systemctl daemon-reload`.

**Production deploy (lemongrab):** Run from repo root: `sudo bash scripts/deploy-hdd-health-check.sh`.
**HDD capacities (from docs):** disk1 = 1 TB, disk2 = 2 TB, disk_old = 500 GB (legacy).
**SMART alerts observed:** disk1 (pending/offline uncorrectable), disk2 (reallocated sectors), disk_old (SMART FAILED) — back up data and plan replacement.

---

## [2026-03-11] Immich primary storage on 1TB SATA SSD

**Date:** 2026-03-11
**Action:** Use the 1TB SATA SSD (/dev/sda, mounted at /mnt/ssd_1tb) as primary storage for Immich (healthiest drive).
**Changes:**
- **docker/immich/.env**: `UPLOAD_LOCATION=/mnt/ssd_1tb/immich-library` (if .env is tracked; otherwise set manually).
- **scripts/migrate-immich-to-ssd1tb.sh**: Migrates existing library from /mnt/storage/immich-library to /mnt/ssd_1tb/immich-library (rsync), updates .env, restarts Immich.
- **docker/immich/README.md**, **create-library-dirs.sh**: Default path now /mnt/ssd_1tb/immich-library.
- **health.d/40-disk-smart.sh**: Added `/mnt/ssd_1tb` to monitored mounts so the primary SSD appears in the Sunday HDD health report.
**On server:** Ensure /mnt/ssd_1tb is in fstab, then run `sudo bash scripts/migrate-immich-to-ssd1tb.sh` from repo root.

**Result:** Migration completed successfully. Immich library now on primary 1TB SSD (/mnt/ssd_1tb/immich-library). Same data kept on mergerfs as backup. Wikipedia no-pics (~50GB) download planned for later (on mergerfs or after confirming primary storage usage).

---

## [2026-03-08] Root disk space & SSD usage

**Date:** 2026-03-08
**Context:** Root (/) was at 93%; health check alerts for Root and “SSD” both refer to the same partition (`/dev/nvme0n1p2` — root is 101G, and `/mnt/ssd` lives on that same partition).
**SSD space:** Root partition has **~6.9 GB free** (89G used of 101G). There is no separate SSD partition; `/mnt/ssd` is on root.
**To free root:** Run (requires sudo):
- `sudo apt-get clean` — frees ~5 GB (apt package cache in `/var/cache/apt/archives`).
- `sudo journalctl --vacuum-size=100M` — caps systemd journal at 100 MB (frees ~114 MB).
- Optional: `sudo find /var/log -name "*.log" -mtime +30 -exec truncate -s 0 {} \;` to truncate old logs (use with care).
**Note:** Docker data is already on `/home/docker-data` (not on root).

### What else can be moved from root

| What | Size (approx.) | How | Effort |
|------|-----------------|-----|--------|
| **Swap file** | **4 GB** | Move `/swapfile` to e.g. `/home/swapfile` and point fstab there | Low |
| **Systemd journal** | **~1.3 GB** | Bind mount: store journal on `/home` and bind to `/var/log/journal` | Medium |
| **Snap packages** | **~4.1 GB** | Change snap layout (e.g. `SNAP_REAL_HOME`) or remove unused snaps | Medium / High |
| **Old Docker backups** | Tiny | Remove `/var/lib/docker_backup_*` (Docker already on `/home/docker-data`) | Low |
| **/var/log (old files)** | Part of 1.4G | Aggressive logrotate + truncate old logs | Low |

**Recommended order:** (1) Move swap to `/home`. (2) Cap or move journal. (3) Remove old docker_backup dirs. (4) Optionally trim snaps or move journal to `/home` via bind mount.

---

## [2026-03-08] USB HDD SMART health check (health.d module)

**Date:** 2026-03-08
**Action:** Added SMART-based health check for the 3 USB HDDs (docking stations) so the homelab can warn before a disk is likely to fail.
**Result:** New module `scripts/health.d/40-disk-smart.sh` runs as part of the existing health check. It detects disks from mount points `/mnt/disk1`, `/mnt/disk2`, `/mnt/disk_old`, runs `smartctl` (trying `-d sat` for USB bridges if needed), and alerts on SMART overall FAILED or on pre-failure attributes (Reallocated_Sector_Ct, Current_Pending_Sector, Offline_Uncorrectable).
**Requirement:** Install smartmontools: `sudo apt install smartmontools`. If a USB enclosure does not pass SMART, the module logs and skips that drive.
**Optional:** To monitor different mounts, edit the `USB_DISK_MOUNTS` array in `40-disk-smart.sh`.
**Notification schedule:** The "💾 USB HDDs health" summary (OK + space per disk) is sent to Mattermost **only on Sunday** (when the daily run falls on Sunday 11:00). Failure/warning alerts are sent immediately on any run.
**Standalone daily run:** As of 2026-03-08 the HDD check runs separately from the main health check: use `scripts/hdd-health-check.sh` with systemd timer `hdd-health-check.timer` (daily 11:00). See README “HDD health check (standalone, daily)” for deploy steps.

---

## [2026-03-03] FreshRSS: Unavailable on :8099 and URL – container not started + restarts required

**Date:** 2026-03-03
**Symptoms:** http://localhost:8099 and https://rss.gmojsoski.com were unavailable.
**Causes:** (1) FreshRSS container had never been started. (2) After adding a new service, Caddy and cloudflared must be restarted or the public URL stays 404.
**Fix:**
1. Start container: `cd docker/freshrss && docker compose up -d`.
2. **Apply config and restart (required for any new service):**
   - `cp cloudflare/config.yml ~/.cloudflared/config.yml`
   - `cd docker/caddy && docker compose restart caddy`
   - `cd docker/cloudflared && docker compose restart`
3. Run `./scripts/verify-services.sh`.
**Result:** Local :8099 and https://rss.gmojsoski.com both work (302 installer).
**Remember:** New Caddy/tunnel routes only take effect after copying the tunnel config and restarting Caddy then cloudflared. See SERVICE_ADDITION_CHECKLIST.md “Restart Sequence”.

---

## [2026-03-03] Bookmarks: "URL is required" – rebuilt to accept form + JSON

**Date:** 2026-03-03
**Symptoms:** POST to bookmarks.gmojsoski.com returned "URL is required" even when sending a URL.
**Cause:** Old app only read `request.json` and expected key `url`; form submissions or different keys (e.g. `link`) were ignored.
**Fix:** Rebuilt app in `Pi-version-control/apps/bookmarks/`: accepts both JSON and form data, accepts `url` / `link` / `bookmark_url`, validates URL (http/https), uses env for webhook and token (`.env` + systemd `EnvironmentFile`), added simple HTML form at `/`.
**Deploy:** Copy `apps/bookmarks/*` to `/mnt/ssd/apps/bookmarks/`, ensure `.env` has `MATTERMOST_WEBHOOK_URL` and `BOOKMARKS_SECRET_TOKEN`, then `sudo systemctl restart bookmarks.service`.

---

## [2026-03-03] Immich: Photo backup service added

**Date:** 2026-03-03
**Action:** Added Immich for self-hosted photo/video backup (Google Photos alternative).
**Result:** Service at https://immich.gmojsoski.com, local http://localhost:2283 (port 2283).

### Configuration
- **docker/immich/**: docker-compose (server, ML, Redis, PostgreSQL), .env with `UPLOAD_LOCATION=/mnt/storage/immich-library` (3TB mergerfs). `IMMICH_IGNORE_MOUNT_CHECK_ERRORS=true` used so server starts on empty library; optional: run `sudo docker/immich/create-library-dirs.sh` to create .immich markers, then remove the flag.
- **Caddy:** docker/caddy/config.d/20-media.caddy — `immich.gmojsoski.com` → `http://172.17.0.1:2283` (no gzip).
- **Tunnel:** immich.gmojsoski.com in cloudflare/config.yml and ~/.cloudflared/config.yml → `http://localhost:8080`.
- **2FA:** No native TOTP; use Google OAuth (Administration → Settings) and 2FA on Google account, or Authentik.
- **Access control:** OAuth Auto Register disabled (only pre-created users can sign in); password login disabled in Settings so login is OAuth-only and not guessable.

### If Immich crashes on start (encoded-video/.immich ENOENT)
- Empty UPLOAD_LOCATION lacks subdirs; either set `IMMICH_IGNORE_MOUNT_CHECK_ERRORS=true` in .env or run `sudo docker/immich/create-library-dirs.sh /mnt/storage/immich-library`.

---

## [2026-02-17] Clawdbot: Switched from Google Gemini to local Ollama

**Date:** 2026-02-17
**Action:** Removed Gemini API key and configured Clawdbot to use local Ollama (DeepSeek R1 1.5B).
**Result:** Clawdbot now uses `ollama/deepseek-r1:1.5b` on the host; no cloud API key required.

### Changes
- **docker/clawdbot/docker-compose.yml**: Removed `GEMINI_API_KEY` and `GOOGLE_API_KEY`. Added `OLLAMA_API_KEY` and `extra_hosts: host.docker.internal:host-gateway` so the gateway container can reach Ollama on the host.
- **docker-data/clawdbot/config/clawdbot.json**: Replaced `google` provider with `ollama` provider (`baseUrl: http://host.docker.internal:11434/v1`), primary model `ollama/deepseek-r1:1.5b`. Backup saved as `clawdbot.json.bak`.

### Prerequisites
- Ollama must be running on the host (e.g. `ollama serve`) and model `deepseek-r1:1.5b` pulled.

### Rollback
- To revert: restore `clawdbot.json` from `clawdbot.json.bak`, re-add Gemini env vars to docker-compose, and restart the gateway.

### [2026-02-17] Reverted to Google Gemini (local Ollama too slow / stuck)
- Local Ollama (1.5B/3B) was too slow on CPU; Clawd stayed on "molt is typing..." and did not respond in time.
- **Action:** Switched Clawdbot back to Google Gemini: restored `google` provider and `google/gemini-2.5-flash` in `clawdbot.json`, re-added `GEMINI_API_KEY` / `GOOGLE_API_KEY` in docker-compose.
- **User:** Set `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) in `docker/clawdbot/.env` and restart the gateway.

---

## [2026-01-29] CPU Upgrade - Intel Pentium G4560T → Intel Core i5-7500T

**Date:** 2026-01-29
**Action:** Replaced CPU from Intel Pentium G4560T (2 cores, 4 threads) to Intel Core i5-7500T (4 cores, 4 threads)
**Result:** Successful upgrade with no software changes required

### ✅ Hardware Change
- **Previous CPU**: Intel Pentium G4560T @ 2.90GHz (2 Cores, 4 Threads)
- **New CPU**: Intel Core i5-7500T @ 2.70GHz (4 Cores, 4 Threads)
- **Machine**: Lenovo ThinkCentre M710q
- **BIOS**: M1AKT18A (05/03/2017)

### 🔍 Verification
- CPU detected correctly: `Intel(R) Core(TM) i5-7500T CPU @ 2.70GHz` ✅
- All 4 cores recognized by system ✅
- Docker services running (30 containers active) ✅
- No software configuration changes required ✅

### 📝 Notes
- Both CPUs are 7th generation (Kaby Lake) - same architecture (x86_64)
- No driver or kernel changes needed
- All services continue to function normally
- Performance improvement: 2 cores → 4 cores (better parallel processing)
- Lower base clock (2.70GHz vs 2.90GHz) but more cores for better multi-threaded performance

### ✅ Status
CPU upgrade completed successfully. System operational with improved multi-core performance.

---

## [2026-01-28] Portfolio Layout Issues - Cache Busting Mismatch

**Date:** 2026-01-28
**Symptoms:**
- Portfolio site (`gmojsoski.com`) showing broken layout on desktop
- Duplicated social icons visible in Contact section
- "Show more" buttons not working on Personal Projects section
- Cache appearing to serve old assets despite latest code being deployed

**Root Cause Identified:**
1. **Local Uncommitted Changes**: Cache-busting query strings (`?v=20260128`) were added to asset links in `index.html` to force Cloudflare cache refresh
2. **Sync Mismatch**: These changes were never committed to git, so `make portfolio-update` pulled clean code from GitHub without the cache busters
3. **Version Mismatch**: Live site served assets without cache busters → Cloudflare served stale cached CSS/JS from December while HTML was from January
4. **Confusion**: Issue appeared after Caddy configuration split, making it seem related to that change when it was actually a cache/sync problem

**Solution Applied:**
1. **Restored Clean State**: Ran `git restore index.html` in portfolio repository to match GitHub `main` branch exactly
2. **Re-synced**: Ran `make portfolio-update` to ensure complete sync from repository to live site
3. **Removed Temporary Fix**: Removed the `no-cache` headers that were added to Caddy as a workaround
4. **Verified Paths**: Confirmed `/home/docker-projects/caddy` and `/mnt/ssd/docker-projects/caddy` are the same directory (symlinked, inode: 9942018)

**Verification:**
- Portfolio repository shows clean working tree ✅
- `make portfolio-update` reports "Already up to date" ✅
- Live site matches GitHub `main` branch exactly ✅

**Key Lessons Learned:**
1. **Don't Mix Fixes**: Cache-busting changes should be committed to git OR not used at all; uncommitted changes create sync mismatches
2. **Cloudflare Caching**: Cloudflare edge caching can persist old assets even when server is updated
3. **Hard Refresh Required**: Users need to hard refresh (Ctrl+Shift+R) or use incognito mode after cache issues
4. **Sync Verification**: Always verify that local changes match what's deployed when troubleshooting "broken" sites

**Files Involved:**
- `/home/goce/Desktop/Cursor projects/portfolio/portfolio/index.html` - Repository file
- `/home/docker-projects/caddy/site/index.html` - Live site (symlinked to `/mnt/ssd/docker-projects/caddy/site/index.html`)
- `scripts/update-portfolio.sh` - Sync script

**Status**: ✅ Resolved - Site restored to clean state from `main` branch

---

## [2026-01-28] Configured Clawdbot Web Search (Brave Search)

**Date:** 2026-01-28
**Action:** Used `clawdbot configure --section web` to enable Brave Search and web fetch.
**Result:** Clawdbot can now perform live web searches using the Brave Search API.

### ✅ Changes Made
1. **Enabled Web Search**: Switched `tools.web.search.enabled` to `true` in `clawdbot.json`.
2. **Set API Key**: Provided the Brave Search API key to the configuration tool.
3. **Enabled Web Fetch**: Switched `tools.web.fetch.enabled` to `true` to allow reading web content.
4. **Service Restarted**: Restarted the `clawdbot-gateway` container to apply changes.

### 🧪 Verification
- Config file `clawdbot.json` verified to contain the `tools` section with correct settings.
- Service restarted successfully.

---

## [2026-01-28] Caddy Configuration Outage after Splitting

**Date:** 2026-01-28
**Action:** Splitting monolithic Caddyfile into service-specific configurations in `config.d/`
**Result:** Service went down during initial attempt; successfully restored with modular structure.

### 🔴 Symptoms
- Caddy service failed to start after splitting the Caddyfile.
- Port 8080 (reverse proxy) became unresponsive.
- All services behind the proxy returned connection errors.

### 🔍 Root Cause Identified
1. **Missing Config Mount**: The `config.d` directory was not properly mounted or referenced in the production Caddy instance.
2. **Explicit Import Errors**: Using explicit individual imports made the configuration fragile (a missing file would crash the entire proxy).

### ✅ Solution Applied
1. **Wildcard Import**: Updated `Caddyfile` to use `import /etc/caddy/config.d/*.caddy`.
2. **Consistent Extensions**: Renamed all split configs to `.caddy`.
3. **Volume Mount**: Ensured `config.d` is correctly mounted to `/etc/caddy/config.d` in `docker-compose.yml`.
4. **Validation**: Used `caddy validate` via Docker to verify syntax before deployment.

---

## [2026-01-28] Modular Health Check System Migration

**Date:** 2026-01-28
**Action:** Migrated monolithic `enhanced-health-check.sh` to a modular engine with service-specific plugins.
**Result:** Reduced CPU churn and improved maintainability.

### 🔍 Improvements
1. **Modular Engine**: `health-check-engine.sh` now sources small check scripts from `health.d/`.
2. **Interval Optimization**: Increased health check interval from **3 minutes** to **15 minutes** as requested by the user.
3. **Robustness**: A failure in one check module no longer risks the entire script's execution.

### ✅ Verification
- Manual execution confirmed the engine picks up and runs all modules in `health.d/`.
- Systemd timer successfully updated to 15-minute intervals.

---

## [2026-01-16] Backup Cron Job Failing - Permission Denied on Log File

**Date:** 2026-01-10
**Action:** Attempted to enable plugin uploads in Mattermost by modifying config.json directly
**Result:** Mattermost returned 502 Bad Gateway, service unavailable

### 🔴 Symptoms
- Mattermost returning **502 Bad Gateway** immediately after configuration change
- Service completely unavailable
- Container may have been running but not responding

### 🔍 Root Cause Identified
1. **Direct config.json Modification**: Attempted to modify `config.json` file directly inside the Docker container to enable plugin uploads (`PluginSettings.EnableUploads: true`)
2. **Config Corruption**: The direct modification likely corrupted the JSON structure or introduced syntax errors
3. **Mattermost Startup Failure**: Mattermost couldn't parse the corrupted config.json and failed to start properly
4. **Unnecessary Complexity**: The docker-compose.yml already had `MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"` environment variable set, which should have been sufficient

### ✅ Solution Applied
1. **Stop Mattermost**: `docker compose stop mattermost`
2. **Remove Corrupted Config**: Used temporary container to remove corrupted `config.json` from Docker volume:
   ```bash
   docker run --rm -v mattermost_mattermost-config:/config busybox sh -c "rm -f /config/config.json"
   ```
3. **Restart Mattermost**: `docker compose up -d mattermost`
4. **Config Regeneration**: Mattermost automatically regenerated `config.json` from environment variables on startup

### 📝 Key Lessons Learned
1. **Use Environment Variables First**: Mattermost's docker-compose.yml already had `MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"` which should have been sufficient. Environment variables are the preferred method for Mattermost configuration.
2. **Avoid Direct Config.json Modifications**: Modifying config.json directly can cause corruption and service failures. Mattermost manages config.json internally from environment variables.
3. **Environment Variables > Direct File Edits**: When both methods exist, prefer environment variables:
   - Environment variables in docker-compose.yml are more maintainable
   - Mattermost automatically merges environment variables into config.json
   - Direct file edits bypass Mattermost's configuration management system
4. **Recovery Method**: If config.json is corrupted, simply delete it and let Mattermost regenerate from environment variables on restart.

### 🔧 Correct Approach for Future Plugin Upload Enable
If you need to enable plugin uploads in Mattermost, use **ONLY** the environment variable (already set in docker-compose.yml):
```yaml
environment:
  MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"
```

**DO NOT** modify config.json directly. Mattermost will read the environment variable and configure itself accordingly on startup.

### ✅ Verification
- Mattermost accessible at `https://mattermost.gmojsoski.com` ✅
- Service responding with HTTP 200 ✅
- Plugin uploads enabled via environment variable ✅
- Config.json regenerated successfully ✅

### 📍 Files Involved
- `docker/mattermost/docker-compose.yml` - Contains `MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"` (correct method)
- Docker volume: `mattermost_mattermost-config:/mattermost/config` - Contains config.json (managed by Mattermost)

**Status**: ✅ Resolved - Mattermost restored and plugin uploads enabled via environment variable

## [2026-01-10] Mattermost → RocketChat → Zulip Migration

**Date:** 2026-01-10
**Action:** Mattermost removed → RocketChat attempted → Zulip installed

### Mattermost Removal
**Completed:**
- Stopped and removed Mattermost containers and volumes
- Removed Mattermost from Caddy configuration (both production and repo)
- Removed Mattermost from Cloudflare Tunnel config
- Removed Mattermost from Makefile commands
- Removed Mattermost from LAB_COMMANDS.md
- Removed Mattermost from verify-services.sh
- Removed Mattermost from main README
- Deleted Mattermost directory and all documentation

**Reason for Removal:**
- Intermittent 530/502 errors (root cause: failing health check + Caddy syntax error - both fixed but user opted for replacement)
- Service not accessible internally (DNS/IPv6 issues)
- User preference for alternative solution

### 🔍 Mattermost Failure Root Cause Analysis (Retrospective - 2026-01-10)

After investigating the WiFi access issue and fixing it, it's now clear what likely caused Mattermost to fail:

**Primary Root Cause: Same DNS Issue as WiFi Problem**
1. **Pi-hole Local DNS Record**: Pi-hole was configured with a Local DNS Record for `mattermost.gmojsoski.com` pointing to local server IP (`192.168.1.97`)
2. **Inconsistent Access Patterns**:
   - **WiFi devices** (using Pi-hole DNS): Resolved to local IP → tried to access locally → failed (Caddy not accessible on LAN, no HTTPS locally)
   - **Mobile devices**: Resolved to Cloudflare IP → went through tunnel → worked intermittently
   - **Server health checks**: May have been checking localhost or local IP, getting inconsistent results

**Secondary Issues:**
1. **IPv6 Conflicts**: Similar to other services, Pi-hole was returning both:
   - Local IPv4: `192.168.1.97` (from Local DNS Record)
   - Cloudflare IPv6: `2606:4700:...` (from upstream DNS)
   - Browsers preferred IPv6, causing unpredictable behavior

2. **Caddy Configuration Issues**:
   - Initial Caddy syntax error (mentioned as fixed, but timing suggests it contributed to problems)
   - Caddy only accessible on `localhost:8080`, not on LAN interface
   - No local HTTPS (Caddy has `auto_https off`)

3. **Health Check Failures**:
   - Health check script (`enhanced-health-check.sh`) checks HTTP status codes via external URLs
   - When WiFi devices resolved to local IP, health checks may have failed
   - Intermittent failures caused health check system to report Mattermost as unstable

4. **Intermittent 530/502 Errors**:
   - **530 errors**: Cloudflare-specific errors (tunnel connection issues, rate limiting)
   - **502 errors**: Bad Gateway (Caddy couldn't reach Mattermost, or tunnel couldn't reach Caddy)
   - Pattern matches the WiFi access issue - worked sometimes (mobile/external) but not others (WiFi/local)

**What "Tried Everything" Likely Included:**
Based on the troubleshooting log and README documentation:
- ✅ Fixed Caddy syntax error
- ✅ Fixed health check configuration
- ✅ Attempted DNS configuration changes
- ✅ Tested webhook connectivity (ntfy.sh intermittent 530 errors)
- ✅ Configured Pi-hole DNS records
- ✅ Tried IPv6 disabling (mentioned in README)
- ❌ **Did NOT remove Pi-hole Local DNS Record** (same solution as WiFi fix)

**Solution That Would Have Worked:**
The same solution that fixed WiFi access would have fixed Mattermost:
1. Remove Pi-hole Local DNS Record for `mattermost.gmojsoski.com`
2. Let all devices (WiFi and mobile) use Cloudflare DNS
3. All requests go through Cloudflare Tunnel consistently
4. No local network access issues
5. Consistent behavior across all networks

**Why It Wasn't Obvious:**
- Multiple symptoms (530/502 errors, health check failures, DNS issues) made it hard to identify single root cause
- Health check and Caddy syntax errors were genuine issues that masked the underlying DNS problem
- Intermittent nature (worked on mobile, failed on WiFi) made it seem like multiple problems
- The pattern wasn't clear until we saw the same issue with other services (cloud.gmojsoski.com)

**Lesson Learned:**
When a service works on mobile/external but not on WiFi/local network, check:
1. **Pi-hole Local DNS Records** - Are they causing local IP resolution?
2. **IPv6 conflicts** - Is Pi-hole returning both local IPv4 and Cloudflare IPv6?
3. **Caddy accessibility** - Is Caddy reachable from LAN, or only localhost?
4. **Remove Local DNS Records** - For services using Cloudflare Tunnel, let all devices use Cloudflare DNS consistently

**Note:** Mattermost was removed before this root cause was identified. The same pattern was seen with other services and fixed by removing Pi-hole Local DNS Records.

## [2026-01-10] Mattermost Reinstallation - Successful Setup

**Date:** 2026-01-10
**Action:** Mattermost reinstalled using Zulip's proven configuration pattern

### ✅ Setup Completed
- Created Mattermost docker-compose.yml following Zulip's pattern
- Configured PostgreSQL 15 database (no AVX requirement)
- Port mapping: 8066 (host) → 8065 (container) to avoid conflict with RocketChat
- Added Mattermost to Caddyfile with proper headers (no gzip - prevents real-time/webhook issues)
- Added Mattermost to Cloudflare Tunnel config
- Added Mattermost management commands to Makefile
- Updated verify-services.sh to include Mattermost
- Created comprehensive README with setup instructions and troubleshooting

### 🔧 Configuration Highlights
- **Port**: 8066 (host) → 8065 (container) - avoids RocketChat conflict on 8065
- **Database**: PostgreSQL 15 (no AVX requirement, compatible with CPU)
- **Access**: `https://mattermost.gmojsoski.com` via Cloudflare Tunnel
- **Caddy Config**: NO gzip encoding (like Zulip) - prevents real-time feature issues
- **DNS**: **NO Pi-hole Local DNS Record** - learned from previous WiFi access issues

### ✅ Verification
- **HTTP Status**: HTTP 200 ✅
- **Mattermost Version**: 11.2.1 (latest)
- **Container Status**: Running and healthy
- **Database**: PostgreSQL healthy
- **External Access**: Working via Cloudflare Tunnel
- **WiFi Access**: Working (no Pi-hole Local DNS Record - same fix as other services)

### 📝 Key Lessons Applied
1. **No Pi-hole Local DNS Records** - All devices use Cloudflare DNS for consistent access
2. **No gzip encoding** - Prevents issues with real-time features and webhooks (same as Zulip)
3. **Proper headers** - X-Forwarded-Proto, X-Forwarded-Ssl, Host headers configured
4. **Port conflict avoidance** - Used 8066 instead of 8065 (RocketChat is on 8065)

### 🚀 Management Commands
```bash
# From project root
make lab-mattermost-start    # Start Mattermost
make lab-mattermost-stop     # Stop Mattermost
make lab-mattermost-restart  # Restart Mattermost
make lab-mattermost-logs     # View logs
make lab-mattermost-status   # Check status
```

### 📍 Access URLs
- **External HTTPS**: `https://mattermost.gmojsoski.com` (recommended - all devices)
- **Local Direct**: `http://localhost:8066` (from server)

### ✅ Success Factors
- Used Zulip's proven configuration pattern
- Applied lessons learned from WiFi access issue (no Pi-hole Local DNS Record)
- Proper Caddy configuration (no gzip, correct headers)
- Correct port mapping to avoid conflicts
- Comprehensive documentation and troubleshooting guide

**Status**: ✅ Fully operational - Mattermost is up and running successfully

### RocketChat Installation & Removal
**Date:** 2026-01-10
**Service:** RocketChat Team Communication Platform

**Configuration Attempted:**
- Port: 3002 → 8065 (port conflicts resolved)
- Database: MongoDB 4.4 → 5.0 (AVX compatibility issues)
- RocketChat Version: Latest (7.12.2) → 6.6.4 (MongoDB 4.4 compatibility)
- Domain: `rocketchat.gmojsoski.com`

**Issues Encountered:**
- **CPU Compatibility**: Intel Pentium G4560T doesn't support AVX (required by MongoDB 5.0+)
- **MongoDB Version Conflict**: RocketChat 7.12.2 requires MongoDB 5.0+, but CPU can't run MongoDB 5.0+
- **Solution Attempted**: RocketChat 6.6.4 with MongoDB 4.4 (compatible versions)
- **Final Issue**: RocketChat 6.6.4 container stuck initializing, never fully started despite MongoDB being healthy

**Reason for Removal:**
- RocketChat container stuck in initialization loop (not crashing, but never completing startup)
- User requested alternative solution with better webhook support
- Zulip chosen as replacement (PostgreSQL-based, no AVX requirement, excellent webhook support)

**Files Removed:**
- RocketChat containers stopped (not deleted yet - can be cleaned up later)
- Configuration files updated to use Zulip instead

### Zulip Installation
**Date:** 2026-01-10
**Service:** Zulip Team Communication Platform

**Configuration:**
- Port: 8070 (host) → 80 (container), 8444 → 443
- Database: PostgreSQL 15 (no AVX requirement! ✅)
- Additional Services: Redis, RabbitMQ, Memcached
- Storage: Local filesystem (Docker volumes)
- Domain: `zulip.gmojsoski.com`

**Setup Completed:**
- Created Zulip docker-compose.yml with all dependencies (PostgreSQL, Redis, RabbitMQ, Memcached)
- Configured EXTERNAL_HOST to `zulip.gmojsoski.com`
- Added Caddy reverse proxy configuration (production and repo)
- Added Cloudflare Tunnel ingress rule
- Added to Makefile with `lab-zulip-*` commands
- Added to LAB_COMMANDS.md
- Added to verify-services.sh
- Created comprehensive README.md with webhook documentation

**Advantages:**
- ✅ **No AVX requirement** - Works on older CPUs
- ✅ **PostgreSQL-based** - Stable, well-supported database
- ✅ **Excellent webhook support** - Built-in webhook API, Slack-compatible
- ✅ **Threading model** - Unique topic-based organization
- ✅ **Active development** - Well-maintained open-source project

**Files Created/Modified:**
- `docker/zulip/docker-compose.yml` (created)
- `docker/zulip/README.md` (created)
- `/home/docker-projects/caddy/config/Caddyfile` (replaced RocketChat with Zulip block)
- `docker/caddy/Caddyfile` (replaced RocketChat with Zulip block - repo copy)
- `Makefile` (replaced `lab-rocketchat-*` with `lab-zulip-*` commands)
- `restart services/LAB_COMMANDS.md` (replaced RocketChat with Zulip commands)
- `scripts/verify-services.sh` (replaced `rocketchat.gmojsoski.com` with `zulip.gmojsoski.com`)
- `README.md` (updated to Zulip, removed RocketChat references)
- `~/.cloudflared/config.yml` (replaced RocketChat ingress with Zulip)

**Access Information:**
- **External HTTPS:** https://zulip.gmojsoski.com (via Cloudflare Tunnel)
- **Local Direct:** http://localhost:8070 (from server)
- **Local Network:** http://192.168.1.97:8070 (direct IP access)
- **Local Domain:** http://zulip.gmojsoski.com:8080 (via Caddy, requires DNS)

**Note:** Zulip's docker-zulip image may require initialization script on first start. Configuration provided is a starting point - may need adjustment based on actual docker-zulip image requirements.

**Next Steps:**
1. Start Zulip: `make lab-zulip-start`
2. Wait 2-5 minutes for initialization (database setup, migrations)
3. Access `https://zulip.gmojsoski.com` or `http://localhost:8070`
4. Complete setup wizard (create organization, admin account)
5. Configure webhooks via Admin panel → Integrations → Webhooks

**Final Status:** RocketChat removed due to initialization issues. Replaced with Zulip.

## [2026-01-07] Cloudflare Tunnel Certificate Configuration Error

**Symptoms:**
- Cloudflare tunnel replicas showing error: `ERR Cannot determine default origin certificate path`
- Error appeared in logs but tunnel was still functioning
- Both replicas (cloudflared-1 and cloudflared-2) showing the same error on startup

**Root Cause:**
- The `cert.pem` file exists at `/home/goce/.cloudflared/cert.pem` on the host
- Docker containers mount the directory but cloudflared couldn't find the certificate in default search paths
- Config file didn't explicitly specify the `origincert` path

**Fix:**
- Added `origincert: /home/goce/.cloudflared/cert.pem` to `~/.cloudflared/config.yml`
- Restarted tunnel containers: `cd /home/docker-projects/cloudflared && docker compose restart`
- Verified in logs: Settings now show `origincert:/home/goce/.cloudflared/cert.pem`
- Error eliminated from logs

**Verification:**
- External access working (HTTP 200)
- Both replicas running without certificate errors
- Tunnel connections established successfully

**Files Modified:**
- `/home/goce/.cloudflared/config.yml` - Added `origincert` line

## [2026-01-04] Service Down (502 Errors) after System Freeze

**Symptoms:**
- All services accessible internally and directly via Caddy.
- External access via Cloudflare Tunnel returning intermittent 502 errors (approx. 60% failure rate).
- Bookmarks service returning 502 permanently.

### Issue 1: Cloudflare Tunnel Instability
**Root Cause:**
- Multiple `cloudflared` replicas (2) running on host network were creating too many connections (8 total).
- UDP buffer sizes were too small (`net.core.wmem_max` & `rmem_max` = 212992), causing connection drops under load/instability.
- Logs showed: `ERR Request failed error="Incoming request ended abruptly: context canceled"` and `Application error 0x0` (QUIC packet loss).

**Fix:**
- Increased BOTH UDP buffer sizes to **25MB** (Overkill setting for stability).
- Command: `sudo sysctl -w net.core.wmem_max=26214400 net.core.rmem_max=26214400`
- Persistence: Added both settings to `/etc/sysctl.d/99-cloudflared.conf`.

### Issue 2: Bookmarks Service (Flask) Port Conflict
**Root Cause:**
- `shairport-sync` (AirPlay receiver) was starting on boot and claiming port **5000**.
- The Flask bookmarks service tries to bind to port 5000 and crashes if it's taken.
- Health check system didn't resolve this because it only checked if service was "active" (and crash-looping counts as activating).

**Fix:**
- Identified conflict using `sudo lsof -i :5000`.
- Disabled unused AirPlay service: `sudo systemctl disable --now shairport-sync`.
- Updated `enhanced-health-check.sh` to specifically check for port 5000 conflicts and kill unauthorized processes.

## General Recovery Commands

If 502 errors return, run the cleanup/recovery script:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-external-access.sh"
```

## [2026-01-04] Service Inaccessibility & Mobile "File Download" Issue

### 🔴 Symptoms
1.  **Global 502/503 Errors:** All services (`gmojsoski.com`, `jellyfin`, `cloud`, etc.) intermittently returning 502 Bad Gateway.
2.  **Persistent 404 on Jellyfin:** Even when Root domain worked, Jellyfin maintained a 404 (Cloudflare page).
3.  **Mobile Browsers "Downloading" file:** Instead of loading the Jellyfin/Vaultwarden login page, mobile browsers (Chrome/Safari) would attempt to download a blank file or show a white screen.
4.  **Health Check Fails:** Automated health check couldn't find the repair script.

### 🔍 Root Causes identified
1.  **Cloudflared Networking:** The `cloudflared` container runs in `network_mode: host`. Attempts to bind ingress rules to `127.0.0.1` or the LAN IP (`192.168.1.97`) caused instability and 502s due to loopback/interface quirks in this mode.
2.  **Ingress Mismatch (404):** The 404s were due to configuration drift where the running process held a different config state than the file on disk during debugging.
3.  **Mobile "Blank Page" (Compression):** Caddy was applying `encode gzip` to Jellyfin and Vaultwarden. These applications (and their mobile clients) often handle compressed initial handshakes poorly, or Cloudflare double-compression caused issues.
4.  **Missing SSL Signals:** Mobile clients were not receiving the `X-Forwarded-Ssl: on` header, causing them to treat the connection as insecure or improperly redirect.

### ✅ Fixes Applied
1.  **Ingress Configuration:** Reverted and locked `~/.cloudflared/config.yml` to use `http://localhost:8080` for ALL services. This is the correct way to address Caddy on the host when running in `network_mode: host`.
2.  **Robust Restart:** Updated `fix-external-access.sh` to use `docker compose down && docker compose up -d` instead of just `restart`. This forces a clean state.
3.  **Caddyfile Optimization:**
    *   **Disabled Gzip:** Removed `encode gzip` for `@jellyfin` and `@vault` blocks.
    *   **Added Headers:** Injected `header_up X-Forwarded-Ssl on` for these services.
4.  **Health Check:** Updated `/usr/local/bin/enhanced-health-check.sh` to match the repo version, fixing the path to the repair script.
5.  **Redundancy:** Confirmed `replicas: 2` in `docker-compose.yml` for Cloudflared.

### 🧪 Verification
*   `curl -I https://gmojsoski.com` -> **HTTP 200**
*   `curl -I https://jellyfin.gmojsoski.com/web/index.html` -> **HTTP 200** (was 302 loop/download)
*   **Mobile Test:** Validated login page loads correctly without downloading files.


## [2026-01-06] Paperless-ngx Addition Caused Global 502 Outage

### 🔴 Symptoms
1.  **Global 502/503 Errors:** After adding Paperless-ngx, external access to ALL services (Jellyfin, Nextcloud, etc.) began failing with 502 Bad Gateway.
2.  **Paperless CSRF Failed:** Paperless logs showed `Forbidden (403) CSRF verification failed. Request aborted.` and `DisallowedHost` errors.
3.  **Config Drift:** `~/.cloudflared/config.yml` was found to have reverted to `127.0.0.1` instead of `localhost`.

### 🔍 Root Causes identified
1.  **Configuration Reversion:** Some process or manual edit reverted `~/.cloudflared/config.yml` ingress rules from `http://localhost:8080` (stable) to `http://127.0.0.1:8080` (unstable on this host setup). This caused the Cloudfared tunnel to lose connectivity to Caddy intermittently.
2.  **Over-Engineering Caddy:** The initial Caddyfile entry for Paperless included unnecessary headers (`X-Forwarded-Host`, `Host`) that conflicted with the reverse proxy flow, causing CSRF validation in Django (Paperless) to fail.
3.  **Missing SSL Header:** Initially missing `X-Forwarded-Ssl: on` caused redirect loops.

### ✅ Fixes Applied
1.  **Simplified Caddy Config:** Removed all manual header overrides from the Paperless Caddy block. Used the standard `reverse_proxy` directive.
    ```caddyfile
    handle @paperless {
        reverse_proxy http://172.17.0.1:8097
    }
    ```
2.  **Enforced Localhost:** Reverted `~/.cloudflared/config.yml` to use `http://localhost:8080` for the Paperless ingress rule and all other services.
3.  **Integrity Check:** Added `check_config_integrity` function to `enhanced-health-check.sh` to automatically detect and fix if the config reverts to `127.0.0.1` again.
4.  **Service Verification:** Created `scripts/verify-services.sh` to quickly validate HTTP 200/302 status for all subdomains.

### 🧪 Verification
*   Paperless now accessible at `https://paperless.gmojsoski.com` (HTTP 200).
*   All other services restored.
*   Mobile access confirmed.

## [2026-01-08] Mobile Download/Blank Page Issue - Health Check Gap

### 🔴 Symptoms
1. **Mobile browsers downloading .txt files** instead of rendering pages for Jellyfin, Paperless, Tickets, Cloud
2. **Services returning HTTP 200/302** (appearing healthy to health check)
3. **Desktop/WiFi working fine** - only mobile network affected
4. **Issue persisted after Cloudflare cache purge**

### 🔍 Root Causes Identified
1. **Caddyfile Configuration Drift:** `encode gzip` was re-added to mobile-sensitive services (Jellyfin, Paperless, Tickets, Cloud)
2. **Cloudflare Double-Compression:** Caddy compresses → Cloudflare compresses again → Mobile browsers get confused
3. **Health Check Limitation:** Script only checks HTTP status codes (200/302), not:
   - Content-Type headers
   - Compression settings
   - Mobile browser compatibility
   - Caddyfile configuration integrity

### ✅ Fixes Applied
1. **Removed `encode gzip`** from mobile-sensitive services:
   - `@jellyfin` - removed gzip, kept `X-Forwarded-Ssl on`
   - `@paperless` - removed gzip, added `X-Forwarded-Ssl on`
   - `@tickets` - removed gzip, added `X-Forwarded-Ssl on`
   - `@cloud` - removed gzip, simplified headers
2. **Removed problematic headers:** `Host` and `X-Forwarded-Host` (Caddy handles these automatically)
3. **Added Caddyfile integrity check** to `enhanced-health-check.sh`:
   - Warns if `encode gzip` detected in mobile-sensitive service blocks
   - Prevents silent configuration drift
4. **Scaled Cloudflare tunnel to 1 replica** (reduced complexity)

### 🧪 Verification
*   All services returning HTTP 200/302 ✅
*   Mobile browsers now render pages correctly ✅
*   Health check now monitors Caddyfile configuration ✅

### 📝 Lessons Learned
- **Health checks must validate configuration, not just status codes**
- **Mobile clients are more sensitive to compression issues than desktop**
- **Cloudflare edge caching can persist issues even after server fixes**
- **Configuration drift detection is critical for preventing regressions**

### 🔧 Prevention
- Health check now includes `check_caddyfile_integrity()` function
- Monitors for `encode gzip` in: `@jellyfin`, `@paperless`, `@vault`, `@tickets`, `@cloud`
- Logs warnings when problematic config detected (requires manual fix to ensure proper headers)

## [2026-01-10] WiFi Access Issue - Services Accessible on Mobile Network but Not WiFi

### 🔴 Symptoms
1. **Services work on mobile network**: `cloud.gmojsoski.com` and other services accessible via HTTPS on mobile data
2. **Services fail on WiFi**: Same services return connection errors or cannot be accessed on WiFi network
3. **DNS resolution difference**: `nslookup` shows both local IP (192.168.1.97) and Cloudflare IPv6 addresses

### 🔍 Root Cause Identified
1. **Pi-hole Local DNS Records**: Pi-hole is configured with Local DNS Records that resolve `*.gmojsoski.com` domains to local server IP (`192.168.1.97`)
2. **Caddy Network Configuration**: Caddy is only accessible on `localhost:8080` (host network), not exposed on LAN interface
3. **No Local HTTPS**: Caddy has `auto_https off`, so there's no SSL certificate for local access
4. **Network Behavior Difference**:
   - **WiFi (using Pi-hole)**: DNS resolves to local IP → client tries HTTPS on local IP → fails (no SSL listener)
   - **Mobile network**: DNS resolves to Cloudflare IP → goes through Cloudflare Tunnel → works correctly

### ✅ Solution
**Remove Local DNS Records from Pi-hole** for all `*.gmojsoski.com` domains that use Cloudflare Tunnel. This ensures:
- All devices (WiFi and mobile) use Cloudflare DNS
- All requests go through Cloudflare Tunnel consistently
- No local network access issues

**Steps to Fix:**
1. **Access Pi-hole Admin**: `http://192.168.1.98/admin` (or your Pi-hole IP)
2. **Navigate to**: Local DNS → DNS Records
3. **Remove entries** for:
   - `cloud.gmojsoski.com`
   - `jellyfin.gmojsoski.com`
   - `paperless.gmojsoski.com`
   - `bookmarks.gmojsoski.com`
   - `tickets.gmojsoski.com`
   - `poker.gmojsoski.com`
   - `files.gmojsoski.com`
   - `analytics.gmojsoski.com`
   - `vault.gmojsoski.com`
   - `shopping.gmojsoski.com`
   - `zulip.gmojsoski.com`
   - Any other `*.gmojsoski.com` subdomains
4. **Save changes** (Pi-hole reloads DNS automatically)
5. **Clear DNS cache** on WiFi devices:
   - Linux: `sudo systemd-resolve --flush-caches`
   - Windows: `ipconfig /flushdns`
   - Android: Toggle WiFi off/on or restart device
6. **Verify**: `nslookup cloud.gmojsoski.com` should now show only Cloudflare IPs (no local IP)

### 🧪 Verification
- WiFi devices can now access `https://cloud.gmojsoski.com` ✅
- Mobile devices continue to work ✅
- Consistent behavior across all networks ✅

### 📝 Note
If you want local network access (bypassing Cloudflare Tunnel), you would need to:
1. Configure Caddy to listen on LAN interface (not just localhost)
2. Set up proper SSL certificates for local access
3. Or use explicit port `http://cloud.gmojsoski.com:8080` (but browsers prefer HTTPS)

**Recommendation**: Remove Pi-hole Local DNS Records and use Cloudflare Tunnel for all access. This provides:
- Consistent behavior across networks
- Better security (Cloudflare DDoS protection)
- SSL termination handled by Cloudflare
- No local network configuration needed

---

## [2026-01-16] Backup Cron Job Failing - Permission Denied on Log File

**Date:** 2026-01-16
**Action:** Backup verification script detected backups haven't run in 17 days (last backup: Dec 30, 2025)
**Result:** Backup cron job configured but not executing due to log file permission error

### 🔴 Symptoms
- Backup verification script reports backups haven't run in 17 days
- Last backup created: Dec 30, 2025 at 21:07
- Cron service is running and active
- Backup cron job configured in `/etc/crontab`
- No errors in cron logs about backup execution
- Manual backup execution works correctly

### 🔍 Root Cause Identified
1. **Log File Permission Issue**: Cron job configured to write logs to `/var/log/backup-all-critical.log`
2. **User Permission Denied**: User `goce` cannot create/write to `/var/log/` directory (requires root/sudo)
3. **Cron Job Failing Silently**: When cron tries to redirect output (`>> /var/log/backup-all-critical.log 2>&1`), it fails due to permission denied, causing the entire cron job to fail
4. **No Log File Exists**: `/var/log/backup-all-critical.log` doesn't exist, and user `goce` cannot create it

### ✅ Solution Applied
1. **Created Fix Script**: `scripts/fix-backup-cron-log.sh` to update crontab log path
2. **Changed Log Location**: Updated crontab to use user-writable log directory:
   - **Old**: `/var/log/backup-all-critical.log` (requires root)
   - **New**: `/home/goce/Desktop/Cursor projects/Pi-version-control/logs/backup-all-critical.log` (user-writable)
3. **Fix Script Actions**:
   - Backs up original `/etc/crontab` before changes
   - Creates log directory if it doesn't exist
   - Updates crontab entry using `sed` to replace log path
   - Verifies the change was applied correctly

### 🔧 Fix Script Usage
```bash
# Run the fix script (requires sudo)
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-backup-cron-log.sh"

# After fix, verify crontab entry
grep "backup-all-critical" /etc/crontab

# Monitor next backup run (at 2:00 AM)
tail -f "/home/goce/Desktop/Cursor projects/Pi-version-control/logs/backup-all-critical.log"
```

### 📝 Key Lessons Learned
1. **User-Writable Log Directories**: Always use user-writable log directories for user cron jobs, not `/var/log/`
2. **Cron Permission Failures**: Cron jobs fail silently when output redirection fails (permission denied)
3. **Log Directory Best Practice**: Use project-specific log directories (e.g., `$PROJECT_DIR/logs/`) instead of system log directories
4. **Verification Script Value**: Backup verification script successfully detected the issue (missing/old backups)

### ✅ Verification
After fix is applied:
- Backup cron job will execute at 2:00 AM daily ✅
- Logs will be written to user-writable location ✅
- Backup verification script will detect new backups ✅

### 📝 Related Files
- **Cron Job**: `/etc/crontab` (line with `backup-all-critical.sh`)
- **Fix Script**: `scripts/fix-backup-cron-log.sh`
- **Log Location**: `logs/backup-all-critical.log` (after fix)
- **Backup Script**: `scripts/backup-all-critical.sh`

## [2026-02-22] Hardware Upgrade & Docker Data Migration

**Date:** 2026-02-22
**Action:** Attached a new 1TB HDD, formatted it to ext4, mounted it to `/mnt/storage`, and migrated the Docker root directory from root (`/var/lib/docker`) to `/home/docker-data`.
**Result:** Reclaimed space on the root partition and enabled large local storage for extensive data like Kiwix archives.

### ✅ Changes Made
1. **1TB HDD Setup:** Formatted `/dev/sda1` to `ext4` and mounted it at `/mnt/storage` using its UUID in `/etc/fstab` to ensure survival across reboots or moving between dock and SATA.
2. **Docker Migration:**
   - Stopped Docker service and socket.
   - Synchronized all data using `rsync -aP /var/lib/docker/ /home/docker-data/`.
   - Reconfigured Docker daemon via `/etc/docker/daemon.json` setting `"data-root": "/home/docker-data"`.
   - Renamed old directory (`/var/lib/docker.old`) to preserve as a temporary backup.
3. **Kiwix Setup:**
   - Created `/mnt/storage/kiwix-data/` to hold `.zim` archives natively on the new drive.
   - Initialized a resilient background `wget -c` download for the 55GB Wikipedia offline English archive (no-pics).
   - Spun up the Kiwix Docker container serving the directory on port **8089** (since 8088 was already occupied by Portainer).

### 🧪 Verification
- `df -h` confirms `/mnt/storage` has ~916GB available space.
- `docker info` lists `Docker Root Dir: /home/docker-data`.
- Kiwix interface accessible via `http://<device-ip>:8089`.

---

## [2026-02-26] Storage Expansion - 3 New USB HDDs Added (mergerfs Pool)

**Date:** 2026-02-26
**Action:** Connected three external HDDs (2TB, 1TB, 500GB) via USB docking stations, wiped all three, formatted them to `ext4`, and configured a `mergerfs` pool combining the 2TB and 1TB drives.
**Result:** 3TB `mergerfs` storage pool available at `/mnt/storage`. Old 500GB drive mounted separately at `/mnt/disk_old`.

### ✅ Drives Configured

| Drive | Physical Size | Label | Mount Point | Notes |
|-------|--------------|-------|-------------|-------|
| `/dev/sdb` | 1TB | `disk1` | `/mnt/disk1` | Part of mergerfs pool |
| `/dev/sdd` | 2TB | `disk_pool1` | `/mnt/disk2` | Part of mergerfs pool |
| `/dev/sdc` | 500GB (2013) | `disk2` | `/mnt/disk_old` | Isolated - old/possibly unreliable |
| `mergerfs` | ~3TB combined | — | `/mnt/storage` | **Main external storage** |

### 🔧 Steps Performed

1. **Unmounted** auto-mounted NTFS partitions from `/media/goce/`
2. **Wiped** all three drives with `wipefs -a`
3. **Partitioned** all three with GPT + single ext4 partition via `parted`
4. **Formatted** to `ext4` (used `-F` flag to force past NTFS signature detection)
5. **Removed stale old fstab entry** for `UUID=1c5174bc` (previous 1TB `/mnt/storage` drive, no longer present)
6. **Created mount points**: `/mnt/disk1`, `/mnt/disk2`, `/mnt/disk_old`, `/mnt/storage`
7. **Mounted** all three drives individually
8. **Created mergerfs pool**: `/mnt/disk1:/mnt/disk2` → `/mnt/storage` (policy: `mfs` - most free space)
9. **Updated `/etc/fstab`** with UUID-based entries for all 3 drives and the mergerfs pool

### 📍 Fstab Entries Added
```
UUID=fdb8956e-eb47-46c6-a8ff-d9a0e223782f  /mnt/disk1     ext4         defaults,nofail  0  2
UUID=139b09c3-efda-4d88-b9aa-8b20aadd1873  /mnt/disk2     ext4         defaults,nofail  0  2
UUID=a93c91ca-b06b-4a1e-ad4d-353ddf221319  /mnt/disk_old  ext4         defaults,nofail  0  2
/mnt/disk1:/mnt/disk2  /mnt/storage  fuse.mergerfs  defaults,allow_other,use_ino,category.create=mfs,minfreespace=100M,x-systemd.requires=/mnt/disk1,x-systemd.requires=/mnt/disk2  0  0
```

### 🧪 Verification
```
/dev/sdb1  916G  used: 2.1M  avail: 870G  → /mnt/disk1  ✅
/dev/sdd1  1.8T  used: 2.1M  avail: 1.7T  → /mnt/disk2  ✅
/dev/sdc1  458G  used: 2.1M  avail: 435G  → /mnt/disk_old  ✅
mergerfs   2.7T  used: 4.1M  avail: 2.6T  → /mnt/storage  ✅
```
- Write/read test to `/mnt/storage` and `/mnt/disk_old` passed ✅
- `systemctl daemon-reload` run after fstab update ✅

### ⚠️ Notes
- The 500GB drive is from 2013; treat as non-critical storage only.
- Consider running `sudo badblocks -sv /dev/sdc` on the old drive to check health before trusting it.
- **Point Docker volumes, Kiwix data, and media at `/mnt/storage`** for primary use.

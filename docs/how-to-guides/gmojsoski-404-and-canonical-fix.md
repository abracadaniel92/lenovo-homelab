# Fix gmojsoski.com indexing: blog URLs served the homepage, and add a real 404

> **Status: repo-only prep.** Prepared on the Windows dev clone on 2026-08-09.
> Nothing below is live until it is applied **on lemongrab**. Per the governance
> rules, apply where runtime reads the config first, verify, then mirror and
> commit. A repo edit alone has not fixed production.

Handoff note for whoever picks this up on the server: everything needed is in
this file, including the final config content, so you do not have to pull the
dev clone's commits to apply it. If you do pull, the same content is already in
`docker/caddy/Caddyfile` and `docker/caddy/config.d/10-gmojsoski-home.caddy`.

## What was wrong

Google Search Console reported four non-indexing reasons for `gmojsoski.com`:
"Page with redirect", "Not found (404)", "Duplicate without user-selected
canonical", and "Duplicate, Google chose different canonical than user".

**Root cause: the live Caddy `try_files` was `try_files {path} /index.html`.**
It was missing `{path}/index.html`. The portfolio build prerenders `/blog` and
each `/blog/<slug>` to its own `index.html`, and without that rule every one of
those clean URLs fell through to the final `/index.html` fallback and answered
**200 with the homepage**. Measured against production on 2026-08-09:

```
/blog                                 -> <title>Goce Mojsoski · Product & Delivery</title>, canonical https://gmojsoski.com/
/blog/react-ssr-without-a-framework   -> <title>Goce Mojsoski · Product & Delivery</title>, canonical https://gmojsoski.com/
/blog/goatcounter-vs-plausible        -> <title>Goce Mojsoski · Product & Delivery</title>, canonical https://gmojsoski.com/
/blog/react-ssr-without-a-framework/index.html -> correct post title and canonical
```

The prerendered files were on disk and correct. Only the URL resolution was
broken, which is why the build looked healthy. All 11 sitemap URLs resolved to
one page declaring `canonical: /`, which is exactly what the two "Duplicate"
reports describe.

Two secondary findings:

- **`www.gmojsoski.com` answered 200** rather than redirecting, so the entire
  site existed on two hostnames.
- **Nothing on the site ever returned 404.** The `/index.html` catch-all meant
  every stale or typo'd URL answered 200 with the homepage, which Google reads
  as a soft 404. The old portfolio's bare `file_server` did return real 404s,
  which is the likely source of the "Not found (404)" report.

"Page with redirect" is just the `http` to `https` 301 and is expected.

## What changed

| Repo | File | Change |
|---|---|---|
| lenovo-homelab | `docker/caddy/config.d/10-gmojsoski-home.caddy` | `try_files {path} {path}/index.html` (added the middle rule, **removed** the `/index.html` fallback). Split `www` into its own 301 handler. Widened the `no-cache` matcher to the blog paths. |
| lenovo-homelab | `docker/caddy/Caddyfile` | Added a host-matched 404 branch inside the existing global `handle_errors`, serving `/404.html` for `gmojsoski.com` only. |
| portfolio_v2 | `src/components/NotFound.tsx` + `.css` | New 404 page in the site's design system. |
| portfolio_v2 | `src/router.ts` | Unmatched paths are now `notfound`, not `home`. Normalizes `/index.html` and trailing slashes. |
| portfolio_v2 | `scripts/prerender.mjs` | Emits `dist/404.html`: `noindex`, no canonical, no JSON-LD, excluded from `sitemap.xml`. |
| portfolio_v2 | `vite.config.ts` | `vite preview` now mirrors the server for misses, so this is testable locally. |
| portfolio_v2 | `DEPLOY.md`, `CLAUDE.md` | Corrected the note that wrongly called `try_files` an optimisation, which is what let this ship. |

⚠️ **Two governance flags, please confirm you are happy with both:**

1. The change to `docker/caddy/Caddyfile` touches the **global** `handle_errors`
   block, and the constitution says global Caddy changes need an explicit ask.
   It is scoped by a host matcher so other services keep their plain-text
   errors (verified), but it is still a shared file. It cannot live in the
   `config.d` snippet: `handle_errors` is a site-level directive and Caddy
   rejects the config outright if it is nested inside a `handle` block.
2. Caddy configs are append-only sacred files, and this **modifies existing
   lines** in the `gmojsoski` block rather than appending. That is unavoidable:
   the broken `try_files` line is the bug.

## Apply on lemongrab

### 0. Find the live paths, do not trust the docs

The repo is a mirror. Documented paths have drifted (`/home/docker-projects/caddy`
vs `/mnt/ssd/docker-projects/caddy`), so read them off the running container:

```bash
docker inspect caddy --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

That gives you the live `Caddyfile`, the live `config.d/`, and the site root
mounted at `/srv/site`.

### 1. Deploy the site build first

Do this before the Caddy reload. The new Caddy config serves `/404.html`, and
that file only exists in the new build.

```bash
make portfolio-update
```

Confirm the new file landed (path from step 0):

```bash
ls -l /srv/site/404.html
```

Order is a preference, not a hazard: with the new config and no `404.html`, a
miss still returns a 404 status (it falls through to the catch-all file server
for its body). Tested. Nothing 500s either way.

### 2. Edit the live Caddy config

In the live `config.d/10-gmojsoski-home.caddy`, the whole file should read:

```caddy
# Personal homepage: Vite build output synced to /srv/site via scripts/update-portfolio.sh.
# Source repo: portfolio_v2 (github.com/abracadaniel92/portfolio_v2)

# www serves the identical build, so it has to 301 to the apex rather than answer
# 200. Two hosts returning the same bytes is what Search Console reports as a
# duplicate, and rel=canonical alone does not stop Google picking the wrong host.
@gmojsoski_www host www.gmojsoski.com
handle @gmojsoski_www {
	redir https://gmojsoski.com{uri} permanent
}

@gmojsoski host gmojsoski.com
handle @gmojsoski {
	root * /srv/site
	encode zstd gzip
	# {path}/index.html is load-bearing, not an optimisation: the build prerenders
	# /blog and every /blog/<slug> to its own index.html. Without this line those
	# URLs fall through and serve the homepage at 200, so every post looks like a
	# duplicate of / to a crawler.
	#
	# Deliberately NO `/index.html` fallback at the end. With one, every unknown
	# URL answered 200 with the homepage, which Google reads as a soft 404. Now a
	# miss stays a miss and the 404 handler in ../Caddyfile serves dist/404.html
	# with a real 404 status.
	try_files {path} {path}/index.html
	file_server

	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains"
		X-Content-Type-Options "nosniff"
		Referrer-Policy "strict-origin-when-cross-origin"
		Permissions-Policy "camera=(), microphone=(), geolocation=()"
		# analytics.gmojsoski.com allowed in script-src (count.js), connect-src
		# (sendBeacon) and img-src (image fallback) for self-hosted GoatCounter
		Content-Security-Policy "default-src 'self'; script-src 'self' https://analytics.gmojsoski.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self' data: https://analytics.gmojsoski.com; connect-src 'self' https://analytics.gmojsoski.com; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"
		-Server
	}

	@assets path /assets/*
	header @assets Cache-Control "public, max-age=31536000, immutable"
	# Matches the request path, which header sees before try_files rewrites it, so
	# the blog entries have to be listed explicitly.
	@html path / /index.html /blog /blog/*
	header @html Cache-Control "no-cache"
}
```

In the live `Caddyfile`, replace the existing `handle_errors` block with:

```caddy
	# Prevent caching of error responses
	handle_errors {
		header Cache-Control "no-store, no-cache, must-revalidate, max-age=0"

		# gmojsoski.com ships its own prerendered 404 page (dist/404.html), so a
		# miss there gets the real site instead of plain text. Matched here rather
		# than in config.d/10-gmojsoski-home.caddy because handle_errors is a
		# site-level directive: Caddy rejects it inside a handle block.
		@gmojsoski_404 expression {err.status_code} == 404 && {host} == "gmojsoski.com"
		handle @gmojsoski_404 {
			root * /srv/site
			rewrite * /404.html
			# Repeated from the site handler: an error route is a separate route,
			# so it does not inherit that block's headers.
			header {
				Strict-Transport-Security "max-age=31536000; includeSubDomains"
				X-Content-Type-Options "nosniff"
				Referrer-Policy "strict-origin-when-cross-origin"
				Permissions-Policy "camera=(), microphone=(), geolocation=()"
				Content-Security-Policy "default-src 'self'; script-src 'self' https://analytics.gmojsoski.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self' data: https://analytics.gmojsoski.com; connect-src 'self' https://analytics.gmojsoski.com; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"
				-Server
			}
			file_server
		}

		handle {
			respond "{err.status_code} {err.status_text}"
		}
	}
```

### 3. Validate, then reload

```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Verification

Every check below was run locally against this exact config with the real
`dist/`, using the actual homelab `Caddyfile` (adapted only for host and port).
Re-run them against production.

**1. Every sitemap URL serves its own page.** This is the check that catches the
original bug, and a status code will not: the failure mode was 200 with the
wrong content. Each line must print a canonical matching its own URL.

```bash
curl -s https://gmojsoski.com/sitemap.xml | grep -o '<loc>[^<]*</loc>' | sed 's/<[^>]*>//g' | while read -r u; do printf '%s -> ' "$u"; curl -s "$u" | grep -o 'rel="canonical" href="[^"]*"' | head -1; done
```

**2. A miss is a real 404 and returns the styled page.**

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://gmojsoski.com/definitely-not-a-page
```

```bash
curl -s https://gmojsoski.com/definitely-not-a-page | grep -o '<title>[^<]*</title>'
```

Expect `404` and `<title>Page not found · Goce Mojsoski</title>`. Then open it
in a browser: no console errors. A React error #418 means the wrong file was
served and the page is falling back to another route.

**3. The 404 keeps the security headers.** An error route inherits nothing,
which is why they are repeated in the block above.

```bash
curl -sI https://gmojsoski.com/definitely-not-a-page | grep -i -E 'content-security|strict-transport|x-content-type|referrer'
```

**4. www 301s to the apex, preserving the path.**

```bash
curl -sI https://www.gmojsoski.com/blog/goatcounter-vs-plausible | grep -i -E '^HTTP|^location'
```

**5. Other homelab hosts are untouched.** Pick any other service host and
confirm a miss still returns the plain-text error, not the portfolio 404 page.

```bash
curl -s https://<another-service>.gmojsoski.com/definitely-missing | head -c 80
```

**6. Real assets still serve.** `/og-image.png`, `/sitemap.xml`, `/rss.xml`,
`/robots.txt`, `/files/GoceMojsoskiCV.pdf` all 200.

## After it is live

1. Mirror the live config into this repo if you edited live by hand, and commit.
2. Push both repos to `main` (the dev clone's commits are described in the
   troubleshooting-log entry for 2026-08-09).
3. In Google Search Console, hit **Validate Fix** on the two "Duplicate"
   reports. For the "Not found (404)" and "Page with redirect" reports, export
   the URL list first: if they are old-portfolio paths, they are stale and now
   correctly answer 404, so no action is needed beyond letting Google recrawl.
4. Re-submit `sitemap.xml` is not required; it recrawls on its own.

## Rollback

The change is config-only on the server side. To revert, restore
`try_files {path} /index.html` in the `gmojsoski` block, drop the
`@gmojsoski_www` handler, restore the single-line `handle_errors`, then
`docker exec caddy caddy reload --config /etc/caddy/Caddyfile`. The site build
is backwards compatible: `404.html` simply goes unused.

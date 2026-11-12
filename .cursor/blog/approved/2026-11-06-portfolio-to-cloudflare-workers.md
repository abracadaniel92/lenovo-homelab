# Moving my portfolio off the homelab: two ways Cloudflare almost broke my SEO

**Angle:** Moving a static site from self-hosted Caddy to Cloudflare looks like a
five-minute job. Two defaults would have quietly broken every blog URL and
every 404, and the build log was the only hint.

**Story beats:**
- Why move: the homelab is great for me, but the portfolio is the one page
  recruiters see, and it went down with the server, power or ISP
- Default 1: Cloudflare static assets redirect `/blog/post` to `/blog/post/`
  when the file is `post/index.html`. Every canonical and sitemap URL would
  have become a redirect. Fix: prerender flat `post.html` files, plus a
  Caddy `try_files {path}.html` so the homelab copy keeps working
- Default 2: the dashboard's "connect Git" now makes a Worker, and with no
  config `wrangler deploy` rewrites your Vite config on the build server and
  picks SPA mode, which turns every missing URL into a 200 homepage (soft 404)
- Fix: one committed `wrangler.jsonc` with `not_found_handling: "404-page"`
- Verified on `*.workers.dev` before touching DNS: every sitemap URL's
  canonical matched its own address, 404s real, headers on 404s too
- Cutover = delete one tunnel CNAME, add one custom domain; rollback is one
  `cloudflared tunnel route dns` command, Caddy stays as a warm fallback

**Evidence:** lemongrab log 2026-11-06 (two entries); portfolio_v2 commits
c185242, 25a9256; lenovo-homelab 695e2fe.

**Public check:** Leave out: tunnel ID, workers.dev subdomain.

**Outline:**
1. Why move the one page recruiters see off the homelab
2. Default 1: `post/index.html` makes Cloudflare redirect to a trailing slash (and why that breaks canonicals and the sitemap)
3. Fix: prerender flat `post.html`, plus `try_files {path}.html` so the Caddy copy still works
4. Default 2: "connect Git" builds a Worker, and a config-less `wrangler deploy` picks SPA mode, turning every 404 into a 200 homepage
5. Fix: one committed `wrangler.jsonc` with `not_found_handling: "404-page"`, verified on workers.dev before DNS
6. Cutover and rollback: one CNAME out, one custom domain in, Caddy kept as a warm fallback

**Effort:** post

**Priority:** next

**Published:**

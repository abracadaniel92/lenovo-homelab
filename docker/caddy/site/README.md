# gmojsoski.com site root

Static files served by Caddy for `gmojsoski.com` and `www.gmojsoski.com`.

## Source

Built output from [portfolio_v2](https://github.com/abracadaniel92/portfolio_v2):

```bash
cd "/home/goce/Desktop/Cursor projects/portfolio_v2"
npm ci && npm run build   # → dist/
```

## Deploy

From Pi-version-control:

```bash
make portfolio-update
```

This runs `scripts/update-portfolio.sh`, which pulls `portfolio_v2`, builds `dist/`, and rsyncs it here (`/mnt/ssd/docker-projects/caddy/site`, mounted in the container as `/srv/site`).

## Contents

After deploy: `index.html`, hashed `assets/`, favicons, `og-image.png`, `site.webmanifest`, and `files/GoceMojsoskiCV.pdf`.

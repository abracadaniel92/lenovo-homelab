# Portfolio Website

Portfolio website for Goce Mojsoski.

## Development

### Quick Start

Start a local development server:

```bash
npm run dev
```

This will start a server at `http://localhost:8080` (or another port if 8080 is in use).

### Available Scripts

- `npm run dev` or `npm start` - Start development server on port 8080
- `npm run serve` - Same as `npm run dev`
- `npm run preview` - Start preview server on port 3000

### Project Structure

```
portfolio/
├── index.html          # Main HTML file
├── css/                # Stylesheets
├── js/                 # JavaScript files
├── images/             # Images and assets
├── files/              # PDFs and other files
└── Caddyfile          # Caddy web server configuration
```

## Technologies

- HTML5
- CSS3 (Custom CSS + Tailwind CSS via CDN)
- Vanilla JavaScript
- Caddy (for production serving)

## Notes

- The site uses Tailwind CSS via CDN (no build step required)
- All JavaScript is vanilla (no frameworks)
- The site is fully static and can be served from any static file server


# Antarctic Review Hub

Static HTML/CSS site. Plain JavaScript is limited to `js/nav.js` (mobile nav toggle only).

## Structure

```
index.html                  entry point (built)
operators/{slug}/index.html 10 operator pages (built)
methodology/ editorial-policy/ about/ submit-operator/ contact/ privacy-and-cookies/  (built)
components/header.html      shared header markup (source)
components/footer.html      shared footer markup (source)
content/*.html              per-page <main> markup (source)
css/global.css              shared styles
css/ranking.css             homepage-only styles
css/operator.css            operator page template styles
css/page.css                E-E-A-T page styles
js/nav.js                   mobile nav toggle
images/                     favicon, ship silhouettes (images/ships/*.svg)
build.sh                    assembles all pages from components/ + content/
serve.mjs                   local static server (http://localhost:3000)
screenshot.mjs              Puppeteer screenshot helper
```

Never edit the built `index.html` files directly — edit `components/`, `content/`, or `css/` and re-run `bash build.sh`.

## Local development

```bash
npm install
bash build.sh
node serve.mjs
```

Then open http://localhost:3000.

## Adding a new page

1. Create `content/{slug}.html` with only the `<main>` inner markup (no document boilerplate).
2. If it needs unique styles, add them to `css/page.css` or a new page-specific file.
3. Add a call to `assemble()` in `build.sh` with the page's title, description, content file, and output path.
4. Add the URL to `sitemap.xml`.
5. Run `bash build.sh`.

## Data

`build.sh` verifies the published ranking against `_source/operators.json` / `_source/ranking.json` before every build (`_source/verify-scores.mjs`). `_source/` is not committed — see `.gitignore`.

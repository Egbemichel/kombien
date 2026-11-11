# Kombien landing page

The public landing page, served at **egbemichel.tech/kombien** (a path on the
portfolio's domain). The app itself stays at kombien.egbemichel.tech, so
installed copies keep working. The page's main button opens the app; the
install steps on the page explain adding it to the home screen.

It is a plain static page (no framework) in the app's own style: DM Sans, the
app's colours, and the app's own onboarding characters.

```
web/                 what gets served
  index.html         the page
  style.css          the app's design tokens, as CSS
  assets/            fonts, wordmark, app screens, scene.svg
sprites/             the app's characters, cut out and recoloured (build inputs, not served)
scripts/
  build.sh           copies web/ to dist/kombien/ (the path it is served from)
  cut_people.py      cuts the two onboarding characters out of app/assets/illustrations
  make_variants.py   recolours them into five outfits each
  make_scene.py      draws web/assets/img/scene.svg: the roadside, the people, the taxis
wrangler.toml        Cloudflare Worker: static assets, routed to egbemichel.tech/kombien
```

## Working on it

Preview locally (all asset paths are relative, so opening `web/index.html` also works):

```bash
bash scripts/build.sh
python -m http.server 4173 --directory dist   # then open http://localhost:4173/kombien/
```

Change the roadside scene (needs Python with `opencv-python` and `numpy`):

```bash
python scripts/cut_people.py        # only if the onboarding art changes
python scripts/make_variants.py     # recolour into outfits
python scripts/make_scene.py        # writes web/assets/img/scene.svg
```

Everything in the scene is drawn to one scale (see the docstring in
`make_scene.py`). To add more characters, add their cut-out PNG to `sprites/`
and list them in `make_scene.py`.

## Deploying

Pushing to `main` deploys it (`.github/workflows/deploy-landing.yml`). By hand:

```bash
bash scripts/build.sh && npx wrangler deploy
```

The route only claims `egbemichel.tech/kombien` and `/kombien/*`; the rest of
the portfolio is untouched.

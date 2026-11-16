# The website

A free static site on GitHub Pages: a landing page, a press kit, and the
playable web build at `/play`. Until a domain is bought it lives at
https://cyanidesayonara.github.io/path-of-leash-resistance/.

## What is where

```
site/
  index.html        landing page
  press/index.html  press kit
  style.css         one stylesheet for both
  img/              every image, generated (below), never edited by hand
  .gdignore         keeps Godot from importing the folder into the game
```

Plain HTML and CSS, no framework, no build step, no external requests. Links
are relative, so the same files work at `/path-of-leash-resistance/` and at
the root of a custom domain.

`/play` is not in the repository. It is the `leash-resistance-web.zip` that
`release.yml` attaches to each GitHub release, unpacked at deploy time.

## Look and copy

The site wears the game's palette and fonts. `site/palette.css` is generated
from `hud/ui_kit.gd` (run `tools/site_palette.gd` after changing a colour
there; `tests/test_site_palette.gd` fails until you do), `style.css` uses
only its variables, and the fonts are the game's own `fonts/*.ttf`, copied
into `fonts/` by the deploy (copy them into `site/fonts/` by hand for a local
preview; that folder is not committed).

The `<!-- gen:NAME -->` blocks in both pages are filled by
`python tools/site_copy.py` from `store/listing.md` (features, What's new,
description) and the game's walk list (count and names). The deploy runs it
every time, so the live site follows the listing without anyone touching
`site/`; run it locally to preview. After a release the deploy checks out the
tagged commit beside main, renders the images there (`tools/site_media.sh`)
and fills main's pages from its listing (`site_copy.py --from=rel`). A page
missing one of its markers, or with an unclosed one, fails the deploy.

## Images

```
GODOT=godot/Godot_v4.7-stable_win64_console.exe bash tools/site_media.sh
```

Six `--shot` screenshots (JPEG), three clips from `tools/intro_render.gd`
joined by `tools/frames_to_gif.py` (the intro's title over the street, and
the La Neteja and Els Senglars chase films; 128 colors, undithered, which
is what keeps them under a megabyte each), and the icon from
`tools/make_icon.gd`. About 3 MB in all; keep it well under 5. Rerun it after
a visual change worth showing and commit `site/img/`.

## Deploy

One workflow, `.github/workflows/pages.yml`, builds and deploys the whole
site every time. A Pages deploy replaces the entire site, so two workflows
each deploying their own half would wipe each other; one job that always
assembles both halves cannot. It runs:

- on a push to `main` that touches `site/` (or the workflow): `site/` plus
  the web zip of the latest GitHub release
- when a `release.yml` run for a tag finishes: `site/` plus that tag's web
  zip. If the zip did not get attached (that step is allowed to fail), it
  falls back to the newest release that has one, so `/play` never goes
  missing
- by hand (Actions > Website > Run workflow), with the latest release

`release.yml` itself does not deploy: it already exports and attaches the
web zip, and `pages.yml` follows it through `workflow_run`. A `workflow_run`
job runs on the default branch, which keeps it inside the `github-pages`
environment's default-branch-only deployment rule; a deploy straight from a
tag would be refused by that rule.

The web preset has threads off (`variant/thread_support=false`), so the
build needs no cross-origin isolation headers (COOP/COEP), which Pages
cannot send anyway. Pages refuses files over 100 MB; v1.74's `index.wasm` is
39.5 MB and `index.pck` 19 MB, and the workflow fails if any file passes
95 MB. The whole site must stay under Pages' 1 GB.

## Local preview

```
python -m http.server 8000 -d site
```

For `/play` too, unpack a web export (local, or the zip from a release) into
a copy of the site:

```
mkdir -p /tmp/site && cp -r site/. /tmp/site/
unzip -o leash-resistance-web.zip -d /tmp/site/play
python -m http.server 8000 -d /tmp/site
```

and open http://localhost:8000/ and http://localhost:8000/play/.

## One-time setup (not done yet)

1. Repository Settings > Pages > Build and deployment > Source: **GitHub
   Actions**. That creates the `github-pages` environment the workflow
   deploys to.
2. Run the workflow once by hand (Actions > Website > Run workflow) so the
   site exists before the next site change or tag.

Nothing else: no secrets, no branch.

## A custom domain later

When a domain is bought:

1. DNS at the registrar:
   - an apex domain (`example.com`): four `A` records to `185.199.108.153`,
     `185.199.109.153`, `185.199.110.153` and `185.199.111.153`, and
     optionally `AAAA` records to `2606:50c0:8000::153`, `2606:50c0:8001::153`,
     `2606:50c0:8002::153` and `2606:50c0:8003::153`
   - a subdomain (`www.example.com`): one `CNAME` record to
     `cyanidesayonara.github.io`
   - for an apex, also a `www` CNAME to `cyanidesayonara.github.io`, and
     GitHub redirects between the two
2. Add the domain in Settings > Pages > Custom domain, and verify it under
   the account's Settings > Pages (verified domains) so nobody else can claim
   it.
3. The one-line change in the repository: a file `site/CNAME` holding the
   domain and nothing else (`example.com`). With an Actions deploy the
   Settings field is what counts, but the file records it with the site.
4. Once the certificate is issued (minutes to a day), tick **Enforce HTTPS**
   in Settings > Pages.

Links in the site are relative, so nothing else changes. Update the store
pages' website fields and `docs/itch-page.md`'s GitHub About website to the
new address.

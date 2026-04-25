# scrt-link

Automated container build for [stophecom/scrt-link-v2](https://github.com/stophecom/scrt-link-v2), which does not publish its own image.

A GitHub Actions workflow checks the upstream `main` branch daily, and if its HEAD SHA has not been built yet, builds an overlaid Dockerfile against the upstream source and pushes the result to GHCR.

## Image

`ghcr.io/olegstepura/scrt-link`

**Tags:**

- `latest` — always the most recently built commit from upstream `main`.
- `sha-<short>` — specific upstream commit, where `<short>` is the first 7 characters of the commit SHA. Use this for pinning.

## Why an overlay Dockerfile?

Upstream imports several `PUBLIC_*` identifiers from SvelteKit's `$env/static/public`. Those values are inlined into the bundle at build time, so a missing variable causes `pnpm build` to fail (and hard-coded values cannot be overridden at runtime).

Our overlay [`Dockerfile`](Dockerfile):

- Sets **placeholder** values for `PUBLIC_ENV`, `PUBLIC_PRODUCTION_URL`, and `PUBLIC_IMGIX_CDN_URL` at build time (`__PUBLIC_ENV__`, etc.), so Vite's static-import check passes.
- Sets empty strings for `PUBLIC_RECAPTCHA_CLIENT_KEY` and `PUBLIC_STRIPE_PUBLISHABLE_KEY` (features not wired up in the self-hosted deploy).
- Keeps a pristine copy of the build output at `/app/build-template`.

At container startup [`docker-entrypoint.sh`](docker-entrypoint.sh) restores `/app/build` from the template and `sed`-replaces each placeholder with the current value from the environment, so changing a `PUBLIC_*` env var and restarting the container actually takes effect.

## Workflow

Defined in [`.github/workflows/build.yml`](.github/workflows/build.yml).

- **Schedule:** runs once a day (`45 0 * * *` UTC).
- **Manual:** `workflow_dispatch` with an optional `force` input to rebuild the current `main` even if its SHA already has an image.
- **Skip logic:** the `check` job resolves upstream `main`, queries the GHCR package's existing tags, and skips the build if a matching `sha-<short>` tag is already published.
- **Build:** checks out this repo (`overlay/`) and the upstream repo at the resolved SHA (`upstream/`), copies the overlay Dockerfile and entrypoint over the upstream ones, then builds and pushes `latest` + `sha-<short>`.

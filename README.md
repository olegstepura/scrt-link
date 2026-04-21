# scrt-link

Automated container build for [stophecom/scrt-link-v2](https://github.com/stophecom/scrt-link-v2), which does not publish its own image.

A GitHub Actions workflow checks the upstream `main` branch daily, and if its HEAD SHA has not been built yet, builds the upstream `Dockerfile` and pushes the result to GHCR.

## Image

`ghcr.io/olegstepura/scrt-link`

**Tags:**

- `latest` — always the most recently built commit from upstream `main`.
- `sha-<short>` — specific upstream commit, where `<short>` is the first 7 characters of the commit SHA. Use this for pinning.

## Workflow

Defined in [`.github/workflows/build.yml`](.github/workflows/build.yml).

- **Schedule:** runs once a day (`45 0 * * *` UTC).
- **Manual:** `workflow_dispatch` with an optional `force` input to rebuild the current `main` even if its SHA already has an image.
- **Skip logic:** the `check` job resolves upstream `main`, queries the GHCR package's existing tags, and skips the build if a matching `sha-<short>` tag is already published.
- **Build:** checks out the upstream repo at the resolved SHA, builds its `Dockerfile`, and pushes `latest` + `sha-<short>`.

The workflow does not build from this repo's own code — this repo only owns the workflow definition.

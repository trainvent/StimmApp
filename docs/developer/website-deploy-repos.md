# Shared Website Source With Two GitHub Pages Deploy Repos

This repo stays the single source of truth for `website/`.

Two lightweight deploy repos receive the exported static site:

- `Trainvent/stimmapp-website` -> `stimmapp.net`
- `Trainvent/vivot-website` -> `vivot.net`

The website code does not need to fork for this setup. The current site already switches language from `window.location.hostname`, so both deploy repos can publish the same build output.

## How it works

1. Changes land in this repo.
2. The workflow `.github/workflows/publish-website-repos.yml` builds `website/`.
3. The workflow pushes the exported static site into each deploy repo.
4. Each deploy repo serves its own custom domain through GitHub Pages.

## One-time setup in the shared-source repo

Create a fine-grained personal access token with:

- access to `Trainvent/stimmapp-website`
- access to `Trainvent/vivot-website`
- repository contents: read and write

Add it to this repo as:

- `WEBSITE_DEPLOY_TOKEN`

## One-time setup for each deploy repo

Create these repos on GitHub:

- `Trainvent/stimmapp-website`
- `Trainvent/vivot-website`

Initialize each repo with:

- a default branch named `main`
- an empty commit, or a `README.md`

In each deploy repo, open `Settings > Pages` and configure:

- Source: `Deploy from a branch`
- Branch: `main`
- Folder: `/ (root)`

Then set the custom domains:

- `stimmapp-website` -> `stimmapp.net`
- `vivot-website` -> `vivot.net`

Recommended DNS:

- `stimmapp.net` apex -> GitHub Pages A records
- `www.stimmapp.net` -> `CNAME trainvent.github.io`
- `vivot.net` apex -> GitHub Pages A records
- `www.vivot.net` -> `CNAME trainvent.github.io`

The shared-source publish workflow writes the correct `CNAME` file into each deploy repo on every publish.

## First publish

After the token and repos exist:

1. Push this branch to `main`, or run `Publish Website Deploy Repos` manually from Actions.
2. Wait for the workflow to push the built site into both deploy repos.
3. In each deploy repo, wait for GitHub Pages to finish publishing.

## Recommended cleanup after the new setup is live

Once both new deploy repos are working:

1. Remove the custom domain from this source repo's Pages settings.
2. Disable or delete `.github/workflows/deploy-pages.yml` in this repo if it is no longer needed.
3. Keep only the shared-source publish workflow as the deployment path.

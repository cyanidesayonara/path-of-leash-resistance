## 2026-11-22 - Release secrets in GitHub environments

- The release secrets move into three GitHub environments: `store` (Partner
  Center, main only), `itch` (butler) and `google-play` (Android signing and
  the Play service account), both of those deploying from v* tags and main.
  Each job that reads one declares its environment and a matching `if:`.
- No workflow writes a secret, an input or any other expression into a shell
  script any more; they reach scripts through `env:`. Store submit checks its
  tag input's shape before anything runs.
- A release dispatched from a branch no longer pushes a `manual-<sha>` build
  to itch; dispatch on the tag, as the escape hatch always meant.
- New: `credentials.yml` checks the itch and Play secrets without publishing,
  and `tests/test_workflow_secrets.py` (CI) holds every workflow to all this.
  `docs/release-secrets.md` lists each secret, its environment and its source.

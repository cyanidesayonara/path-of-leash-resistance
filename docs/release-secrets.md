# Release secrets and GitHub environments

Every production secret lives in a GitHub **environment**, never as a
repository secret, so only the jobs that ship can read it, and only from the
refs that ship. A job on a pull request, a feature branch or a forked
workflow sees none of them.

Each job that reads a secret has two locks: the environment's deployment rule
(set in GitHub), and a job-level `if:` that says the same thing in the
workflow, so a job from the wrong ref is skipped rather than refused.
Secrets reach scripts only through `env:` and are read as shell variables
(`"$BUTLER_API_KEY"`); no `run:` script contains `${{ ... }}`, for secrets,
workflow inputs or anything else. `tests/test_workflow_secrets.py` (CI,
shard 1) fails on any job that reads a secret outside its environment, on a
missing `if:`, on a secret in the wrong environment or missing from this
page, and on any `${{` in a `run:` script.

## The three environments

| Environment | Deploys from | Jobs | Secrets |
|---|---|---|---|
| `store` | branch `main` | `store-submit.yml` submit | `PARTNER_CENTER_TENANT_ID`, `PARTNER_CENTER_SELLER_ID`, `PARTNER_CENTER_CLIENT_ID`, `PARTNER_CENTER_CLIENT_SECRET` |
| `itch` | tags `v*`, branch `main` | `release.yml` publish, `credentials.yml` itch | `BUTLER_API_KEY` |
| `google-play` | tags `v*`, branch `main` | `release.yml` android, `credentials.yml` google-play | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` |

Why this split:

- **`store`, main only.** Store submit is dispatched by hand and reads
  `store/listing.md` from main; it never needs a tag ref (the tag is an input,
  checked against `^v[0-9]+(\.[0-9]+){1,2}$` before anything else runs).
- **`itch` and `google-play`, one per store.** The release jobs run on a
  `v*` tag. Keeping itch and Play apart means a leaked or rotated Play key
  never touches itch's job and the reverse; the Android signing key sits with
  Play because the `android` job is its only reader. `main` is allowed only
  so `credentials.yml` can check the secrets from main; every `release.yml`
  job carries `if: github.ref_type == 'tag' && startsWith(github.ref_name, 'v')`,
  so nothing publishes from main. (A release dispatched from a branch used to
  push a `manual-<sha>` build to itch; it now skips. Dispatch on the tag for
  the escape hatch, as before.)
- The MSIX job (`release.yml` msix, `msix.yml`) and the website (`pages.yml`,
  the `github-pages` environment) use only `github.token` and need no
  environment of their own.

## Where each value comes from

| Secret | Source |
|---|---|
| `PARTNER_CENTER_TENANT_ID` | Microsoft Entra tenant ID of the account that owns the Partner Center seller (Azure portal > Microsoft Entra ID > Overview, or Partner Center > Account settings > Tenants). Same value as Stemma's. |
| `PARTNER_CENTER_SELLER_ID` | Partner Center > Account settings > Legal info > Developer, "Seller ID". Same as Stemma's. |
| `PARTNER_CENTER_CLIENT_ID` | The Entra app registered for the Store submission API (Partner Center > Account settings > User management > Microsoft Entra applications), its Application (client) ID. Same as Stemma's. |
| `PARTNER_CENTER_CLIENT_SECRET` | A client secret of that Entra app (Azure portal > App registrations > the app > Certificates & secrets). Shared with Stemma: a new one must be put in both repositories' `store` environments. |
| `BUTLER_API_KEY` | itch.io > Settings > API keys (https://itch.io/user/settings/api-keys), a key of the account that owns `cyanidesayonara/path-of-leash-resistance`. |
| `ANDROID_KEYSTORE_BASE64` | The upload keystore made with `keytool -genkeypair` (docs/android-play-store.md), as `base64 -w0 upload.keystore`. Keep the keystore file itself out of the repository and backed up: Play only accepts bundles signed with its upload key. |
| `ANDROID_KEY_ALIAS` | The alias given to `keytool -genkeypair` (`upload`). |
| `ANDROID_KEY_PASSWORD` | The keystore's password, which is also the key's (Godot's export uses one password for both). |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | A JSON key of a Google Cloud service account invited in Play Console > Users and permissions with release rights for the app. Optional: without it the `android` job builds and attaches the bundles but skips the Play upload. |

## Setting them up (GitHub > Settings > Environments)

For each environment: New environment, then under **Deployment branches and
tags** pick "Selected branches and tags" and add the rules from the table
(a branch rule `main`, a tag rule `v*`), then add its secrets under
**Environment secrets**. Required reviewers are optional; with one on `itch`
or `google-play`, a tag's release waits for your approval in the Actions run.

Leave the repository secrets in place until each environment is verified
(below), then delete them under Settings > Secrets and variables > Actions:
the jobs read the environment's secret when both exist, so nothing depends
on the repository copies once the environments are set.

## Checking them without publishing

- **`store`:** Actions > Store submit (manual) > Run workflow from `main`,
  mode `configure`, tag `v1.75`. It runs `msstore reconfigure` and
  `msstore info` and stops: nothing in Partner Center changes.
- **`itch` and `google-play`:** Actions > Check release credentials (manual)
  > Run workflow from `main` (`credentials.yml`). Its itch job lists the
  game's channels with butler (`butler status`). Its google-play job opens
  the keystore and signs a throwaway certificate request with the key (so
  the alias and password are right), then, if the service account is set,
  gets a Play API token and opens an edit of the app and deletes it unsaved
  (`tools/play_credentials.py`), which is what fastlane's key check does.
- Run from any other branch, every job above is skipped, which is the
  `if:` guard working; to see the environment rule refuse on its own, remove
  `main` from an environment's rule and run the check again (the job fails
  with "not allowed to deploy"), then put it back.

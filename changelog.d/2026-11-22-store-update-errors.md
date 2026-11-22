## 2026-11-22 - Name the Store's refusal of a listing update

- `store-submit.yml` runs `msstore submission updateMetadata` with `--verbose` and, when it fails, shows its error lines with every upload link stripped, instead of a bare "Error!" (the v1.76 draft stopped there with no reason given). A successful update no longer prints its output; the next step reads the draft back.

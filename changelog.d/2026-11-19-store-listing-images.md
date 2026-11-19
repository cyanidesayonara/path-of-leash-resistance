## 2026-11-19 - Store listing images staged by the submit workflow

- The Store submit workflow's `update_draft` now renders the listing's screenshots (the ordered list in `store/screenshots.txt`, at 1920x1080) and the Store logos from the tag being submitted, and stages them in the draft with the package: the Store's current images marked PendingDelete, the new ones PendingUpload, one zip of the MSIX and images PUT to the draft's upload URL (`tools/store_images.py`, ported from Stemma). Nobody uploads images in Partner Center by hand anymore.
- `submit` now refuses unless the draft is PendingCommit, its package is the tag's and its What's new is the listing's; it reads msstore's status from stderr too. Every run reports the publish mode and warns when it is Manual.
- msstore's printed upload URL is masked and redacted in the logs.

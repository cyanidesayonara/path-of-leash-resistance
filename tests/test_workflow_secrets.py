"""Production secrets stay in their GitHub environments, and no workflow
writes an expression into a shell script.

    python tests/test_workflow_secrets.py

Every job that reads a secret must be one listed in JOBS, declare that
environment, and carry the job-level if: that restricts where it runs (the
environment's own deployment rule is the other half, set in GitHub). A
secret may only be one its environment holds (ENVIRONMENTS) and must be
named in docs/release-secrets.md. No run: script anywhere may contain
${{ ... }}: secrets, inputs and event fields reach scripts through env:.
The workflows are read line by line, so no YAML package is needed.
"""

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
DOC = ROOT / "docs" / "release-secrets.md"

ON_MAIN = "github.ref == 'refs/heads/main'"
ON_TAG = "github.ref_type == 'tag' && startsWith(github.ref_name, 'v')"

ENVIRONMENTS = {
    "store": {"PARTNER_CENTER_TENANT_ID", "PARTNER_CENTER_SELLER_ID",
              "PARTNER_CENTER_CLIENT_ID", "PARTNER_CENTER_CLIENT_SECRET"},
    "itch": {"BUTLER_API_KEY"},
    "google-play": {"ANDROID_KEYSTORE_BASE64", "ANDROID_KEY_ALIAS",
                    "ANDROID_KEY_PASSWORD", "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"},
}

# (workflow, job): (environment, the condition its if: must contain)
JOBS = {
    ("store-submit.yml", "submit"): ("store", ON_MAIN),
    ("release.yml", "publish"): ("itch", ON_TAG),
    ("release.yml", "android"): ("google-play", ON_TAG),
    ("credentials.yml", "itch"): ("itch", ON_MAIN),
    ("credentials.yml", "google-play"): ("google-play", ON_MAIN),
}

SECRET = re.compile(r"\$\{\{[^}]*?\bsecrets\.([A-Za-z_][A-Za-z0-9_]*)")
KEY = re.compile(r"^(\s*)(?:- )?([A-Za-z0-9_-]+):(.*)$")


def indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def run_scripts(text: str) -> list[tuple[int, str]]:
    """Every run: value as (line number, script)."""
    lines = text.split("\n")
    out = []
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)(- )?run:(.*)$", lines[i])
        if not m:
            i += 1
            continue
        key_col = len(m.group(1)) + (2 if m.group(2) else 0)
        value = m.group(3).strip()
        start = i + 1
        if value[:1] in ("|", ">"):
            body = []
            i += 1
            while i < len(lines) and (not lines[i].strip() or indent(lines[i]) > key_col):
                body.append(lines[i])
                i += 1
            out.append((start, "\n".join(body)))
        else:
            out.append((start, value))
            i += 1
    return out


def jobs(text: str) -> dict[str, list[str]]:
    """Each job's lines, keyed by its id (two-space indent under jobs:)."""
    lines = text.split("\n")
    found: dict[str, list[str]] = {}
    current = None
    in_jobs = False
    for line in lines:
        if re.match(r"^\S", line):
            in_jobs = line.startswith("jobs:")
            current = None
            continue
        if not in_jobs:
            continue
        m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
        if m:
            current = m.group(1)
            found[current] = []
        elif current is not None:
            found[current].append(line)
    return found


def outside_jobs(text: str) -> str:
    keep = []
    in_jobs = False
    for line in text.split("\n"):
        if re.match(r"^\S", line):
            in_jobs = line.startswith("jobs:")
        if not in_jobs:
            keep.append(line)
    return "\n".join(keep)


def job_key(body: list[str], key: str) -> str:
    """A job-level key's value (four-space indent), block form included."""
    for n, line in enumerate(body):
        m = re.match(r"^    " + re.escape(key) + r":(.*)$", line)
        if m:
            value = m.group(1).strip()
            if value:
                return value
            # environment:\n      name: x
            for sub in body[n + 1:]:
                if indent(sub) <= 4 and sub.strip():
                    break
                nm = re.match(r"^\s+name:\s*(.+)$", sub)
                if nm:
                    return nm.group(1).strip()
            return ""
    return ""


def problems() -> list[str]:
    found = []
    doc = DOC.read_text(encoding="utf-8") if DOC.exists() else ""
    if not doc:
        found.append(f"{DOC.relative_to(ROOT)} is missing")
    seen_jobs = set()
    for path in sorted(WORKFLOWS.glob("*.yml")):
        text = path.read_text(encoding="utf-8")
        name = path.name
        for line_no, script in run_scripts(text):
            if "${{" in script:
                found.append(f"{name}:{line_no}: a run: script contains ${{{{ ... }}}}; "
                             "pass the value through env: and read it as a shell variable")
        top = SECRET.findall(outside_jobs(text))
        if top:
            found.append(f"{name}: secrets outside a job ({', '.join(sorted(set(top)))}); "
                         "they would reach every job")
        for job, body in jobs(text).items():
            used = set(SECRET.findall("\n".join(body))) - {"GITHUB_TOKEN"}
            if not used:
                continue
            want = JOBS.get((name, job))
            if want is None:
                found.append(f"{name} job {job} reads {', '.join(sorted(used))} "
                             "but is not listed in this test's JOBS")
                continue
            seen_jobs.add((name, job))
            env, cond = want
            got_env = job_key(body, "environment")
            if got_env != env:
                found.append(f"{name} job {job}: environment is {got_env or 'missing'}, want {env}")
            if cond not in job_key(body, "if"):
                found.append(f"{name} job {job}: its if: must contain {cond}")
            stray = used - ENVIRONMENTS[env]
            if stray:
                found.append(f"{name} job {job}: {', '.join(sorted(stray))} "
                             f"is not a secret of the {env} environment")
            for s in sorted(used):
                if doc and s not in doc:
                    found.append(f"{s} is not documented in docs/release-secrets.md")
    for name, job in sorted(set(JOBS) - seen_jobs):
        found.append(f"{name} job {job} is listed in JOBS but reads no secret (or is gone)")
    for env in ENVIRONMENTS:
        if doc and f"`{env}`" not in doc:
            found.append(f"the {env} environment is not documented in docs/release-secrets.md")
    return found


class WorkflowSecrets(unittest.TestCase):
    maxDiff = None

    def test_workflows(self):
        self.assertEqual(problems(), [])

    def test_scanner_sees_an_interpolated_script(self):
        sample = ("jobs:\n  x:\n    steps:\n      - run: |\n"
                  "          echo \"${{ inputs.tag }}\"\n      - run: echo ok\n")
        scripts = run_scripts(sample)
        self.assertEqual(len(scripts), 2)
        self.assertIn("${{", scripts[0][1])
        self.assertNotIn("${{", scripts[1][1])

    def test_scanner_reads_job_keys(self):
        sample = ("on: push\njobs:\n  a:\n    if: ${{ github.ref == 'refs/heads/main' }}\n"
                  "    environment:\n      name: store\n    steps:\n"
                  "      - env:\n          K: ${{ secrets.K }}\n        run: echo \"$K\"\n"
                  "  b:\n    runs-on: x\n")
        found = jobs(sample)
        self.assertEqual(sorted(found), ["a", "b"])
        self.assertEqual(job_key(found["a"], "environment"), "store")
        self.assertIn(ON_MAIN, job_key(found["a"], "if"))
        self.assertEqual(SECRET.findall("\n".join(found["a"])), ["K"])


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)

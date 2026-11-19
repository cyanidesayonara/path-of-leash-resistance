"""The Store listing's screenshots and logos, rendered and staged in a draft.

msstore has no command for listing images, but the submission API takes them
the way it takes the package: each image is listed in a listing's
BaseListing.Images with FileStatus PendingUpload, the files travel in the one
zip PUT to the submission's FileUploadUrl, and committing the draft ingests
package and images together. The Store submit workflow's update_draft does it
with these commands (ported from Stemma's scripts/stage_store_images.py):

    python tools/store_images.py render --godot GODOT --project DIR --out OUT
        renders every shot in store/screenshots.txt at 1920x1080 and the
        Store logos (tools/make_store_art.gd) from the project in DIR (the
        tag being submitted), into OUT

    python tools/store_images.py stage --draft RAW --submission JSON \\
            --images OUT --msix PKG --zip ZIP
        RAW is what `msstore submission get` printed before any change, JSON
        the payload tools/store_listing.py wrote, rewritten in place: every
        image already in the Store becomes PendingDelete, images an earlier
        run staged are dropped, and OUT's images are added as PendingUpload.
        ZIP gets the MSIX under the draft's pending package name, plus the
        images at the paths their FileNames give

    python tools/store_images.py upload-url RAW
        prints the draft's FileUploadUrl, for the workflow to mask and PUT to

    python tools/store_images.py verify --staged JSON --after RAW
        after updateMetadata: the draft read back must list the staged
        images as PendingUpload; reports the publish mode

    python tools/store_images.py mode RAW
        reports the draft's TargetPublishMode, warning when it is Manual

    python tools/store_images.py check-submit --status STATUS --draft RAW \\
            --tag vX.Y --listing store/listing.md
        before `submission publish`: refuses unless the draft is
        PendingCommit, its package is this tag's, and its What's new is the
        listing's

    python tools/store_images.py --selftest
        runs tests/test_store_images.py

msstore's Image model has FileName, FileStatus, Id and ImageType only, so
screenshot captions cannot be sent.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import store_listing  # noqa: E402

SHOT_LIST = ROOT / "store" / "screenshots.txt"
SHOT_SIZE = (1920, 1080)
# Partner Center's desktop screenshot bounds and count
MIN_SCREENSHOT = (1366, 768)
MAX_SCREENSHOT = (3840, 2160)
MAX_SCREENSHOTS = 10
# tools/make_store_art.gd's output -> (image type, size), as the live listing
# uses them
ART = {
    "poster-1440x2160.png": ("StoreLogo9x16", (1440, 2160)),
    "boxart-2160.png": ("StoreLogoSquare", (2160, 2160)),
    "tile-300.png": ("Icon", (300, 300)),
}
ZIP_FOLDER = "listing"


def png_size(path: Path) -> tuple[int, int]:
    head = Path(path).read_bytes()[:24]
    if head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        raise SystemExit(f"{path} is not a PNG")
    return struct.unpack(">II", head[16:24])


def shot_list(path: Path = SHOT_LIST) -> list[tuple[str, list[str]]]:
    """(file name, --shot flags) for every screenshot, in listing order."""
    shots = []
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, sep, flags = line.partition(":")
        name = name.strip()
        if not sep or not re.fullmatch(r"[A-Za-z0-9._-]+\.png", name):
            raise SystemExit(f"{path}:{n}: expected 'NAME.png: --flags'")
        if any(s[0] == name for s in shots):
            raise SystemExit(f"{path}:{n}: {name} is listed twice")
        shots.append((name, flags.split()))
    if not 1 <= len(shots) <= MAX_SCREENSHOTS:
        raise SystemExit(f"{path} lists {len(shots)} screenshots; the Store "
                         f"takes 1 to {MAX_SCREENSHOTS}")
    return shots


# --- render ---------------------------------------------------------------

def _godot(godot: str, args: list[str], project: Path, log: Path,
           app: Path, timeout: int = 240) -> None:
    env = dict(os.environ, APPDATA=str(app), XDG_DATA_HOME=str(app))
    with open(log, "w", encoding="utf-8", errors="replace") as fh:
        subprocess.run([godot, *args], cwd=project, env=env, stdout=fh,
                       stderr=subprocess.STDOUT, timeout=timeout, check=False)


def render(godot: str, project: Path, out: Path, jobs: int = 4) -> list[str]:
    out.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="store-images-"))
    problems = []

    def shoot(name: str, flags: list[str]) -> str | None:
        png = out / name
        png.unlink(missing_ok=True)
        app = tmp / f"app-{name}"
        app.mkdir()
        _godot(godot, [
            "--fixed-fps", "60", "--rendering-method", "gl_compatibility",
            "--resolution", f"{SHOT_SIZE[0]}x{SHOT_SIZE[1]}",
            "--path", str(project), "--",
            "--shot", "--shot-quit", f"--shot-out={png.resolve()}", "--seed=1",
            *flags,
        ], project, tmp / f"{name}.log", app)
        if not png.is_file():
            log = (tmp / f"{name}.log").read_text(encoding="utf-8", errors="replace")
            return f"{name}: no image written\n{log[-3000:]}"
        size = png_size(png)
        if size != SHOT_SIZE:
            return f"{name}: rendered {size[0]}x{size[1]}, expected {SHOT_SIZE[0]}x{SHOT_SIZE[1]}"
        print(f"shot {name} {' '.join(flags)}")
        return None

    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for problem in pool.map(lambda s: shoot(*s), shot_list()):
            if problem:
                problems.append(problem)

    art_dir = project / "build" / "store-art"
    for name in ART:
        (art_dir / name).unlink(missing_ok=True)
    app = tmp / "app-art"
    app.mkdir()
    _godot(godot, ["--rendering-method", "gl_compatibility", "--path",
                   str(project), "--script", "res://tools/make_store_art.gd"],
           project, tmp / "art.log", app)
    for name, (_kind, size) in ART.items():
        src = art_dir / name
        if not src.is_file():
            log = (tmp / "art.log").read_text(encoding="utf-8", errors="replace")
            problems.append(f"{name}: tools/make_store_art.gd wrote no image\n{log[-3000:]}")
            continue
        if png_size(src) != size:
            problems.append(f"{name}: {png_size(src)}, expected {size}")
            continue
        shutil.copyfile(src, out / name)
        print(f"art {name}")
    shutil.rmtree(tmp, ignore_errors=True)
    return problems


# --- stage ----------------------------------------------------------------

def listing_images(images: Path, shots: Path = SHOT_LIST) -> list[tuple[str, Path, str]]:
    """(FileName in the zip, local file, image type) for every listing image:
    the screenshots in store/screenshots.txt order, then the logos."""
    out = []
    for name, _flags in shot_list(shots):
        path = images / name
        if not path.is_file():
            raise SystemExit(f"missing screenshot {path}; run render first")
        w, h = png_size(path)
        if not (MIN_SCREENSHOT[0] <= w <= MAX_SCREENSHOT[0]
                and MIN_SCREENSHOT[1] <= h <= MAX_SCREENSHOT[1]):
            raise SystemExit(f"{name} is {w}x{h}; the Store takes "
                             f"{MIN_SCREENSHOT[0]}x{MIN_SCREENSHOT[1]} to "
                             f"{MAX_SCREENSHOT[0]}x{MAX_SCREENSHOT[1]}")
        out.append((f"{ZIP_FOLDER}/{name}", path, "Screenshot"))
    for name, (kind, size) in ART.items():
        path = images / name
        if not path.is_file():
            raise SystemExit(f"missing Store logo {path}; run render first")
        if png_size(path) != size:
            raise SystemExit(f"{name} is {png_size(path)}, expected {size}")
        out.append((f"{ZIP_FOLDER}/{name}", path, kind))
    return out


def replace_images(current: list[dict], new: list[tuple[str, Path, str]],
                   in_store: bool) -> list[dict]:
    """A listing's images with the Store's own retired and the new ones
    pending upload. An entry without an Id was staged by an earlier run and
    never ingested: dropped, so a rerun replaces rather than adds. A listing
    that is not in the Store yet (cloned from en-US by tools/store_listing.py)
    holds copies of another listing's images: dropped too."""
    kept = []
    if in_store:
        kept = [{**image, "FileStatus": "PendingDelete"}
                for image in current if image.get("Id")]
    staged = [{"FileName": name, "FileStatus": "PendingUpload", "ImageType": kind}
              for name, _path, kind in new]
    return kept + staged


def pending_package(submission: dict) -> str:
    """The file name the draft expects for its package upload."""
    for package in submission.get("ApplicationPackages") or []:
        if package.get("FileStatus") == "PendingUpload":
            return package["FileName"]
    raise SystemExit("the draft has no package pending upload; run "
                     "msstore publish --noCommit first")


def stage(submission: dict, draft: dict,
          images: list[tuple[str, Path, str]]) -> dict:
    """Return *submission* with every listing's images replaced. *draft* is
    the submission as the Store had it, to tell its listings from new ones."""
    listings = submission.get("Listings") or {}
    if not listings:
        raise SystemExit("the submission has no listings")
    in_store = set((draft.get("Listings") or {}).keys())
    for key, listing in listings.items():
        base = listing.setdefault("BaseListing", {})
        base["Images"] = replace_images(base.get("Images") or [], images,
                                        key in in_store)
    return submission


def write_zip(path: Path, msix: Path, package_name: str,
              images: list[tuple[str, Path, str]]) -> None:
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        # the MSIX is already compressed, and so are PNGs
        archive.write(msix, package_name, compress_type=zipfile.ZIP_STORED)
        for name, local, _kind in images:
            archive.write(local, name, compress_type=zipfile.ZIP_STORED)


def upload_url_masks(url: str) -> list[str]:
    """Every form of the upload URL a log can show: as is, as msstore's JSON
    prints it (& as \\u0026), and its signature alone, which is the secret."""
    forms = [url, url.replace("&", "\\u0026")]
    m = re.search(r"[?&]sig=([^&]+)", url)
    if m:
        forms.append(m[1])
    return forms


def _read_json(path: Path) -> dict:
    return store_listing.submission(Path(path).read_text(encoding="utf-8"))


def cmd_stage(args) -> int:
    import json
    draft = _read_json(args.draft)
    sub = json.loads(Path(args.submission).read_text(encoding="utf-8"))
    images = listing_images(Path(args.images))
    package = pending_package(sub)
    if package != Path(args.msix).name:
        raise SystemExit(f"the draft's pending package is {package}, not "
                         f"{Path(args.msix).name}: the draft is for another version")
    stage(sub, draft, images)
    Path(args.submission).write_text(json.dumps(sub, indent=2, ensure_ascii=False) + "\n",
                                     encoding="utf-8", newline="\n")
    write_zip(Path(args.zip), Path(args.msix), package, images)
    retired = sum(i["FileStatus"] == "PendingDelete"
                  for lst in sub["Listings"].values()
                  for i in lst["BaseListing"]["Images"])
    print(f"Staged {len(images)} images in {', '.join(sub['Listings'])} "
          f"({retired} current images marked PendingDelete); {args.zip} holds "
          f"{package} and the images")
    return 0


# --- verify and submit checks ---------------------------------------------

def publish_mode_note(sub: dict) -> str:
    mode = sub.get("TargetPublishMode") or "unknown"
    if mode == "Manual":
        return ("TargetPublishMode is Manual: after certification the release "
                "waits until someone selects Publish now in Partner Center.")
    if mode == "SpecificDate":
        return (f"TargetPublishMode is SpecificDate: it publishes on "
                f"{sub.get('TargetPublishDate')} after certification.")
    return f"TargetPublishMode is {mode}."


def verify(staged: dict, after: dict) -> list[str]:
    problems = []
    for key, listing in (staged.get("Listings") or {}).items():
        want = [(i["FileName"], i["ImageType"]) for i in listing["BaseListing"]["Images"]
                if i["FileStatus"] == "PendingUpload"]
        got_listing = (after.get("Listings") or {}).get(key)
        if not got_listing:
            problems.append(f"{key}: not in the draft read back")
            continue
        got = [(i.get("FileName"), i.get("ImageType"))
               for i in got_listing.get("BaseListing", {}).get("Images") or []
               if i.get("FileStatus") == "PendingUpload"]
        if got != want:
            problems.append(f"{key}: {len(got)} images pending upload, expected "
                            f"{len(want)}: {got}")
    return problems


def _summary(lines: list[str]) -> None:
    for line in lines:
        print(line)
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n\n")


def cmd_verify(args) -> int:
    import json
    staged = json.loads(Path(args.staged).read_text(encoding="utf-8"))
    after = _read_json(args.after)
    problems = verify(staged, after)
    lines = []
    for key, listing in (after.get("Listings") or {}).items():
        images = listing.get("BaseListing", {}).get("Images") or []
        up = sum(i.get("FileStatus") == "PendingUpload" for i in images)
        gone = sum(i.get("FileStatus") == "PendingDelete" for i in images)
        lines.append(f"- {key}: {up} images pending upload, {gone} pending delete")
    note = publish_mode_note(after)
    if after.get("TargetPublishMode") == "Manual":
        print(f"::warning::{note}")
    _summary(["Draft read back:", *lines, "", note])
    for p in problems:
        print(f"::error::{p}")
    return 1 if problems else 0


def package_version(tag: str) -> str:
    m = re.fullmatch(r"v(\d+)\.(\d+)(?:\.(\d+))?", tag)
    if not m:
        raise SystemExit(f"not a release tag: {tag}")
    return f"{m[1]}.{m[2]}.{m[3] or 0}.0"


def check_submit(status: str, draft: dict, tag: str, whats_new: str) -> list[str]:
    problems = []
    if not re.search(r"Submission Status\s*=\s*PendingCommit\b", status):
        problems.append("No draft waiting to be committed (status is not "
                        "PendingCommit). Run update_draft first, or get_draft "
                        "to see the status.")
    want = f"PathOfLeashResistance-{package_version(tag)}.msix"
    pending = [p.get("FileName") for p in draft.get("ApplicationPackages") or []
               if p.get("FileStatus") == "PendingUpload"]
    if pending != [want]:
        problems.append(f"The draft's pending package is {pending or 'none'}, "
                        f"not {want}. Run update_draft with {tag} first.")
    listings = draft.get("Listings") or {}
    en = next((v for k, v in listings.items()
               if store_listing.lang_for_listing_key(k) == "en-US"), None)
    notes = ((en or {}).get("BaseListing") or {}).get("ReleaseNotes")
    if (notes or "").strip() != whats_new.strip():
        problems.append("The draft's What's new is not store/listing.md's "
                        "What's new in this version. Run update_draft with "
                        f"{tag} first.")
    return problems


def cmd_check_submit(args) -> int:
    status = Path(args.status).read_text(encoding="utf-8", errors="replace")
    draft = _read_json(args.draft)
    md = Path(args.listing).read_text(encoding="utf-8")
    whats_new = store_listing.fields(md, "en")["ReleaseNotes"]
    problems = check_submit(status, draft, args.tag, whats_new)
    for p in problems:
        print(f"::error::{p}")
    note = publish_mode_note(draft)
    if draft.get("TargetPublishMode") == "Manual":
        print(f"::warning::{note}")
    _summary([note])
    return 1 if problems else 0


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if argv == ["--selftest"]:
        return subprocess.call([sys.executable, str(ROOT / "tests" / "test_store_images.py")])
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("render")
    r.add_argument("--godot", required=True)
    r.add_argument("--project", type=Path, required=True)
    r.add_argument("--out", type=Path, required=True)
    r.add_argument("--jobs", type=int, default=4)
    s = sub.add_parser("stage")
    s.add_argument("--draft", type=Path, required=True)
    s.add_argument("--submission", type=Path, required=True)
    s.add_argument("--images", type=Path, required=True)
    s.add_argument("--msix", type=Path, required=True)
    s.add_argument("--zip", type=Path, required=True)
    u = sub.add_parser("upload-url")
    u.add_argument("draft", type=Path)
    u.add_argument("--masks", action="store_true",
                   help="print ::add-mask:: lines for every form of the URL instead")
    v = sub.add_parser("verify")
    v.add_argument("--staged", type=Path, required=True)
    v.add_argument("--after", type=Path, required=True)
    m = sub.add_parser("mode")
    m.add_argument("draft", type=Path)
    c = sub.add_parser("check-submit")
    c.add_argument("--status", type=Path, required=True)
    c.add_argument("--draft", type=Path, required=True)
    c.add_argument("--tag", required=True)
    c.add_argument("--listing", type=Path, required=True)
    args = p.parse_args(argv)
    if args.cmd == "render":
        problems = render(args.godot, args.project.resolve(), args.out.resolve(), args.jobs)
        for problem in problems:
            print(f"FAILED {problem}")
        return 1 if problems else 0
    if args.cmd == "stage":
        return cmd_stage(args)
    if args.cmd == "upload-url":
        url = _read_json(args.draft).get("FileUploadUrl")
        if not url and args.masks:
            # a committed submission has none: nothing to hide
            return 0
        if not url:
            raise SystemExit("the draft has no FileUploadUrl")
        if args.masks:
            for secret in upload_url_masks(url):
                print(f"::add-mask::{secret}")
        else:
            print(url)
        return 0
    if args.cmd == "verify":
        return cmd_verify(args)
    if args.cmd == "mode":
        draft = _read_json(args.draft)
        if draft.get("TargetPublishMode") == "Manual":
            print(f"::warning::{publish_mode_note(draft)}")
        _summary([publish_mode_note(draft)])
        return 0
    return cmd_check_submit(args)


if __name__ == "__main__":
    raise SystemExit(main())

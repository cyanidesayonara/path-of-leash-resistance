"""tools/store_images.py: staging the Store listing's screenshots and logos.

    python tests/test_store_images.py
"""

import copy
import json
import struct
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import store_images  # noqa: E402
import store_listing  # noqa: E402

URL = ("https://ingestionpackagesprod1.blob.core.windows.net/ingestion/abc"
       "?skoid=1&sv=2024-05-04&sr=b&sp=rwl&sig=SECRET%3D")


def png(path: Path, w: int, h: int) -> None:
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR"
                     + struct.pack(">II", w, h) + b"\x08\x02\x00\x00\x00")


def draft() -> dict:
    """Shaped like the v1.75 draft msstore printed (trimmed)."""
    return {
        "TargetPublishMode": "Immediate",
        "FileUploadUrl": URL,
        "ApplicationPackages": [
            {"FileName": "PathOfLeashResistance-1.74.0.0.msix",
             "FileStatus": "PendingDelete", "Id": "2000000000100769876"},
            {"FileName": "PathOfLeashResistance-1.75.0.0.msix",
             "FileStatus": "PendingUpload", "Id": None},
        ],
        "Listings": {"en-us": {"BaseListing": {
            "Description": "unchanged",
            "ReleaseNotes": "- notes",
            "Images": [
                {"FileName": "03-freedom.png", "FileStatus": "Uploaded",
                 "Id": "1152922700028295294", "ImageType": "Screenshot"},
                {"FileName": "tile-300.png", "FileStatus": "Uploaded",
                 "Id": "1152922700028295328", "ImageType": "Icon"},
                {"FileName": "boxart-2160.png", "FileStatus": "Uploaded",
                 "Id": "1152922700028295346", "ImageType": "StoreLogoSquare"},
                {"FileName": "poster-1440x2160.png", "FileStatus": "Uploaded",
                 "Id": "1152922700028295327", "ImageType": "StoreLogo9x16"},
            ],
        }, "PlatformOverrides": {}}},
    }


class StoreImages(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.images = self.tmp / "images"
        self.images.mkdir()
        for name, _flags in store_images.shot_list():
            png(self.images / name, 1920, 1080)
        for name, (_kind, (w, h)) in store_images.ART.items():
            png(self.images / name, w, h)

    def test_shot_list_is_ordered_unique_and_within_the_stores_count(self):
        shots = store_images.shot_list()
        names = [n for n, _ in shots]
        self.assertEqual(names, sorted(names))
        self.assertTrue(1 <= len(shots) <= 10)
        for _name, flags in shots:
            self.assertTrue(any(f.startswith("--level=") for f in flags))

    def test_images_are_the_screenshots_in_order_then_the_logos(self):
        images = store_images.listing_images(self.images)
        shots = [n for n, _p, k in images if k == "Screenshot"]
        self.assertEqual(shots, [f"listing/{n}" for n, _ in store_images.shot_list()])
        kinds = {n.split("/")[-1]: k for n, _p, k in images if k != "Screenshot"}
        self.assertEqual(kinds, {"poster-1440x2160.png": "StoreLogo9x16",
                                 "boxart-2160.png": "StoreLogoSquare",
                                 "tile-300.png": "Icon"})

    def test_stage_retires_the_stores_images_and_adds_the_new_ones(self):
        images = store_images.listing_images(self.images)
        sub = store_images.stage(draft(), draft(), images)
        got = sub["Listings"]["en-us"]["BaseListing"]
        self.assertEqual([i["FileStatus"] for i in got["Images"][:4]], ["PendingDelete"] * 4)
        staged = [i for i in got["Images"] if i["FileStatus"] == "PendingUpload"]
        self.assertEqual(len(staged), len(images))
        self.assertTrue(all("Id" not in i for i in staged))
        self.assertEqual(got["Description"], "unchanged")

    def test_a_rerun_replaces_its_own_staged_images_instead_of_adding_more(self):
        images = store_images.listing_images(self.images)
        once = store_images.stage(draft(), draft(), images)
        twice = store_images.stage(copy.deepcopy(once), copy.deepcopy(once), images)
        listing = twice["Listings"]["en-us"]["BaseListing"]["Images"]
        self.assertEqual(len(listing), 4 + len(images))
        self.assertEqual(sum(i["FileStatus"] == "PendingDelete" for i in listing), 4)

    def test_a_cloned_listing_drops_the_images_it_copied(self):
        images = store_images.listing_images(self.images)
        sub = draft()
        sub["Listings"]["ca-ES"] = copy.deepcopy(sub["Listings"]["en-us"])
        store_images.stage(sub, draft(), images)
        ca = sub["Listings"]["ca-ES"]["BaseListing"]["Images"]
        self.assertEqual([i["FileStatus"] for i in ca], ["PendingUpload"] * len(images))

    def test_stage_writes_the_zip_with_the_package_under_the_drafts_name(self):
        raw = self.tmp / "raw.txt"
        raw.write_text("info: fetching\n" + json.dumps(draft()) + "\ndone\n", encoding="utf-8")
        sub = self.tmp / "metadata.json"
        sub.write_text(json.dumps(draft()), encoding="utf-8")
        msix = self.tmp / "PathOfLeashResistance-1.75.0.0.msix"
        msix.write_bytes(b"MSIX")
        upload = self.tmp / "upload.zip"
        self.assertEqual(store_images.main([
            "stage", "--draft", str(raw), "--submission", str(sub),
            "--images", str(self.images), "--msix", str(msix), "--zip", str(upload)]), 0)
        with zipfile.ZipFile(upload) as z:
            names = z.namelist()
            self.assertEqual(z.read("PathOfLeashResistance-1.75.0.0.msix"), b"MSIX")
        staged = json.loads(sub.read_text(encoding="utf-8"))
        for image in staged["Listings"]["en-us"]["BaseListing"]["Images"]:
            if image["FileStatus"] == "PendingUpload":
                self.assertIn(image["FileName"], names)

    def test_stage_refuses_a_draft_for_another_version(self):
        raw = self.tmp / "raw.json"
        raw.write_text(json.dumps(draft()), encoding="utf-8")
        msix = self.tmp / "PathOfLeashResistance-1.76.0.0.msix"
        msix.write_bytes(b"MSIX")
        with self.assertRaisesRegex(SystemExit, "another version"):
            store_images.main(["stage", "--draft", str(raw), "--submission", str(raw),
                               "--images", str(self.images), "--msix", str(msix),
                               "--zip", str(self.tmp / "u.zip")])

    def test_a_draft_without_a_pending_package_is_refused(self):
        d = draft()
        d["ApplicationPackages"] = d["ApplicationPackages"][:1]
        with self.assertRaisesRegex(SystemExit, "no package pending upload"):
            store_images.pending_package(d)

    def test_a_screenshot_outside_the_stores_bounds_is_refused(self):
        name = store_images.shot_list()[0][0]
        png(self.images / name, 1280, 720)
        with self.assertRaisesRegex(SystemExit, "1280x720"):
            store_images.listing_images(self.images)

    def test_verify_wants_the_staged_images_back_as_pending_upload(self):
        images = store_images.listing_images(self.images)
        staged = store_images.stage(draft(), draft(), images)
        self.assertEqual(store_images.verify(staged, copy.deepcopy(staged)), [])
        self.assertTrue(store_images.verify(staged, draft()))

    def test_publish_mode_manual_is_called_out(self):
        d = draft()
        d["TargetPublishMode"] = "Manual"
        self.assertIn("Publish now", store_images.publish_mode_note(d))
        self.assertEqual(store_images.publish_mode_note(draft()),
                         "TargetPublishMode is Immediate.")

    def test_check_submit_needs_pending_commit_this_tags_package_and_the_notes(self):
        ok = "Submission Status = PendingCommit\n"
        self.assertEqual(store_images.check_submit(ok, draft(), "v1.75", "- notes"), [])
        self.assertEqual(len(store_images.check_submit(
            "Submission Status = CommitStarted", draft(), "v1.75", "- notes")), 1)
        self.assertEqual(len(store_images.check_submit(ok, draft(), "v1.76", "- notes")), 1)
        self.assertEqual(len(store_images.check_submit(ok, draft(), "v1.75", "- other")), 1)

    def test_package_version_follows_pack_msix(self):
        self.assertEqual(store_images.package_version("v1.75"), "1.75.0.0")
        self.assertEqual(store_images.package_version("v1.75.2"), "1.75.2.0")

    def test_upload_url_masks_cover_msstores_json_escaping_and_the_signature(self):
        masks = store_images.upload_url_masks(URL)
        self.assertIn(URL, masks)
        self.assertIn(URL.replace("&", "\\u0026"), masks)
        self.assertIn("SECRET%3D", masks)

    def test_the_listings_whats_new_is_readable(self):
        md = (ROOT / "store" / "listing.md").read_text(encoding="utf-8")
        self.assertTrue(store_listing.fields(md, "en")["ReleaseNotes"])


if __name__ == "__main__":
    unittest.main()

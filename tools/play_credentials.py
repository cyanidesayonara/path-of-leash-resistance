"""Check the Google Play service account without changing anything.

    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='{...}' python3 tools/play_credentials.py PACKAGE

Signs a token request with the account's key (openssl, no extra packages),
opens an edit of PACKAGE in the Play Developer API and deletes it unsaved:
an edit is a draft that nothing sees until it is committed. Prints only
statuses and Google's error messages, never the key or the token.
Used by .github/workflows/credentials.yml.
"""

import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

SCOPE = "https://www.googleapis.com/auth/androidpublisher"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"


def b64(data: bytes) -> bytes:
    return base64.urlsafe_b64encode(data).rstrip(b"=")


def sign(key_pem: str, message: bytes) -> bytes:
    fd, path = tempfile.mkstemp(suffix=".pem")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(key_pem)
        return subprocess.run(["openssl", "dgst", "-sha256", "-sign", path],
                              input=message, capture_output=True, check=True).stdout
    finally:
        os.remove(path)


def token(account: dict) -> str:
    now = int(time.time())
    head = b64(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    claims = b64(json.dumps({"iss": account["client_email"], "scope": SCOPE,
                             "aud": account["token_uri"], "iat": now,
                             "exp": now + 600}).encode())
    unsigned = head + b"." + claims
    assertion = unsigned + b"." + b64(sign(account["private_key"], unsigned))
    body = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": assertion.decode(),
    }).encode()
    with urllib.request.urlopen(account["token_uri"], body, timeout=30) as r:
        return json.load(r)["access_token"]


def call(method: str, url: str, tok: str) -> dict:
    req = urllib.request.Request(url, method=method, data=b"" if method == "POST" else None,
                                 headers={"Authorization": "Bearer " + tok})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    return json.loads(raw) if raw else {}


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    package = sys.argv[1]
    raw = os.environ.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", "")
    try:
        account = json.loads(raw)
        email = account["client_email"]
    except (ValueError, KeyError, TypeError):
        print("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not a service account key (JSON with client_email).")
        return 1
    print(f"Service account: {email}")
    try:
        tok = token(account)
        print("Token: granted for the androidpublisher scope.")
        edit = call("POST", f"{API}/{package}/edits", tok)
        call("DELETE", f"{API}/{package}/edits/{edit['id']}", tok)
        print(f"Play: opened an edit of {package} and deleted it unsaved.")
    except urllib.error.HTTPError as e:
        try:
            message = json.loads(e.read()).get("error", {})
            message = message.get("message") if isinstance(message, dict) else message
        except ValueError:
            message = ""
        print(f"Play API refused: HTTP {e.code} {message}")
        return 1
    except subprocess.CalledProcessError:
        print("openssl could not sign with the account's private_key.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

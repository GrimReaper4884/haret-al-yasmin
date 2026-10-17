"""Uploads an image, audio or video file to Roblox through Open Cloud (BUILD_PLAN P3-02, POLISH_PLAN PV-C01).

    python tools/upload_asset.py <file> --name "Haret icon lira" [--type Image] [--dry-run]
    python tools/upload_asset.py <file> --name "..." --register   add it to the manifest (id 0) without uploading
    python tools/upload_asset.py --pending [--dry-run]      every manifest entry whose id is still 0

Standard library only (`uv run` also works where its cache sits on the same drive as %TEMP%). Reads ROBLOX_OPEN_CLOUD_KEY (sent as x-api-key, never printed) and ROBLOX_CREATOR_ID
from the environment, POSTs multipart/form-data to https://apis.roblox.com/assets/v1/assets, polls the returned
operation and prints `rbxassetid://<id>`. Images go up as assetType "Image" so the id works directly in an
ImageLabel (a Decal id would not). Every upload is recorded in tools/upload_manifest.json (file -> name, type,
id, date); the manifest is how ids reach src/shared/Config (Icons, Vfx). The owner approves the first real
upload (POLISH_PLAN PV-C01); the default use is --dry-run.
"""

import argparse
import datetime
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools" / "upload_manifest.json"
API = "https://apis.roblox.com/assets/v1"
TYPES = {
    "Image": {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".bmp": "image/bmp", ".tga": "image/tga"},
    "Decal": {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".bmp": "image/bmp", ".tga": "image/tga"},
    "Audio": {".mp3": "audio/mpeg", ".ogg": "audio/ogg", ".wav": "audio/wav", ".flac": "audio/flac"},
    "Video": {".mp4": "video/mp4", ".mov": "video/mov"},
}
MAX_BYTES = 20 * 1024 * 1024  # images and audio stay far below this; videos are uploaded by the owner


def load_manifest() -> dict:
    if MANIFEST.exists():
        return json.loads(MANIFEST.read_text(encoding="utf-8"))
    return {"_comment": "Open Cloud uploads (tools/upload_asset.py). id 0 = not uploaded yet.", "files": {}}


def save_manifest(m: dict):
    MANIFEST.write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def content_type(path: Path, asset_type: str) -> str:
    ct = TYPES[asset_type].get(path.suffix.lower())
    if not ct:
        sys.exit(f"{path.name}: {path.suffix} is not accepted for {asset_type} ({', '.join(TYPES[asset_type])})")
    return ct


def multipart(fields: dict, file_field: str, path: Path, ctype: str) -> tuple[bytes, str]:
    boundary = "----haret" + uuid.uuid4().hex
    out = bytearray()
    for name, value in fields.items():
        out += f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n".encode()
        out += value.encode("utf-8") + b"\r\n"
    out += (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"{file_field}\"; filename=\"{path.name}\"\r\n"
        f"Content-Type: {ctype}\r\n\r\n"
    ).encode()
    out += path.read_bytes() + b"\r\n"
    out += f"--{boundary}--\r\n".encode()
    return bytes(out), f"multipart/form-data; boundary={boundary}"


def http(method: str, url: str, key: str, body: bytes | None = None, ctype: str | None = None) -> dict:
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("x-api-key", key)
    if ctype:
        req.add_header("Content-Type", ctype)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as e:
        # The error body never contains the key; print it for diagnosis.
        sys.exit(f"HTTP {e.code} on {method} {url}: {e.read().decode('utf-8', 'replace')[:500]}")


def upload(path: Path, name: str, asset_type: str, description: str, dry_run: bool) -> int:
    if not path.exists():
        sys.exit(f"no such file: {path}")
    if asset_type not in TYPES:
        sys.exit(f"--type must be one of {', '.join(TYPES)}")
    size = path.stat().st_size
    if size > MAX_BYTES:
        sys.exit(f"{path.name} is {size} bytes (> {MAX_BYTES}); upload it through Creator Hub")
    ctype = content_type(path, asset_type)
    creator = os.environ.get("ROBLOX_CREATOR_ID", "")
    key = os.environ.get("ROBLOX_OPEN_CLOUD_KEY", "")
    request = {
        "assetType": asset_type,
        "displayName": name[:50],
        "description": description[:1000],
        "creationContext": {"creator": {"userId": creator or "<ROBLOX_CREATOR_ID>"}},
    }
    print(f"POST {API}/assets  {rel(path)}  {size} bytes  {ctype}")
    print("  request = " + json.dumps(request, ensure_ascii=False))
    print(f"  x-api-key = {'<set>' if key else '<MISSING>'}  (never printed)")
    if dry_run:
        print("  dry run: nothing sent")
        return 0
    if not key or not creator:
        sys.exit("ROBLOX_OPEN_CLOUD_KEY and ROBLOX_CREATOR_ID must both be set (user environment)")

    body, mp = multipart({"request": json.dumps(request)}, "fileContent", path, ctype)
    op = http("POST", f"{API}/assets", key, body, mp)
    op_path = op.get("path") or ""
    for _ in range(60):
        if op.get("done"):
            break
        time.sleep(2)
        op = http("GET", f"{API}/{op_path}", key)
    if not op.get("done"):
        sys.exit(f"operation {op_path} still running after 2 minutes; poll it later")
    if "error" in op:
        sys.exit(f"upload failed: {json.dumps(op['error'])[:500]}")
    res = op.get("response") or {}
    asset_id = int(res.get("assetId", 0))
    state = (res.get("moderationResult") or {}).get("moderationState", "?")
    print(f"rbxassetid://{asset_id}  ({state})")
    return asset_id


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", nargs="?")
    ap.add_argument("--name", help="display name on Roblox (default: Haret <file stem>)")
    ap.add_argument("--type", default="Image", choices=sorted(TYPES))
    ap.add_argument("--description", default="Haret Al-Yasmin game asset")
    ap.add_argument("--pending", action="store_true", help="upload every manifest entry whose id is 0")
    ap.add_argument("--register", action="store_true", help="add the file to the manifest with id 0; no upload")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    m = load_manifest()
    files = m.setdefault("files", {})
    if a.pending:
        todo = [(k, v) for k, v in files.items() if not v.get("id")]
        if not todo:
            print("nothing pending")
        for k, v in todo:
            asset_id = upload(ROOT / k, v["name"], v.get("type", "Image"), v.get("description", a.description), a.dry_run)
            if asset_id:
                v["id"], v["uploaded"] = asset_id, datetime.date.today().isoformat()
                save_manifest(m)
        return
    if not a.file:
        ap.error("give a file or --pending")
    path = Path(a.file)
    name = a.name or ("Haret " + path.stem.replace("_", " "))
    key = rel(path)
    entry = files.get(key)
    if entry and entry.get("id") and not a.dry_run:
        sys.exit(f"{key} is already rbxassetid://{entry['id']} (manifest); delete the id to upload again")
    if a.register:
        if not path.exists():
            sys.exit(f"no such file: {path}")
        content_type(path, a.type)
        files[key] = {"name": name, "type": a.type, "id": (entry or {}).get("id", 0)}
        save_manifest(m)
        print(f"registered {key} as '{name}' ({a.type})")
        return
    asset_id = upload(path, name, a.type, a.description, a.dry_run)
    if asset_id:
        files[key] = {"name": name, "type": a.type, "id": asset_id, "uploaded": datetime.date.today().isoformat()}
        save_manifest(m)


if __name__ == "__main__":
    main()

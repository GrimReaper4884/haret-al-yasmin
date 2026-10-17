"""Downloads every clip named in tools/anim/clips.json for each character's own Meshy rig.

    python tools/anim/fetch.py [character ...]

Characters run in parallel (one manifest each), clips of one character one after another.
Already-downloaded clips are skipped, so rerunning only fetches what is missing.
"""

import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CFG = json.loads((ROOT / "tools" / "anim" / "clips.json").read_text(encoding="utf-8"))


def fetch(cid: str) -> str:
    names = sorted({(v["clip"] if isinstance(v, dict) else v) for v in CFG["characters"][cid].values()})
    for name in names:
        r = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "meshy" / "meshy.py"), "clip", cid, name, str(CFG["actions"][name])],
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            return f"{cid}: {name} failed: {(r.stdout + r.stderr).strip()[-300:]}"
    return f"{cid}: {', '.join(names)}"


ids = sys.argv[1:] or list(CFG["characters"])
with ThreadPoolExecutor(max_workers=8) as pool:
    for line in pool.map(fetch, ids):
        print(line, flush=True)

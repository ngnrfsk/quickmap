import os
import shutil

SRC = "/Users/iarla/Coding/quickmap/dev/archviz_v1"
DST = "/Users/iarla/Library/Mobile Documents/com~apple~CloudDocs/dev/quickmap_archviz_v1"

if os.path.exists(DST):
    shutil.rmtree(DST)
shutil.copytree(SRC, DST)
seen = {}
for root, _, files in os.walk(DST):
    for f in files:
        key = os.path.join(root, f).lower()
        if key in seen:
            raise SystemExit(f"names differ only by case: {f}")
        seen[key] = 1
print(len(seen), "files copied to", DST)

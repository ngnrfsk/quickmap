#!/usr/bin/env python3
"""Inspect the mapgl tarball and extract maplibre-gl dist assets for the prototype."""
import tarfile, pathlib

TGZ = pathlib.Path("/Users/iarla/Coding/quickmap/dev/mapgl_0.4.4.tgz")
DEST = pathlib.Path("/Users/iarla/Coding/quickmap/dev/item5_prototypes/maplibre/assets")
DEST.mkdir(exist_ok=True)

with tarfile.open(TGZ) as tf:
    names = tf.getnames()
    for n in names:
        if "maplibre" in n.lower() or n.endswith((".js", ".css", "DESCRIPTION")):
            print(n)
    for n in names:
        base = n.split("/")[-1]
        if base in ("maplibre-gl.js", "maplibre-gl.css", "DESCRIPTION"):
            m = tf.getmember(n)
            f = tf.extractfile(m)
            (DEST / base).write_bytes(f.read())
            print("extracted", base, m.size, "bytes")

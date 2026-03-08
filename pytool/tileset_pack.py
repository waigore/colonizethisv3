#!/usr/bin/env python3
"""
Layer 4: Pack Layer 1–3 outputs into spritesheets and a single manifest.
No API calls; does not require PIXELLAB_API_KEY. See SPEC/ui/wang-tileset-and-assets.md.
"""
import argparse
import json
from pathlib import Path

from PIL import Image

TILE_SIZE_PX = 64


def load_manifest(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text())


def pack_layer(
    layer_dir: Path,
    manifest_key: str,
    tile_size: int,
    out_image_path: Path,
    *,
    default_size: int | None = None,
) -> dict:
    """
    Pack tiles from layer_dir (using manifest at layer_dir/manifest.json) into a single image.
    manifest.json maps tile_id -> path string or {path, w?, h?}.
    Returns tiles dict: tile_id -> {x, y, w, h}.
    """
    manifest_path = layer_dir / "manifest.json"
    manifest = load_manifest(manifest_path)
    if not manifest:
        return {}
    tiles_dir = layer_dir / "tiles" if (layer_dir / "tiles").is_dir() else layer_dir
    positions = {}
    row, col = 0, 0
    max_w, max_h = 0, 0
    images_to_paste = []
    for tile_id, entry in manifest.items():
        if isinstance(entry, str):
            rel = entry
            w = h = default_size or tile_size
        else:
            rel = entry.get("path", entry.get("filename", str(entry)))
            w = entry.get("w", default_size or tile_size)
            h = entry.get("h", default_size or tile_size)
        path = layer_dir / rel
        if not path.is_file():
            path = tiles_dir / Path(rel).name
        if not path.is_file():
            continue
        img = Image.open(path).convert("RGBA")
        tw, th = img.size
        positions[tile_id] = {"x": col * tile_size, "y": row * tile_size, "w": tw, "h": th}
        images_to_paste.append((col * tile_size, row * tile_size, img))
        max_w = max(max_w, col * tile_size + tw)
        max_h = max(max_h, row * tile_size + th)
        col += 1
        if col * tile_size >= 1024:
            col = 0
            row += 1
    if not images_to_paste:
        return {}
    out_w = max_w if max_w > 0 else tile_size
    out_h = max_h if max_h > 0 else tile_size
    out = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    for x, y, img in images_to_paste:
        out.paste(img, (x, y))
    out.save(out_image_path)
    return positions


def main() -> None:
    parser = argparse.ArgumentParser(description="Layer 4: Pack terrain, resources, improvements into spritesheets")
    parser.add_argument("--out", type=Path, default=Path("out/4_spritesheet"), help="Output dir for spritesheets")
    parser.add_argument("--terrain", type=Path, default=Path("out/1_terrain"), help="Layer 1 dir")
    parser.add_argument("--resources", type=Path, default=Path("out/2_resources"), help="Layer 2 dir")
    parser.add_argument("--improvements", type=Path, default=Path("out/3_improvements"), help="Layer 3 dir")
    args = parser.parse_args()

    out_dir = args.out
    out_dir.mkdir(parents=True, exist_ok=True)

    terrain_tiles = pack_layer(
        args.terrain,
        "terrain",
        TILE_SIZE_PX,
        out_dir / "terrain.png",
        default_size=TILE_SIZE_PX,
    )
    resources_tiles = pack_layer(
        args.resources,
        "resources",
        TILE_SIZE_PX,
        out_dir / "resources.png",
        default_size=48,
    )
    improvements_tiles = pack_layer(
        args.improvements,
        "improvements",
        TILE_SIZE_PX,
        out_dir / "improvements.png",
        default_size=64,
    )

    manifest = {
        "tile_size_px": TILE_SIZE_PX,
        "layers": {
            "terrain": {"image": "terrain.png", "tiles": terrain_tiles},
            "resources": {"image": "resources.png", "tiles": resources_tiles},
            "improvements": {"image": "improvements.png", "tiles": improvements_tiles},
        },
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"Wrote spritesheets and manifest to {out_dir}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build a proper 48×48 nine-patch PNG with solid stretchable edges.

This creates a nine-patch where:
- Corners (4 tiles): Keep detailed artwork from source (don't stretch)
- Horizontal edges (2 tiles): Solid color that stretches horizontally
- Vertical edges (2 tiles): Solid color that stretches vertically  
- Center (1 tile): Solid color that stretches in both directions

This avoids deformation when buttons are scaled to different sizes.

Usage:
  python pytool/button_nine_patch_proper.py <input.png> <output.png> [tile_size]

Example:
  python pytool/button_nine_patch_proper.py app/assets/images/ui_main_menu_button.png app/assets/images/ui_button_nine_patch.png 16

See SPEC/ui/buttons-nine-patch.md.
"""
import sys
from pathlib import Path
from PIL import Image

DEFAULT_TILE_SIZE = 16


def get_dominant_color(region: Image.Image) -> tuple:
    """Get the most common non-transparent color in a region."""
    pixels = list(region.getdata())
    color_counts = {}
    for p in pixels:
        if p[3] > 0:  # non-transparent
            # Round to reduce color variations
            rounded = (p[0] // 4 * 4, p[1] // 4 * 4, p[2] // 4 * 4, p[3])
            color_counts[rounded] = color_counts.get(rounded, 0) + 1
    if color_counts:
        return max(color_counts, key=color_counts.get)
    return (0, 0, 0, 0)


def create_solid_tile(color: tuple, size: int) -> Image.Image:
    """Create a solid color tile."""
    tile = Image.new("RGBA", (size, size), color)
    return tile


def main() -> None:
    if len(sys.argv) < 3:
        print(
            "Usage: button_nine_patch_proper.py <input.png> <output.png> [tile_size]",
            file=sys.stderr,
        )
        sys.exit(1)

    inp = Path(sys.argv[1])
    out = Path(sys.argv[2])
    tile_size = int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_TILE_SIZE

    img = Image.open(inp).convert("RGBA")
    w, h = img.size

    if w < tile_size * 3 or h < tile_size:
        print(
            f"Image {w}×{h} too small for tile_size {tile_size} (need width >= {tile_size * 3}, height >= {tile_size})",
            file=sys.stderr,
        )
        sys.exit(1)

    # Define regions in the source image
    # For a 123x57 button with 16px tile size:
    # - Left corner: 0-15
    # - Right corner: 107-122 (or w-16 to w)
    # - Top edge: 0-15
    # - Bottom edge: 42-56 (or h-16 to h)
    
    left_end = tile_size
    right_start = max(tile_size, w - tile_size)
    top_end = tile_size
    bottom_start = max(tile_size, h - tile_size)
    
    # Calculate center region
    center_x_start = left_end
    center_x_end = right_start
    center_y_start = top_end
    center_y_end = bottom_start

    # Extract the 9 regions
    # Corners (fixed size, don't stretch)
    top_left = img.crop((0, 0, tile_size, tile_size))
    top_right = img.crop((right_start, 0, w, tile_size))
    bottom_left = img.crop((0, bottom_start, tile_size, h))
    bottom_right = img.crop((right_start, bottom_start, w, h))

    # Edges (need to be solid for stretching)
    # Get dominant color from center for edges
    center_region = img.crop((center_x_start, center_y_start, center_x_end, center_y_end))
    center_color = get_dominant_color(center_region)
    
    # Top edge - sample from middle of top row
    top_edge_region = img.crop((center_x_start, 0, center_x_end, tile_size))
    top_edge_color = get_dominant_color(top_edge_region)
    
    # Bottom edge - sample from middle of bottom row
    bottom_edge_region = img.crop((center_x_start, bottom_start, center_x_end, h))
    bottom_edge_color = get_dominant_color(bottom_edge_region)
    
    # Left edge - sample from middle of left column
    left_edge_region = img.crop((0, center_y_start, tile_size, center_y_end))
    left_edge_color = get_dominant_color(left_edge_region)
    
    # Right edge - sample from middle of right column
    right_edge_region = img.crop((right_start, center_y_start, w, center_y_end))
    right_edge_color = get_dominant_color(right_edge_region)

    # Create output image (3x3 grid of tiles)
    out_img = Image.new("RGBA", (tile_size * 3, tile_size * 3))

    # Paste corners (they keep their detailed artwork)
    out_img.paste(top_left, (0, 0))
    out_img.paste(top_right, (tile_size * 2, 0))
    out_img.paste(bottom_left, (0, tile_size * 2))
    out_img.paste(bottom_right, (tile_size * 2, tile_size * 2))

    # Create solid color tiles for edges and center
    top_edge_tile = create_solid_tile(top_edge_color, tile_size)
    bottom_edge_tile = create_solid_tile(bottom_edge_color, tile_size)
    left_edge_tile = create_solid_tile(left_edge_color, tile_size)
    right_edge_tile = create_solid_tile(right_edge_color, tile_size)
    center_tile = create_solid_tile(center_color, tile_size)

    # Paste edges and center
    out_img.paste(top_edge_tile, (tile_size, 0))  # top edge
    out_img.paste(bottom_edge_tile, (tile_size, tile_size * 2))  # bottom edge
    out_img.paste(left_edge_tile, (0, tile_size))  # left edge
    out_img.paste(right_edge_tile, (tile_size * 2, tile_size))  # right edge
    out_img.paste(center_tile, (tile_size, tile_size))  # center

    out.parent.mkdir(parents=True, exist_ok=True)
    out_img.save(out, "PNG")
    print(f"Saved {out} ({tile_size * 3}×{tile_size * 3}, tile_size={tile_size})")
    print(f"  Center color: {center_color}")
    print(f"  Top edge color: {top_edge_color}")
    print(f"  Bottom edge color: {bottom_edge_color}")
    print(f"  Left edge color: {left_edge_color}")
    print(f"  Right edge color: {right_edge_color}")


if __name__ == "__main__":
    main()

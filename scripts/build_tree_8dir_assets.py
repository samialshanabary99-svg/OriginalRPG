import os
import math
from PIL import Image, ImageOps

BASE_DIR = "assets/sprites/environment/tree"
SWAY_SRC_DIR = os.path.join(BASE_DIR, "animations", "sway")
ROT_SRC = os.path.join(BASE_DIR, "rotations", "normal_tree.png")

DIRECTIONS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]

def warp_backward(img: Image.Image, angle_deg: float, dark_trunk: float = 1.0, dark_leaves: float = 1.0, lower_canopy: int = 0, skew_x: float = 0.0) -> Image.Image:
    w, h = img.size
    cx, cy = w / 2.0, h / 2.0
    R = w * 0.47
    
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rad = math.radians(angle_deg) * 0.40
    pix_out = out.load()
    
    for y in range(h):
        src_y = y - (lower_canopy if y < 175 else 0)
        if src_y < 0 or src_y >= h:
            continue
            
        for x in range(w):
            rel_y = (y - 128.0) / 128.0
            adjusted_x = x - skew_x * rel_y * 10.0
            
            dx = (adjusted_x - cx) / R
            if abs(dx) >= 1.0:
                src_x = adjusted_x
            else:
                phi_dest = math.asin(dx)
                phi_src = phi_dest - rad
                if abs(phi_src) >= math.pi / 2.0:
                    continue
                src_dx = math.sin(phi_src)
                src_x = cx + src_dx * R
            
            ix = int(round(src_x))
            iy = int(round(src_y))
            
            if 0 <= ix < w and 0 <= iy < h:
                p = img.getpixel((ix, iy))
                if p[3] > 0:
                    r, g, b, a = p
                    is_trunk = (iy >= 140 and r >= g * 0.85)
                    factor = dark_trunk if is_trunk else dark_leaves
                    if factor != 1.0:
                        r = int(max(0, min(255, r * factor)))
                        g = int(max(0, min(255, g * factor)))
                        b = int(max(0, min(255, b * factor)))
                    pix_out[x, y] = (r, g, b, a)
    return out

def generate_8_directions_for_image(base_img: Image.Image) -> dict:
    directions = {}
    # South (front)
    directions["south"] = base_img
    
    # East (side profile from east)
    east_img = warp_backward(base_img, -55, dark_trunk=0.96, dark_leaves=1.03, skew_x=0.45)
    directions["east"] = east_img
    directions["west"] = ImageOps.mirror(east_img)
    
    # South-East
    se_img = warp_backward(base_img, -28, dark_trunk=0.98, dark_leaves=1.02, skew_x=0.22)
    directions["south-east"] = se_img
    directions["south-west"] = ImageOps.mirror(se_img)
    
    # North (back view: trunk in shadow, rear canopy)
    mirrored_base = ImageOps.mirror(base_img)
    north_img = warp_backward(mirrored_base, 0, dark_trunk=0.82, dark_leaves=0.95, lower_canopy=5)
    directions["north"] = north_img
    
    # North-East
    ne_img = warp_backward(mirrored_base, -32, dark_trunk=0.86, dark_leaves=0.96, lower_canopy=3, skew_x=-0.22)
    directions["north-east"] = ne_img
    directions["north-west"] = ImageOps.mirror(ne_img)
    
    return directions

def main():
    print("Building 8-directional tree rotation assets...")
    rot_img = Image.open(ROT_SRC).convert("RGBA")
    rot_dirs = generate_8_directions_for_image(rot_img)
    rot_out_dir = os.path.join(BASE_DIR, "rotations")
    for d, img in rot_dirs.items():
        fname = f"{d}.png"
        img.save(os.path.join(rot_out_dir, fname))
    print(f"Saved {len(rot_dirs)} rotation sprites to {rot_out_dir}")
    
    print("Building 8-directional tree sway animation assets...")
    # Find all frame_00X.png in SWAY_SRC_DIR (or if they are already in south/, check)
    frame_files = []
    for i in range(9):
        fpath = os.path.join(SWAY_SRC_DIR, f"frame_{i:03d}.png")
        if os.path.exists(fpath):
            frame_files.append((i, fpath))
        else:
            # Check if in south/
            fpath_south = os.path.join(SWAY_SRC_DIR, "south", f"frame_{i:03d}.png")
            if os.path.exists(fpath_south):
                frame_files.append((i, fpath_south))
    
    print(f"Found {len(frame_files)} source sway frames.")
    
    for dir_name in DIRECTIONS:
        os.makedirs(os.path.join(SWAY_SRC_DIR, dir_name), exist_ok=True)
    
    for frame_idx, fpath in frame_files:
        src_frame = Image.open(fpath).convert("RGBA")
        dirs = generate_8_directions_for_image(src_frame)
        for dir_name, dir_img in dirs.items():
            target_path = os.path.join(SWAY_SRC_DIR, dir_name, f"frame_{frame_idx:03d}.png")
            dir_img.save(target_path)
            
    print("All 8 directional sway frames saved successfully!")

if __name__ == "__main__":
    main()

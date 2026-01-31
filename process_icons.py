from PIL import Image
import os
import math

# Map new artifact filenames to asset names
mapping = {
    "planet_sun_v2_1769843897627.png": "planet_sun",
    "planet_moon_v2_1769843911796.png": "planet_moon",
    "planet_mars_v2_1769843930111.png": "planet_mars",
    "planet_mercury_v2_1769843949253.png": "planet_mercury",
    "planet_jupiter_v2_1769843965497.png": "planet_jupiter",
    "planet_venus_v2_1769843993305.png": "planet_venus",
    "planet_saturn_v2_1769844011890.png": "planet_saturn",
    "planet_rahu_v2_1769844028459.png": "planet_rahu",
    "planet_ketu_1769843100636.png": "planet_ketu" # Fallback to v1
}

artifact_dir = "/Users/i074917/.gemini/antigravity/brain/d4156308-c062-4047-8a6a-e14c1145a9fa/"
assets_dir = "/Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app/Assets.xcassets/"

def color_dist(c1, c2):
    return math.sqrt(sum((a-b)**2 for a, b in zip(c1[:3], c2[:3])))

def remove_background_flood(img, tolerance=40):
    img = img.convert("RGBA")
    width, height = img.size
    pixels = img.load()
    
    # Sample background color from corners
    corners = [(0,0), (width-1, 0), (0, height-1), (width-1, height-1)]
    bg_color = pixels[0,0] # Assume top-left is bg
    
    # Queue for flood fill
    queue = []
    visited = set()
    
    # Initialize with corners that match bg color
    for x, y in corners:
        if color_dist(pixels[x,y], bg_color) < tolerance:
            queue.append((x,y))
            visited.add((x,y))
            
    # Directions: 4-connected
    dirs = [(0,1), (0,-1), (1,0), (-1,0)]
    
    while queue:
        cx, cy = queue.pop(0)
        
        # Make transparent
        pixels[cx, cy] = (0, 0, 0, 0)
        
        for dx, dy in dirs:
            nx, ny = cx + dx, cy + dy
            
            if 0 <= nx < width and 0 <= ny < height:
                if (nx, ny) not in visited:
                    # Check similarity to BG color OR to current pixel (gradient check)
                    # Here we check against original BG color to avoid eating into the planet
                    if color_dist(pixels[nx, ny], bg_color) < tolerance:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
                        
    return img

print("Processing images with flood fill...")

for filename, asset_name in mapping.items():
    src_path = os.path.join(artifact_dir, filename)
    dest_path = os.path.join(assets_dir, f"{asset_name}.imageset", f"{asset_name}.png")
    
    # Special handling for Ketu (Quota workaround + Astrological logic)
    # Use Rahu V2 (Dragon Head) and rotate 180 to make Ketu (Dragon Tail / South Node)
    if asset_name == "planet_ketu":
        # Use Rahu V2 source
        rahu_filename = "planet_rahu_v2_1769844028459.png"
        src_path = os.path.join(artifact_dir, rahu_filename)
        print(f"Generating optimized Ketu from Rahu source...")
        try:
            img = Image.open(src_path)
            # Remove background first
            img = remove_background_flood(img, tolerance=30)
            # Rotate 180 degrees
            img = img.rotate(180)
            
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            img.save(dest_path, "PNG")
            print(f"Saved generated Ketu to {dest_path}")
        except Exception as e:
            print(f"Error generating Ketu: {e}")
        continue

    if os.path.exists(src_path):
        print(f"Processing {asset_name}...")
        try:
            img = Image.open(src_path)
            # Use flood fill to remove contiguous background
            img = remove_background_flood(img, tolerance=30)
            
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            img.save(dest_path, "PNG")
            print(f"Saved to {dest_path}")
        except Exception as e:
            print(f"Error processing {filename}: {e}")
    else:
        print(f"Source not found: {src_path}")

print("Done.")

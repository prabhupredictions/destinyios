import os
import re

def clean_strings_file(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()

    # Regex to identify "key" = "value";
    # Captures key in group 1
    key_pattern = re.compile(r'^\s*"([^"]+)"\s*=\s*".*";')
    
    seen_keys = {}
    lines_to_remove = set()
    
    # First pass: identify duplicates (keep LAST occurrence)
    for i, line in enumerate(lines):
        match = key_pattern.match(line)
        if match:
            key = match.group(1)
            if key in seen_keys:
                # Mark previous occurrence for removal
                lines_to_remove.add(seen_keys[key])
            # Update to current index (current becomes the "keeper")
            seen_keys[key] = i
            
    if not lines_to_remove:
        return False

    with open(file_path, 'w') as f:
        for i, line in enumerate(lines):
            if i not in lines_to_remove:
                f.write(line)
                
    return True

base_dir = "/Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app"
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file == "Localizable.strings":
            path = os.path.join(root, file)
            if clean_strings_file(path):
                print(f"Cleaned {path}")
            else:
                print(f"No duplicates in {path}")

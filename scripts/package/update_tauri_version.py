#!/usr/bin/env python3
import json
import subprocess
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: update_tauri_version.py <path_to_tauri_conf_json>")
        sys.exit(1)
    
    tauri_conf_path = sys.argv[1]
    
    # Get version from getversion.sh (run via bash so this works on Windows too,
    # where the script can't be executed directly)
    try:
        version_output = subprocess.check_output(["bash", "scripts/package/getversion.sh"]).decode('utf-8').strip()
    except Exception as e:
        print(f"Error running getversion.sh: {e}")
        sys.exit(1)
    
    # Strip leading 'v'
    if version_output.startswith('v'):
        version = version_output[1:]
    else:
        version = version_output
        
    # Replace any beta/alpha with a hyphen for semver compatibility (e.g. 0.13.3b1 -> 0.13.3-b1)
    import re
    version = re.sub(r'([a-zA-Z]+)', r'-\1', version)
    # Remove double hyphens if any
    version = version.replace('--', '-')
    
    print(f"Updating {tauri_conf_path} to version {version}")
    
    try:
        with open(tauri_conf_path, 'r') as f:
            data = json.load(f)
            
        data['version'] = version
        
        with open(tauri_conf_path, 'w') as f:
            json.dump(data, f, indent=2)
            # Add a newline at the end of the file
            f.write('\n')
    except Exception as e:
        print(f"Error updating {tauri_conf_path}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json
import os
import subprocess
import sys


def get_version():
    """Mirrors scripts/package/getversion.sh, without needing a shell to run it
    (invoking the .sh script directly is unreliable on Windows runners)."""
    github_ref = os.environ.get("GITHUB_REF", "")
    if github_ref.startswith("refs/tags/v"):
        return os.environ["GITHUB_REF_NAME"]
    if os.environ.get("TRAVIS_TAG"):
        return os.environ["TRAVIS_TAG"]
    if os.environ.get("APPVEYOR_REPO_TAG_NAME"):
        return os.environ["APPVEYOR_REPO_TAG_NAME"]

    try:
        return subprocess.check_output(
            ["git", "describe", "--tags", "--abbrev=0", "--exact-match"],
            stderr=subprocess.DEVNULL,
        ).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        pass

    try:
        latest_tag = subprocess.check_output(
            ["git", "describe", "--tags", "--abbrev=0"], stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        latest_tag = "v0.0.0"

    try:
        commit_hash = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        commit_hash = "unknown"

    return f"{latest_tag}.dev-{commit_hash}"


def main():
    if len(sys.argv) < 2:
        print("Usage: update_tauri_version.py <path_to_tauri_conf_json>")
        sys.exit(1)

    tauri_conf_path = sys.argv[1]

    try:
        version_output = get_version()
    except Exception as e:
        print(f"Error determining version: {e}")
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

Linux Tauri packages (AppImage, deb, rpm)
=========================================

The AppImage / deb / rpm under aw-tauri/ (or the versioned
activitywatch-tauri-*-linux-* artifacts) are self-contained: they include
aw-tauri, aw-awatcher (window + AFK on X11 and Wayland), and aw-sync.

Install the package for your distro and run it — no extra step is required
for basic tracking. If in doubt, use the AppImage; copy it to a permanent
path such as ~/bin or /usr/local/bin because autostart depends on a stable
location.

Optional: full module pack (zip)
================================

The separate activitywatch-tauri-*-linux-*.zip still ships the full module
tree (including Python watchers). Use it when you need extras beyond the
Rust watchers bundled in the packages:

  1. Unzip the archive
  2. Run move-to-aw-modules.sh to copy modules (except aw-tauri) to ~/aw-modules/
  3. aw-tauri discovers aw-* executables there (and you can add your own)

Modules must start with the aw- prefix and must not have an extension
(e.g. no .sh).

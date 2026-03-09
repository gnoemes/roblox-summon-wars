# Raw Assets

This folder stores original source files that must stay in the repo for backup and re-upload.

Rules:
- `raw/` is intentionally outside every Rojo mapping and must not be added to any `*.project.json`.
- Keep the original files here after export/upload to Roblox.
- Runtime config should reference uploaded Roblox asset ids, not local file paths.
- For UI skill icons, prefer square PNG files with transparency.

Suggested layout:
- `raw/skills/icons/` - source skill icons before or after Roblox upload
- add more subfolders only when a real asset category appears

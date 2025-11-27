# combine_img_tags.sh — README

## Purpose
Merge metadata into a single Darktable-style XMP sidecar file for each image.

For each image the script extracts metadata from:
1. the image file itself (e.g. `image.jpg`)
2. the Lightroom sidecar (`image.xmp`), if present
3. the Darktable/Digikam sidecar (`image.jpg.xmp`), if present — this is the final destination

Later sources override earlier values.

## Important safety notes
- **ExifTool is required.** Install it before running.
- The script will overwrite or create the Darktable-style sidecar `name.ext.xmp`. ExifTool creates a backup named `name.ext.xmp_original` automatically when writing.
- The Lightroom sidecar (`name.xmp`) is deleted only after the new `name.ext.xmp` has been written successfully, and only if `--cleanup` is enabled (default: keep it).
- The original `name.ext.xmp` contents are preserved in the ExifTool backup file.
- The script does NOT search for or combine other sidecars such as `name_geo.xmp` or `name_edited.xmp`.
- **Always keep a backup of your files before running on a large dataset.**

## What the script does (accurately)
- Recursively finds image files under `SEARCH_DIR` (default: `.`) by a configurable list of extensions (case-insensitive).
- For each image:
  - Builds the source list in this order: image file → Lightroom sidecar (`name.xmp`, if present) → Darktable-style sidecar (`name.ext.xmp`, if present).
  - If a Darktable-style sidecar exists, it is copied to a temporary file and used as a source (so the original file can be safely overwritten).
  - Calls exiftool with ordered `-tagsFromFile <source> -all:all` entries so later sources override earlier values.
  - Writes the combined result to `name.ext.xmp` (Darktable-style sidecar). ExifTool creates `name.ext.xmp_original` as a backup.
  - On success: optionally deletes the Lightroom sidecar (`name.xmp`) if `--cleanup` is enabled, and removes any temporary files it created.
  - On failure: prints exiftool stderr and leaves original files intact (except for the ExifTool backup if created).

## Supported extensions (default)
PEF, JPEG, JPG, DNG, TIF, TIFF, GIF, PNG, BMP (case-insensitive).

To change this, edit the `IMAGE_EXTENSIONS` array in the script.

## Command-line options

```
--dryrun    Print the exiftool commands and actions without executing them.
--cleanup   Delete Lightroom sidecar (name.xmp) after successful merge. Default: keep it.
--help      Show usage and exit.
```

## Usage

1. Make executable:
    ```bash
    chmod +x combine_img_tags.sh
    ```

2. Test with dry-run first (recommended):
    ```bash
    ./combine_img_tags.sh /path/to/your/images --dryrun
    ```

3. Run from the directory you want to process (will use current directory by default):
    ```bash
    ./combine_img_tags.sh
    ```

4. Specify a directory and enable cleanup (arguments can be in any order):
    ```bash
    ./combine_img_tags.sh --cleanup /path/to/your/images
    ```

## Recommendations
- Always test on a small directory first with `--dryrun` to verify behavior.
- Keep regular backups of your images and XMP files.
- Review the output of `--dryrun` before running the actual merge.

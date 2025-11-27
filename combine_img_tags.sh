#!/bin/bash

# --- Configuration ---
# Case-insensitive list of extensions to find
IMAGE_EXTENSIONS=("PEF" "JPEG" "JPG" "DNG" "TIF" "TIFF" "GIF" "PNG" "BMP")
# --- End Configuration ---

SEARCH_DIR="."
DRYRUN=0
CLEANUP=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [SEARCH_DIR] [--dryrun] [--cleanup] [--help]

Arguments:
  SEARCH_DIR     Directory to search for images. Defaults to the current directory (".").
  --dryrun, -d   Print the exiftool commands and actions without executing them.
  --cleanup, -c  Delete Lightroom sidecar (name.xmp) after successful merge. Default: do NOT delete.
  --help, -h     Show this help and exit.
EOF
    exit 0
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --dryrun|-d) DRYRUN=1; shift ;;
        --cleanup|-c) CLEANUP=1; shift ;;
        --help|-h) usage ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            # Assume the first non-option argument is the search directory
            if [ -z "${SEARCH_DIR_SET:-}" ]; then
                SEARCH_DIR=$1
                SEARCH_DIR_SET=1
                shift
            else
                echo "Error: Only one search directory can be specified."
                usage
            fi
    esac
done

# Check if ExifTool is installed (skip check in dryrun only for presence note)
if [ "$DRYRUN" -ne 1 ]; then
    if ! command -v exiftool &> /dev/null
    then
        echo "🚨 Error: exiftool could not be found."
        echo "Please install ExifTool to run this script (or use --dryrun to preview)."
        exit 1
    fi
fi

echo "Starting metadata merge process in: $SEARCH_DIR"
if [ "$DRYRUN" -eq 1 ]; then
    echo "Mode: DRY-RUN (no changes will be made)"
else
    echo "Mode: EXECUTE"
fi
if [ "$CLEANUP" -eq 1 ]; then
    echo "Cleanup: Enabled (Lightroom sidecars will be deleted after successful merge)"
else
    echo "Cleanup: Disabled (Lightroom sidecars will be kept)"
fi
echo "------------------------------------------------------"

# Build find expression safely by passing multiple -iname args
FIND_ARGS=()
for ext in "${IMAGE_EXTENSIONS[@]}"; do
    FIND_ARGS+=( -iname "*.${ext}" -o )
done
# remove trailing -o
unset 'FIND_ARGS[${#FIND_ARGS[@]}-1]'

# Use find -print0 to safely handle any filenames
find "$SEARCH_DIR" '(' "${FIND_ARGS[@]}" ')' -print0 |
while IFS= read -r -d '' IMAGE_PATH; do

    # get image extension and base path
    IMAGE_EXT="${IMAGE_PATH##*.}"
    BASE_PATH="${IMAGE_PATH%.*}"
    # lightroom sidecar (name.xmp)
    LIGHTROOM_XMP="${BASE_PATH}.xmp"
    # darktable sidecar / final destination (name.ext.xmp)
    PRIMARY_XMP="${BASE_PATH}.${IMAGE_EXT}.xmp"

    echo ""
    echo "Processing image: $IMAGE_PATH"

    # Build ordered sources:
    # 1) image file itself
    # 2) lightroom sidecar (name.xmp) if present
    # 3) darktable sidecar (name.ext.xmp) if present
    SRC_LIST=()
    SRC_LIST+=( "$IMAGE_PATH" )

    if [ -f "$LIGHTROOM_XMP" ] && [ "$LIGHTROOM_XMP" != "$IMAGE_PATH" ]; then
        SRC_LIST+=( "$LIGHTROOM_XMP" )
    fi

    # If darktable sidecar exists, in dryrun just reference it; otherwise copy to a temp file to use as a source
    TMP_DARKTABLE_SRC=""
    if [ -f "$PRIMARY_XMP" ] && [ "$PRIMARY_XMP" != "$IMAGE_PATH" ]; then
        if [ "$DRYRUN" -eq 1 ]; then
            # In dry-run mode reference the existing file (no copy)
            SRC_LIST+=( "$PRIMARY_XMP" )
        else
            TMP_DARKTABLE_SRC="$(mktemp "$(dirname "$PRIMARY_XMP")/tmp_xmp.XXXXXX")"
            if cp -- "$PRIMARY_XMP" "$TMP_DARKTABLE_SRC"; then
                SRC_LIST+=( "$TMP_DARKTABLE_SRC" )
            else
                rm -f -- "$TMP_DARKTABLE_SRC" 2>/dev/null || true
                TMP_DARKTABLE_SRC=""
            fi
        fi
    fi

    # Build exiftool args: copy all tags from each source in order
    TAGS_FROM_ARGS=()
    for SRC in "${SRC_LIST[@]}"; do
        TAGS_FROM_ARGS+=( -tagsFromFile "$SRC" -all:all )
    done

    # Destination is the darktable-style sidecar (name.ext.xmp). exiftool will create it if missing.
    CMD=(exiftool "${TAGS_FROM_ARGS[@]}" "$PRIMARY_XMP")

    if [ "$DRYRUN" -eq 1 ]; then
        # Print the command that would be run (safe quoting)
        printf 'DRYRUN: would run:'
        for a in "${CMD[@]}"; do printf ' %q' "$a"; done
        echo

        # Indicate deletions that would occur on success
        if [ -f "$LIGHTROOM_XMP" ] && [ "$CLEANUP" -eq 1 ]; then
            echo "DRYRUN: would delete Lightroom sidecar: $LIGHTROOM_XMP (after successful merge)"
        elif [ -f "$LIGHTROOM_XMP" ]; then
            echo "DRYRUN: would KEEP Lightroom sidecar: $LIGHTROOM_XMP"
        fi

        if [ -n "$TMP_DARKTABLE_SRC" ]; then
            echo "DRYRUN: would remove temporary copy: $TMP_DARKTABLE_SRC (if created)"
        fi

        continue
    fi

    # Run and capture output on failure
    ERRFILE="/tmp/exiftool_err.$$"
    if "${CMD[@]}" 2>"$ERRFILE"; then
        echo "✅ Merged metadata successfully into: $(basename "$PRIMARY_XMP")"

        # Remove the lightroom sidecar (name.xmp) only after success and only if cleanup enabled
        if [ "$CLEANUP" -eq 1 ] && [ -f "$LIGHTROOM_XMP" ]; then
            if rm -f -- "$LIGHTROOM_XMP"; then
                echo "   -> Deleted original lightroom sidecar: $(basename "$LIGHTROOM_XMP")"
            else
                echo "   -> Failed to delete lightroom sidecar: $(basename "$LIGHTROOM_XMP")"
            fi
        else
            if [ -f "$LIGHTROOM_XMP" ]; then
                echo "   -> Kept original lightroom sidecar: $(basename "$LIGHTROOM_XMP")"
            fi
        fi

        # Remove temporary copy of darktable sidecar, if created
        if [ -n "$TMP_DARKTABLE_SRC" ] && [ -f "$TMP_DARKTABLE_SRC" ]; then
            rm -f -- "$TMP_DARKTABLE_SRC"
        fi

        echo "   -> ExifTool backup (if any) left as-is."
        rm -f -- "$ERRFILE"
    else
        echo "❌ Command failed for $IMAGE_PATH"
        echo "---- exiftool stderr ----"
        cat "$ERRFILE"
        rm -f -- "$ERRFILE"
        # cleanup temp if created
        if [ -n "$TMP_DARKTABLE_SRC" ] && [ -f "$TMP_DARKTABLE_SRC" ]; then
            rm -f -- "$TMP_DARKTABLE_SRC"
        fi
    fi

done

echo ""
echo "------------------------------------------------------"
echo "Metadata merge completed."

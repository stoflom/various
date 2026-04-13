# GPX Processing Log

**Date:** October 2025
**Context:** Cleanup and organization of GPS data from various backups.

## Process Workflow

*   **Initial State**: `~/Documents/gpx/archives` was populated with all `.gdb` and `.gpx` files discovered during backups.
*   **Conversion**: Converted `.gdb` files to `.gpx` format using `gpsbabel` (via `gdb-to-gpx.sh`). This process introduced significant duplication.
*   **First Pass Deduplication**: Ran `jdupes` to remove exact duplicates. Note: This was insufficient as `gpsbabel` output differs slightly from original MapSource files.
*   **Second Pass Deduplication (Scripted)**:
    *   Used `test_and_clean.sh` (leveraging the `xmlgpx.pl` Perl script) to identify and remove tracks that contained no data.
    *   Used `test_sort_hash_and_clean.sh` to identify and remove duplicate tracks based on content hashing.
*   **Manual Refinement (Viking)**:
    *   Opened remaining files individually in Viking.
    *   Sorted tracks chronologically (date ascending).
    *   Exported the complete layer (including routes and waypoints) into new, uniquely named GPX files.
    *   **Naming Convention**: New files include the track date and a location indicator.
    *   **Destination**: Exported files were saved under `.../TracksEtc/`.
    *   Performed a final round of manual duplicate removal within Viking.
*   **Final Organization**: Moved the cleaned files into their respective year/GPX folders within the `PICTURES` directory tree.

## Observations
*   **Missing Data**: No GPX files were found for the period 2011–2015.

---
*Log entry by CL, Oct 2025*

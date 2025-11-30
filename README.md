# Bash Utilities

A collection of miscellaneous shell scripts for file management, system tasks, and command-line automation.

----
## Table of Contents

- [Installation](#installation)
- [Scripts](#scripts)
  - [File Management](#file-management)
  - [GPS & GPX Utilities](#gps--gpx-utilities)
  - [EXIF Data Utilities](#exif-data-utilities)
- [Dependencies](#dependencies)

## Installation

This project uses a `Makefile` for easy installation and uninstallation of the scripts.

### Prerequisites

- `make` must be installed on your system.
- The `~/.local/bin` directory should be in your `$PATH`. This is standard on most modern Linux distributions.

### Instructions

1.  **Install Scripts**: To make the scripts available as system-wide commands, run the following from the project directory:
    ```bash
    make install
    ```
    This command copies the executable scripts to `~/.local/bin/`.

2.  **Uninstall Scripts**: To remove all installed scripts from `~/.local/bin/`, run:
    ```bash
    make uninstall
    ```

---

## Scripts

### File Management

*   **`ffile-copy`**: A powerful wrapper for `find` and `cp` to collect files from various locations into a single directory, automatically handling potential name collisions.

*   **`compare_and_delete`**: Finds and deletes files in a target directory that are content-duplicates of files in a separate reference directory. Useful for cleaning up redundant copies.

### GPS & GPX Utilities

A suite of tools for managing GPS data in image files and for cleaning and converting GPX track files. For a detailed description of the GPX file cleanup workflow, see README-gpx.md.

*   **`gdb-to-gpx`**: Converts Garmin GDB database files to the more universal GPX format using `gpsbabel`.

*   **`gpsinfo`, `gpstags`**: Utilities to manipulate and view GPS metadata within image files.

*   **`test_and_clean`, `test_sort_hash_and_clean`, `xmlgpx.pl`**: A set of scripts designed to find and remove duplicate or empty GPX track files.
    - `test_and_clean.sh` uses `xmlgpx.pl` to check for GPX files that contain no tracks.
    - `test_sort_hash_and_clean.sh` identifies duplicate tracks by sorting and hashing their content.

### EXIF Data Utilities

Tools to manage EXIF data in images.

*   **`combine_img_tags.sh`**: Merge metadata into a single Darktable-style XMP sidecar file for each image using `exiftool`.

---

## Dependencies

Some scripts require external command-line tools to be installed:

*   **`gdb-to-gpx`**: Requires `gpsbabel`.
*   **`combine_img_tags.sh`**: Requires `exiftool`.
*   **`test_and_clean.sh`**: Requires `xmlgpx.pl` (included in this repository).

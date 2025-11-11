# Bash Utilities

A collection of miscellaneous shell scripts for file management, system tasks, and command-line automation.

----
## Table of Contents

- [Installation](#installation)
- [Scripts](#scripts)
  - [File Management](#file-management)
  - [GPS & GPX Utilities](#gps--gpx-utilities)
  - [System & Backup](#system--backup)

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

*   **`cp-safe`**: A safe copy utility. If a file with the same name already exists at the destination, `cp-safe` renames the new file with a numeric suffix instead of overwriting it.

### GPS & GPX Utilities

A suite of tools for managing GPS data in image files and for cleaning and converting GPX track files. For a detailed description of the GPX file cleanup workflow, see README-gpx.md.

*   **`gdb-to-gpx`**: Converts Garmin GDB database files to the more universal GPX format using `gpsbabel`.

*   **`gpsinfo`, `gpstags`**: Utilities to manipulate and view GPS metadata within image files.

*   **`test_and_clean`, `test_sort_hash_and_clean`, `xmlgpx.pl`**: A set of scripts designed to find and remove duplicate or empty GPX track files.
    - `test_and_clean.sh` uses `xmlgpx.pl` to check for GPX files that contain no tracks.
    - `test_sort_hash_and_clean.sh` identifies duplicate tracks by sorting and hashing their content.

### System & Backup

#### `btrfs_backup.sh`

A script to take Btrfs snapshots of the `/` and `/home` subvolumes and send them incrementally to a backup disk.

##### ⚙️ Initial Setup and Execution

1.  **Create Snapshot Directories**

    Ensure the Btrfs subvolumes where snapshots will be stored exist. If not, create them first.

    ```bash
    # Example: Assuming /snapshots is a mounted Btrfs volume
    sudo btrfs subvolume create /snapshots
    sudo btrfs subvolume create /home/snapshots
    ```

2.  **Set Up Initial History File (Optional)**

    For the script's incremental backup feature to work from the first run, you can initialize a history file with the paths to your initial **full** snapshots. If this file does not exist, the script will create it on its first run.

    Create the file `/root/.btrfs_last_snapshot` with the following format:

    ```ini
    root:/snapshots/root_20251111102847
    home:/home/snapshots/home_20251111103030
    ```

3.  **Run the Script**

    Execute the script with root privileges:

    ```bash
    sudo ./btrfs_backup.sh
    ```
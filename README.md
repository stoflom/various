
# Bash Utilities

A collection of miscellaneous shell scripts for file management, system tasks, and command-line automation.

---

## Installation

This project uses a `Makefile` for easy installation and uninstallation of the scripts.

### Prerequisites

-   `make` must be installed.
-   The `~/.local/bin` directory should be in your `$PATH`. This is standard on most modern Linux distributions.

### Instructions

1.  **Install:** To install the scripts, run the following command from the project directory:
    ```bash
    make install
    ```
    -   Copy executable scripts (e.g., `compare_and_delete.sh`, `gdb-to-gpx.sh`) to `~/.local/bin/`, making them available as commands.

2.  **Uninstall:** To remove all installed scripts, run:
    ```bash
    make uninstall
    ```

---

### Executable Scripts (run as commands)

-   `ffile-copy`: A powerful wrapper for `find` and `cp` to collect files into a single directory, handling name collisions.
-   `compare_and_delete`: Finds and deletes files in a target directory that are content-duplicates of files in a reference directory.
-   `cp-safe`: A safe copy utility that renames the destination file with a numeric suffix if it already exists.
-   `gpsinfo, gpstags, gdb-to-gpx`: Utilities to manipulate gps info in images and to convert Garmin gdb files to gpx with gpsbabel.
-   `test_and_clean, test_sort_hash_and_clean, xmlgpx.pl`: Utilities to find and remove gpx files with no tracks.



### btrfs_backup.sh script to take btrfs snapshots of / and /home and to send them to a backup disk (incrementally)

## ⚙️ Initial Setup and Execution

### 1\. Create Snapshot Directories

Ensure the subvolumes where snapshots will live actually exist. If they don't, you need to create them as Btrfs subvolumes first:

```bash
# Assuming /snapshots is already mounted/existing. If not, create it:
# btrfs subvolume create /snapshots 
# btrfs subvolume create /home/snapshots 
```

### 2\. Set Up Initial History File

For the script to work immediately, you need to initialize the history file with the provided full snapshot paths. This tells the script which snapshots were your initial **full** backups.

Create the file `/root/.btrfs_last_snapshot` with the contents of existing snapshots if they exist, if not the ecript will create it for you:

```
root:/snapshots/root_20251111102847
home:/home/snapshots/home_20251111103030
```

### 3\. Run the Script

Execute the script as root:

```bash
sudo ./btrfs_backup.sh
```


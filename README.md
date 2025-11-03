
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
`gpsinfo, gpstags, gdb-to-gpx`: Utilities to manipulate gps info in images and to convert Garmin gdb files to gpx with gpsbabel.
`test_and_clean, test_sort_hash_and_clean, xmlgpx.pl`: Utilities to find and remove gpx files with no tracks.



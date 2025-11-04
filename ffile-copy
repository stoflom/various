#!/usr/bin/env bash
# ffile-copy - Find files and copy them to a specified directory
# using `cp --backup=numbered` to avoid collisions.
#
# This script acts as a wrapper around 'find' to simplify copying files
# into a single directory, with robust handling for duplicate filenames.
# Only regular files ('-type f') are copied.
#
# Examples:
#   ffile-copy.sh /dest/dir /source/path -name '*.txt'  (copies *.txt files)
#   ffile-copy.sh /dest/dir /source/path -mtime -1  (copies files modified in the last 24 hours)
#   ffile-copy.sh /dest/dir -L /source/path -name '*.jpg' (follows symbolic links)

set -euo pipefail

usage() {
    cat <<'USAGE'
Copies files found by 'find' into <dest_dir>, handling name collisions
using 'cp --backup=numbered'.

Usage: ffile-copy.sh [options] <dest_dir> [find_args...]
Options:
  -h, --help    	Show this help and exit
  -ok, --confirm	Ask user to confirm each copy.

<dest_dir> is the target directory for copies.
[find_args...] are any valid arguments for the 'find' command,
	such as: -L /path/to/search -ls -print -name '*.txt'
	(The '-L' causes symbolic links to be followed,
	 '-ls -print' prints output in 'ls -dils' format,
	 '-name '*.txt' ' searches for filenames matching *.txt.
	 See 'man find' for other search options.)
e.g #>ffile-copy.sh /dest/dir -L /source/path -ls -print -name '*.txt'
USAGE
    exit 1
}
user_confirm=0

# --- Argument Parsing ---
find_args=()
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage ;;
        -ok|--confirm) user_confirm=1 ; shift ;; 
        --) shift ; find_args+=("$@") ; break ;;
        -*) # It's a find argument, stop parsing script options
            find_args+=("$@")
            break
            ;;
        *) # First non-option is dest_dir
            find_args+=("$@")
            break
            ;;
    esac
done

if [ ${#find_args[@]} -lt 1 ]; then
    echo "Error: Missing <dest_dir>." >&2
    usage
fi

dest_dir="${find_args[0]}"
find_args=("${find_args[@]:1}") # Remove dest_dir from find_args

if [ ${#find_args[@]} -lt 1 ]; then
    echo "Error: Missing <dest_dir> and/or find arguments." >&2
    usage
fi

if [ ! -d "$dest_dir" ]; then
        echo "Destination '$dest_dir' does not exist. It will be created." >&2
        mkdir -p -- "$dest_dir" || { echo "Error: Failed to create destination '$dest_dir'." >&2; exit 1; }
fi

echo "Executing copy to '$dest_dir'..."
if [ "$user_confirm" -eq 1 ]; then
    echo "Confirmation will be required for each file."
    find "${find_args[@]}" -type f -ok cp -p --backup=numbered -t "$dest_dir" -- {} \;
else
    find "${find_args[@]}" -type f -exec cp -p --backup=numbered -t "$dest_dir" -- {} +
fi
echo "Done."


exit 0

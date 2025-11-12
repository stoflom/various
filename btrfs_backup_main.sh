#!/bin/bash
# Main execution script for Btrfs Incremental Backup
# This script calls the backup_subvolume function defined in btrfs_backup.sh
#
# Must be run as root.

# --- Configuration ---
# Source Subvolumes
# Define the subvolumes to back up in an array.
# Each element is a string with three space-separated values (the last is used to generate a unique snapshot name):
# "SOURCE_SUBVOLUME SNAPSHOT_DIRECTORY SNAPSHOT_TYPE_PREFIX"
SUBVOLUMES_TO_BACKUP=(
	"/ /snapshots root"
	"/home /home/snapshots home"
	"/home/stoflom/Pictures/latest /home/stoflom/Pictures/latest/snapshots latest_pictures"
)

# Backup Destination Mount Point and Subvolume
BACKUP_DEST="$BACKUP_MOUNT/fedora_snapshots"

# Include the function definition
source btrfs_backup.sh

# --- Main Execution ---

# Check if history file exists, if not create it with empty lines
# Check if the backup destination is mounted and exists
if [ ! -d "$BACKUP_DEST" ]; then
	echo "ERROR: Backup destination $BACKUP_DEST does not exist or is not mounted. Exiting."
	exit 1
fi

# Loop through the array and back up each subvolume
for item in "${SUBVOLUMES_TO_BACKUP[@]}"; do
	# Split the string into variables
	read -r SOURCE_SUBVOL SNAP_DIR SNAP_TYPE <<<"$item"

	# Define the history file path for this specific subvolume
	HISTORY_FILE="${SNAP_DIR}/.btrfs_last_snapshot"

	# Ensure the snapshot directory exists
	mkdir -p "$SNAP_DIR"

	# Check if history file exists, if not create it
	if [ ! -f "$HISTORY_FILE" ]; then
		touch "$HISTORY_FILE"
		echo "Created history file: $HISTORY_FILE"
	fi

	backup_subvolume "$SOURCE_SUBVOL" "$SNAP_DIR" "$BACKUP_DEST" "$HISTORY_FILE" "$SNAP_TYPE"
	echo -e "\n======================================================\n"
done

echo -e "\n--- Script Execution Complete ---"

exit 0

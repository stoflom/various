#!/bin/bash
# Main orchestration script for Btrfs Incremental Backups.
# This script calls the backup_subvolume function defined in btrfs_backup.sh
#
# Must be run as root.

# Exit on error, treat unset variables as errors, and propagate exit status in pipelines.
set -euo pipefail


# --- Configuration ---

# SUBVOLUMES_TO_BACKUP: Array of Btrfs subvolumes to back up.
# Define the subvolumes to back up in an array. The script will derive
# the snapshot directory and name prefix from these paths. The directory
# for snapshots will be created under each source subvolume root (e.g., /home/snapshots)
# and the unique snapshot name will be the basename of the subvolume path + timestamp.
SUBVOLUMES_TO_BACKUP=(
	"/"
	"/home"
#	"/home/stoflom/Pictures/latest"
)

# Backup Destination Mount Point and Subvolume
BACKUP_MOUNT="/run/media/stoflom/BlackArmor"
#BACKUP_MOUNT="/mnt/BlackArmor"
#BACKUP_DEST="$BACKUP_MOUNT/fedora_snapshots"
BACKUP_DEST="$BACKUP_MOUNT/fedora2_snapshots"


echo "--- btrfs_backup_main script execution Started: $(date) ---"

# --- Source function library ---

# Get the absolute path of the directory where this script is located.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
BACKUP_FUNCTION_SCRIPT="${SCRIPT_DIR}/btrfs_backup.sh"

##DEBUG
#echo "Sourcing backup function script from: $BACKUP_FUNCTION_SCRIPT"

if ! source "$BACKUP_FUNCTION_SCRIPT"; then
    echo "ERROR: Failed to source the backup function script at '$BACKUP_FUNCTION_SCRIPT'. Exiting." >&2
    exit 1
fi

# --- Main Execution ---

# Check if the backup destination is mounted and exists
if [ ! -d "$BACKUP_DEST" ]; then
	echo "ERROR: Backup destination $BACKUP_DEST does not exist or is not mounted. Exiting."
	exit 1
fi

# Loop through the array and back up each subvolume
for SOURCE_SUBVOL in "${SUBVOLUMES_TO_BACKUP[@]}"; do
	echo -e "======================================================"
	echo "Processing source subvolume: $SOURCE_SUBVOL"

	# --- Derive snapshot configuration from source subvolume ---
	if [ "$SOURCE_SUBVOL" = "/" ]; then
		# Special case for the root subvolume
		SNAP_DIR="/snapshots"
		SNAP_NAME="root"
	else
		# For all other subvolumes
		SNAP_DIR="${SOURCE_SUBVOL}/snapshots"
		SNAP_NAME=$(basename "$SOURCE_SUBVOL")
	fi

##DEBUG
#    echo "SNAP_DIR: $SNAP_DIR"
#    echo "SNAP_NAME: $SNAP_NAME"

	# Ensure the snapshot directory exists
	mkdir -p "$SNAP_DIR"

	# Find the most recent snapshot in the snapshot directory to use as a parent for the incremental backup.
	LAST_SNAP_PATH=""
	# Use find to get the latest snapshot directory. It's safer than parsing ls.
	# -maxdepth 1 to avoid searching in subdirectories.
	# -type d for directories.
	# -name to match the pattern.
	# The part after the pipe will sort them and get the last one.
	LATEST_SNAPSHOT=$(find "$SNAP_DIR" -maxdepth 1 -type d -name "${SNAP_NAME}_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" | sort | tail -n 1)
	if [ -n "$LATEST_SNAPSHOT" ]; then
		LAST_SNAP_PATH="$LATEST_SNAPSHOT"
	fi
	
 ##DEBUG
 #   echo "LAST_SNAP_PATH: $LAST_SNAP_PATH"

	# If the last snapshot doesn't exist on disk, clear the variable to force a full backup.
	if [ -n "$LAST_SNAP_PATH" ] && [ ! -d "$LAST_SNAP_PATH" ]; then
		echo "WARNING: Last snapshot '$LAST_SNAP_PATH' not found. Forcing a full backup."
		LAST_SNAP_PATH=""
	fi
	# Construct the full path for the new snapshot
	NEW_SNAP_NAME="${SNAP_NAME}_$(date +%Y%m%d%H%M%S)"
	NEW_SNAP_PATH="${SNAP_DIR}/${NEW_SNAP_NAME}"

##DEBUG
#    echo "NEW_SNAP_PATH: $NEW_SNAP_PATH"


	# Call the backup function, checking its exit code for success
	if backup_subvolume "$SOURCE_SUBVOL" "$BACKUP_DEST" "$NEW_SNAP_PATH" "$LAST_SNAP_PATH"; then
		echo "SUCCESS: Backup function completed for $SOURCE_SUBVOL."
		# No need to update any history file. The next run will find the new snapshot.
	fi

done

echo "--- Script Execution Complete: $(date) ---"

exit 0

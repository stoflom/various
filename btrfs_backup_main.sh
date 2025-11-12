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
	"/home/stoflom/Pictures/latest"
)

# Backup Destination Mount Point and Subvolume
BACKUP_MOUNT="/run/media/stoflom/BlackArmor""
BACKUP_DEST="$BACKUP_MOUNT/fedora_snapshots"

# Include the function definition
source btrfs_backup.sh

echo "--- Starting Btrfs Backup Run: $(date) ---"

# --- Main Execution ---

# Check if the backup destination is mounted and exists
if [ ! -d "$BACKUP_DEST" ]; then
	echo "ERROR: Backup destination $BACKUP_DEST does not exist or is not mounted. Exiting."
	exit 1
fi

# Loop through the array and back up each subvolume
for SOURCE_SUBVOL in "${SUBVOLUMES_TO_BACKUP[@]}"; do
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

	# Define the history file path for this specific subvolume
	# The history file tracks the last successful snapshot for incremental backups.
	HISTORY_FILE="${SNAP_DIR}/.btrfs_last_snapshot"

	# Ensure the snapshot directory exists
	mkdir -p "$SNAP_DIR"

	# Check if history file exists, if not create it
	if [ ! -f "$HISTORY_FILE" ]; then
		touch "$HISTORY_FILE"
		echo "Created history file: $HISTORY_FILE"
	fi

	# Get the last successfully sent snapshot path from history
	LAST_SNAP_PATH=$(grep "^${SNAP_NAME}:" "$HISTORY_FILE" | cut -d ':' -f 2)

	# If the last snapshot doesn't exist on disk, clear the variable to force a full backup.
	if [ -n "$LAST_SNAP_PATH" ] && [ ! -d "$LAST_SNAP_PATH" ]; then
		echo "WARNING: Last snapshot '$LAST_SNAP_PATH' not found. Forcing a full backup."
		LAST_SNAP_PATH=""
	fi
	# Construct the full path for the new snapshot
	NEW_SNAP_NAME="${SNAP_NAME}_$(date +%Y%m%d%H%M%S)"
	NEW_SNAP_PATH="${SNAP_DIR}/${NEW_SNAP_NAME}"

	# Call the backup function, checking its exit code for success
	if backup_subvolume "$SOURCE_SUBVOL" "$BACKUP_DEST" "$NEW_SNAP_PATH" "$LAST_SNAP_PATH"; then
		echo "SUCCESS: Backup function completed for $SOURCE_SUBVOL."

		# Update the history file atomically using a secure temporary file.
		TEMP_HISTORY=$(mktemp)
		# Ensure the temp file is cleaned up on script exit
		trap 'rm -f "$TEMP_HISTORY"' EXIT

		# Copy existing lines, but exclude the one we're updating
		grep -v "^${SNAP_NAME}:" "$HISTORY_FILE" >"$TEMP_HISTORY"

		# Append the new successful snapshot path
		echo "${SNAP_NAME}:${NEW_SNAP_PATH}" >>"$TEMP_HISTORY"
		# Atomically replace the old file with the new one
		mv "$TEMP_HISTORY" "$HISTORY_FILE"

		echo "History updated to: ${NEW_SNAP_PATH}"
	fi

	echo -e "\n======================================================\n"
done

echo "--- Script Execution Complete: $(date) ---"
echo -e "##########################################################################\n"

exit 0

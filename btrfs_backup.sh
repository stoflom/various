#!/bin/bash
#
# Btrfs Backup Function Library
#
# This script contains the backup_subvolume function used for creating
# Btrfs snapshots and sending them to a backup destination. It is intended
# to be sourced by a main execution script.

# Performs a Btrfs snapshot and an incremental send/receive operation.
#
# @param $1 - SOURCE_SUBVOL: The source subvolume to back up (e.g., "/").
# @param $2 - SNAP_DIR: The directory where the snapshot will be created.
# @param $3 - BACKUP_DEST: The destination subvolume for the backup.
# @param $4 - HISTORY_FILE: The path to the file tracking the last successful backup.
# @param $5 - SNAP_TYPE: A unique identifier for the backup type (e.g., "root", "home").
backup_subvolume() {
	local SOURCE_SUBVOL=$1
	local SNAP_DIR=$2
	local BACKUP_DEST=$3
	local HISTORY_FILE=$4
	local SNAP_TYPE=$5

	echo "--- Starting Btrfs Backup for $SOURCE_SUBVOL ---"

	# 1. Generate new snapshot name
	local NEW_SNAP_NAME="${SNAP_TYPE}_$(date +%Y%m%d%H%M%S)"
	NEW_SNAP_PATH="${SNAP_DIR}/${NEW_SNAP_NAME}"

	# 2. Get the last successfully sent snapshot path from history
	LAST_SNAP_PATH=$(grep "^${SNAP_TYPE}:" "$HISTORY_FILE" | cut -d ':' -f 2)

	# 3. Create the read-only snapshot
	echo "Creating read-only snapshot: ${NEW_SNAP_PATH}"
	btrfs subvolume snapshot -r "$SOURCE_SUBVOL" "$NEW_SNAP_PATH"
	if [ $? -ne 0 ]; then
		echo "ERROR: Failed to create snapshot for $SOURCE_SUBVOL."
		return 1
	fi

	# 4. Perform btrfs send/receive
	if [ -n "$LAST_SNAP_PATH" ] && [ -d "$LAST_SNAP_PATH" ]; then
		# Incremental backup (if parent exists)
		echo "Performing INCREMENTAL send/receive."
		echo "Parent: ${LAST_SNAP_PATH}"
		btrfs send -p "$LAST_SNAP_PATH" "$NEW_SNAP_PATH" | btrfs receive "$BACKUP_DEST"
	else
		# Full backup (first time or parent missing/deleted)
		echo "Performing FULL send/receive (no parent found)."
		btrfs send "$NEW_SNAP_PATH" | btrfs receive "$BACKUP_DEST"
	fi

	if [ $? -eq 0 ]; then
		echo "SUCCESS: Backup completed for $SOURCE_SUBVOL. Updating history file."

		# 5. Update the history file atomically
		TEMP_HISTORY="/tmp/btrfs_history_temp_$$"
		# Copy existing lines, but exclude the one we're updating
		grep -v "^${SNAP_TYPE}:" "$HISTORY_FILE" >"$TEMP_HISTORY"
		# Append the new successful snapshot path
		echo "${SNAP_TYPE}:${NEW_SNAP_PATH}" >>"$TEMP_HISTORY"
		# Atomically replace the old file with the new one
		mv "$TEMP_HISTORY" "$HISTORY_FILE"

		echo "History updated to: ${NEW_SNAP_PATH}"
	else
		echo "ERROR: Btrfs send/receive failed for $SOURCE_SUBVOL. History NOT updated."
		# If send/receive fails, delete the local snapshot to avoid clutter
		echo "Cleaning up local snapshot: ${NEW_SNAP_PATH}"
		btrfs subvolume delete "$NEW_SNAP_PATH"
		return 1
	fi

	echo "--- Finished Btrfs Backup for $SOURCE_SUBVOL ---"
}

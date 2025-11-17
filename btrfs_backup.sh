#!/bin/bash
#
# Btrfs Backup Function Library
# This file contains functions for creating and sending Btrfs snapshots.
# It is intended to be sourced by a main script.

# take_snapshot()
# Creates a local read-only Btrfs snapshot.
#
# On success, it returns exit code 0.
# On failure, it returns a non-zero exit code.
#
# @param $1 SOURCE_SUBVOL   The source subvolume to snapshot (e.g., "/home").
# @param $2 NEW_SNAP_PATH   The full, absolute path for the new snapshot to be created.
take_snapshot() {
	local SOURCE_SUBVOL=$1
	local NEW_SNAP_PATH=$2

	echo "--- Creating read-only snapshot for '$SOURCE_SUBVOL' ---"
	echo "Snapshot path: $NEW_SNAP_PATH"

	if btrfs subvolume snapshot -r "$SOURCE_SUBVOL" "$NEW_SNAP_PATH"; then
		echo "SUCCESS: Snapshot created at $NEW_SNAP_PATH."
		return 0
	else
		echo "ERROR: Failed to create snapshot for '$SOURCE_SUBVOL' at '$NEW_SNAP_PATH'."
		return 1
	fi
}

# send_snapshot()
# Sends a local Btrfs snapshot to a backup destination.
# Can perform a full or an incremental send.
# Logs success or failure to syslog via the `logger` command.
#
# @param $1 SNAPSHOT_TO_SEND The full path of the snapshot to send.
# @param $2 BACKUP_DEST      The destination path for the btrfs receive operation.
# @param $3 PARENT_SNAPSHOT  (Optional) Full path to the parent for an incremental send.
send_snapshot() {
	local SNAPSHOT_TO_SEND=$1
	local BACKUP_DEST=$2
	local PARENT_SNAPSHOT=$3
	local SNAP_NAME=$(basename "$SNAPSHOT_TO_SEND")

	echo "--- Sending snapshot '$SNAP_NAME' to '$BACKUP_DEST' ---"

	if [ -n "$PARENT_SNAPSHOT" ] && [ -d "$PARENT_SNAPSHOT" ]; then
		echo "Performing INCREMENTAL send from parent: $PARENT_SNAPSHOT"
		btrfs send -p "$PARENT_SNAPSHOT" "$SNAPSHOT_TO_SEND" | btrfs receive "$BACKUP_DEST"
	else
		echo "Performing FULL send (no suitable parent found)."
		btrfs send "$SNAPSHOT_TO_SEND" | btrfs receive "$BACKUP_DEST"
	fi

	if [ $? -eq 0 ]; then
		logger -t btrfs_backup_script -p local0.info "Snapshot ${SNAP_NAME} -> ${BACKUP_DEST} COMPLETED"
		echo "SUCCESS: Btrfs send/receive completed for ${SNAP_NAME}."
		return 0
	else
		logger -t btrfs_backup_script -p local0.error "Snapshot ${SNAP_NAME} -> ${BACKUP_DEST} FAILED"
		echo "ERROR: Btrfs send/receive failed for ${SNAP_NAME}."
		return 1 # Indicate failure
	fi
}

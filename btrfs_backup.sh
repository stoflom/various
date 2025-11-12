#!/bin/bash
#
# Btrfs Backup Function Library
# This file contains the backup_subvolume function and is intended to be
# sourced by a main script.

# backup_subvolume()
# Creates a local Btrfs snapshot and sends it to a backup destination.
# It can perform a full or an incremental backup.
# Logs success or failure to syslog via the `logger` command.
#
# On success, it returns exit code 0.
# On failure, it returns a non-zero exit code, leaving the created snapshot in place.
#
# @param $1 SOURCE_SUBVOL   The source subvolume to back up (e.g., "/home").
# @param $2 BACKUP_DEST     The destination path for the btrfs receive operation.
# @param $3 NEW_SNAP_PATH   The full, absolute path for the new snapshot to be created.
# @param $4 LAST_SNAP_PATH  (Optional) Full path to the parent snapshot for an incremental backup.
backup_subvolume() {
	local SOURCE_SUBVOL=$1
	local BACKUP_DEST=$2
	local NEW_SNAP_PATH=$3
	local LAST_SNAP_PATH=$4
	local NEW_SNAP_NAME=$(basename "$NEW_SNAP_PATH")

	echo "--- Starting Btrfs Backup for $SOURCE_SUBVOL ---"

	# 1. Create the read-only snapshot
	echo "Creating read-only snapshot: ${NEW_SNAP_PATH}"
	btrfs subvolume snapshot -r "$SOURCE_SUBVOL" "$NEW_SNAP_PATH"
	if [ $? -ne 0 ]; then
		echo "ERROR: Failed to create snapshot for $SOURCE_SUBVOL."
		return 1
	fi

	# 2. Perform btrfs send/receive
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
		logger -t btrfs_backup_script -p local0.info "Snapshot ${NEW_SNAP_NAME} for ${SOURCE_SUBVOL} -> ${BACKUP_DEST} COMPLETED"
		# Return success
		return 0
	else
		echo "ERROR: Btrfs send/receive failed for $SOURCE_SUBVOL. History NOT updated."
		logger -t btrfs_backup_script -p local0.error "Snapshot ${NEW_SNAP_NAME} for ${SOURCE_SUBVOL} -> ${BACKUP_DEST} FAILED"
		# The local snapshot is intentionally kept for potential manual intervention or retry.
		echo "WARNING: Failed to send snapshot, but keeping local snapshot: ${NEW_SNAP_PATH}"
		return 1 # Indicate failure
	fi

	echo "--- Finished Btrfs Backup for $SOURCE_SUBVOL ---"
}

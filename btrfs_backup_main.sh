#!/bin/bash
# Main orchestration script for Btrfs Incremental Backups.
# This script calls the backup_subvolume function defined in btrfs_backup.sh
#
# Must be run as root.
#
# Usage:
#   ./btrfs_backup_main.sh [-s]
#
# Arguments:
#   -s: Enables a re-send and verification mode for the latest local snapshots.
#       When this flag is provided, the script does NOT create new snapshots.
#       Instead, for each subvolume, it finds the latest local snapshot and checks
#       if it exists and is complete on the backup destination. If the snapshot
#       is missing or found to be incomplete, it will be (re-)sent. This is
#       useful for retrying failed or interrupted transfers.

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
BACKUP_MOUNT="/run/media/stoflom/BlackArmor"
#BACKUP_MOUNT="/mnt/BlackArmor"
#BACKUP_DEST="$BACKUP_MOUNT/fedora_snapshots"
BACKUP_DEST="$BACKUP_MOUNT/fedora2_snapshots"


SEND_RECEIVE=false


echo "--- btrfs_backup_main script execution Started: $(date) ---"

# --- Source function library ---

# Get the absolute path of the directory where this script is located.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BACKUP_FUNCTION_SCRIPT="${SCRIPT_DIR}/btrfs_backup.sh"
##DEBUG
#echo "Sourcing backup function script from: $BACKUP_FUNCTION_SCRIPT"

if ! source "$BACKUP_FUNCTION_SCRIPT"; then
    echo "ERROR: Failed to source the backup function script at '$BACKUP_FUNCTION_SCRIPT'. Exiting." >&2
    exit 1
fi

# --- Usage function ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [-s] [-h|--help]

Main orchestration script for Btrfs Incremental Backups.
Must be run as root.

Arguments:
  -s: Enables a re-send and verification mode for the latest local snapshots.
      When this flag is provided, the script does NOT create new snapshots.
      Instead, for each subvolume, it finds the latest local snapshot and checks
      if it exists and is complete on the backup destination. If the snapshot
      is missing or found to be incomplete, it will be (re-)sent. This is
      useful for retrying failed or interrupted transfers.
  -h, --help: Display this help message and exit.
EOF
}

# --- Argument Parsing ---
while getopts ":sh-:" opt; do
  case "$opt" in
    s)
      SEND_RECEIVE=true
      echo "Re-send/Receive mode enabled."
      ;;
    h)
      usage
      exit 0
      ;;
    -)
      [ "${OPTARG}" = "help" ] && { usage; exit 0; }
      echo "Invalid option: --${OPTARG}" >&2
      usage >&2
      exit 1
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
  esac
done

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


	# If the last snapshot doesn't exist on disk, clear the variable to force a full backup.
	if [ -n "$LAST_SNAP_PATH" ] && [ ! -d "$LAST_SNAP_PATH" ]; then
		echo "WARNING: Last snapshot '$LAST_SNAP_PATH' not found. Forcing a full backup."
		LAST_SNAP_PATH=""
	fi

	if $SEND_RECEIVE; then
		echo "Re-send mode: attempting to send latest existing snapshot."
		if [ -z "$LAST_SNAP_PATH" ]; then
			echo "INFO: No local snapshots found for $SOURCE_SUBVOL to re-send. Skipping."
			continue
		fi

		# The latest snapshot is the one we want to re-send.
		SNAPSHOT_TO_SEND="$LAST_SNAP_PATH"
		SNAPSHOT_TO_SEND_NAME=$(basename "$SNAPSHOT_TO_SEND")
		DEST_SNAP_PATH="$BACKUP_DEST/$SNAPSHOT_TO_SEND_NAME"

		# --- Check for completeness of the destination snapshot ---
		NEEDS_RESEND=false
		if [ -d "$DEST_SNAP_PATH" ]; then
			echo "INFO: Snapshot '$DEST_SNAP_PATH' exists on backup. Checking for completeness."
			# A successfully received snapshot is read-only and has a Received UUID.
			SUBVOL_INFO=$(btrfs subvolume show "$DEST_SNAP_PATH")
			IS_READONLY=$(echo "$SUBVOL_INFO" | grep -c 'Flags:.*readonly')
			# Check for a Received UUID that is not '-' (which indicates none).
			HAS_RECEIVED_UUID=$(echo "$SUBVOL_INFO" | grep -c -E 'Received UUID:.*[a-f0-9]{8}-')

			if [ "$IS_READONLY" -eq 1 ] && [ "$HAS_RECEIVED_UUID" -eq 1 ]; then
				echo "INFO: Snapshot '$DEST_SNAP_PATH' appears complete. Skipping."
			else
				echo "WARNING: Snapshot '$DEST_SNAP_PATH' is incomplete. Deleting to re-send."
				if ! btrfs subvolume delete "$DEST_SNAP_PATH"; then
					echo "ERROR: Failed to delete incomplete snapshot '$DEST_SNAP_PATH'. Please remove it manually. Skipping."
					continue # Skip to the next subvolume in the main loop
				fi
				NEEDS_RESEND=true
			fi
		else
			# Destination does not exist, so it needs to be sent.
			NEEDS_RESEND=true
		fi

		if [ "$NEEDS_RESEND" = true ]; then
			# Find the parent of the snapshot we are trying to send.
			PARENT_OF_SNAPSHOT_TO_SEND=$(find "$SNAP_DIR" -maxdepth 1 -type d -name "${SNAP_NAME}_*" | sort | grep -B 1 "$SNAPSHOT_TO_SEND" | head -n 1)
			
			# Ensure the found parent is not the same as the snapshot itself (which happens if it's the only one).
			if [ "$PARENT_OF_SNAPSHOT_TO_SEND" = "$SNAPSHOT_TO_SEND" ]; then
				PARENT_OF_SNAPSHOT_TO_SEND=""
			fi
			
			# Call the send function with the existing snapshot and its parent
			send_snapshot "$SNAPSHOT_TO_SEND" "$BACKUP_DEST" "$PARENT_OF_SNAPSHOT_TO_SEND"
		fi
	else
		# --- Normal backup mode: take snapshot, then send it ---
		NEW_SNAP_NAME="${SNAP_NAME}_$(date +%Y%m%d%H%M%S)"
		NEW_SNAP_PATH="${SNAP_DIR}/${NEW_SNAP_NAME}"
		
		# 1. Take the new snapshot
		if take_snapshot "$SOURCE_SUBVOL" "$NEW_SNAP_PATH"; then
			# 2. Send the newly created snapshot
			# The parent for the send is the one we found earlier ($LAST_SNAP_PATH)
			send_snapshot "$NEW_SNAP_PATH" "$BACKUP_DEST" "$LAST_SNAP_PATH"
		fi
	fi	

done

echo "--- Script Execution Complete: $(date) ---"

exit 0

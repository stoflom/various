#!/bin/bash
# Btrfs Incremental Backup Script for Root and Home Subvolumes
#
# Must be run as root.

# --- Configuration ---
# Source Subvolumes
ROOT_SUBVOL="/"
HOME_SUBVOL="/home"

# Source Snapshot Directories
ROOT_SNAP_DIR="/snapshots"
HOME_SNAP_DIR="/home/snapshots"

# Backup Destination Mount Point and Subvolume
BACKUP_MOUNT="/run/media/stoflom/BlackArmor"
BACKUP_DEST="$BACKUP_MOUNT/fedora_snapshots"

# History File (stores the last successfully sent snapshot full paths)
HISTORY_FILE="/.btrfs_last_snapshot"

# --- Functions ---

# Function to perform the snapshot and send/receive operation
backup_subvolume() {
    local SOURCE_SUBVOL=$1
    local SNAP_DIR=$2
    local PREFIX=$3
    local SNAP_TYPE=$4 # root or home

    echo "--- Starting Btrfs Backup for $SOURCE_SUBVOL ---"

    # 1. Generate new snapshot name
    NEW_SNAP_NAME="${PREFIX}_$(date +%Y%m%d%H%M%S)"
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
        grep -v "^${SNAP_TYPE}:" "$HISTORY_FILE" > "$TEMP_HISTORY"
        # Append the new successful snapshot path
        echo "${SNAP_TYPE}:${NEW_SNAP_PATH}" >> "$TEMP_HISTORY"
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

# --- Main Execution ---

# Check if history file exists, if not create it with empty lines
if [ ! -f "$HISTORY_FILE" ]; then
    touch "$HISTORY_FILE"
    echo "Created history file: $HISTORY_FILE"
fi

# Check if the backup destination is mounted and exists
if [ ! -d "$BACKUP_DEST" ]; then
    echo "ERROR: Backup destination $BACKUP_DEST does not exist or is not mounted. Exiting."
    exit 1
fi

# 1. Backup the Root (/) subvolume
backup_subvolume "$ROOT_SUBVOL" "$ROOT_SNAP_DIR" "root" "root"

# Add a separator between operations
echo -e "\n======================================================\n"

# 2. Backup the Home (/home) subvolume
backup_subvolume "$HOME_SUBVOL" "$HOME_SNAP_DIR" "home" "home"

echo -e "\n--- Script Execution Complete ---"

exit 0



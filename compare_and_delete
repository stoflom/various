#!/bin/bash

# Check if both directories were provided as arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <DirectoryA> <DirectoryB>"
    echo "  DirectoryA: The reference directory (files here are KEPT)."
    echo "  DirectoryB: The target directory (files here are DELETED if content matches a file in A)."
    exit 1
fi

# Assign arguments to variables
DIR_A="$1"
DIR_B="$2"

# --- Script Logic ---

# Check if directories exist and are actually directories
if [[ ! -d "$DIR_A" ]]; then
    echo "Error: Directory A not found or is not a directory: $DIR_A"
    exit 1
fi

if [[ ! -d "$DIR_B" ]]; then
    echo "Error: Directory B not found or is not a directory: $DIR_B"
    exit 1
fi

echo "Starting comparison and deletion..."
echo "Reference (A): '$DIR_A'"
echo "Target (B): '$DIR_B'"

# Find all regular files in DIR_B
# -print0 and read -d $'\0' are used for safe handling of filenames with spaces or special characters
find "$DIR_B" -type f -print0 | while IFS= read -r -d $'\0' file_b; do
    
    # 1. Get the checksum (SHA-256) of the file in DIR_B
    checksum_b=$(sha256sum "$file_b" 2>/dev/null | awk '{print $1}')
    
    # Skip if checksum fails (e.g., file permissions changed mid-script)
    if [ -z "$checksum_b" ]; then
        echo "Warning: Could not get checksum for $file_b. Skipping."
        continue
    fi
    
    # 2. Search for a file in DIR_A with the same checksum
    # This uses find to generate checksums in DIR_A and awk to check for a match.
    # The '2>/dev/null' suppresses errors (like permission denied) from sha256sum.
    if find "$DIR_A" -type f -exec sha256sum {} + 2>/dev/null | awk -v cb="$checksum_b" 'BEGIN {found=0} $1 == cb {found=1; exit} END {exit !found}'; then
        
        # 3. If a match is found (awk/find returns exit code 0)
        echo "Match found for: $file_b (Checksum: $checksum_b)"
        
        # 4. Delete the file from DIR_B
        if rm "$file_b"; then
            echo "-> DELETED $file_b"
        else
            echo "-> Error deleting $file_b"
        fi
        
    fi

done

echo "Comparison and deletion complete."

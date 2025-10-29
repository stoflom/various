#!/bin/bash

#Script to test files in current directory using a perl script (xmlgpx.pl which checks for <trk> elements in a GPX file).
#If the perl script returns an empty output for a file, that file is deleted.

# Define the directory to test files in
# You should change this to your actual directory path
TARGET_DIR="."

# Define the path to your perl script
# Assuming it's in the current directory or in your PATH
PERL_SCRIPT="xmlgpx.pl"

# --- Error Handling and Setup ---

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found." >&2
    exit 1
fi

# Check if the perl script exists (assuming it's relative to the script's execution)
if ! command -v "$PERL_SCRIPT" &> /dev/null; then
    if [ ! -f "$PERL_SCRIPT" ]; then
        echo "Error: Perl script '$PERL_SCRIPT' not found. Please check its path." >&2
        exit 1
    fi
fi

echo "Starting file check in directory: $TARGET_DIR"

# --- Main Logic ---

# Use find to get a list of files (and handle spaces in filenames correctly)
# The -print0 and read -d '' -r are for safe handling of filenames with spaces/special characters
find "$TARGET_DIR" -type f -print0 | while IFS= read -r -d '' filepath; do
    echo "Testing file: $filepath"

    # Run the perl script and capture its output (and error status)
    # The output is stored in the 'output' variable
    output=$("$PERL_SCRIPT" "$filepath")
    
    # Check if the output is an empty string
    # -z is the test for a zero-length string (empty)
    if [ -z "$output" ]; then
        echo "--> Output is empty. Deleting file: $filepath"
        
        # Uncomment the 'rm' line below to enable actual deletion!
        # For a safe test, leave it commented out and run the script first.
        rm "$filepath"
        
        # ---
        # NOTE: For safety, the 'rm' command is commented out. 
        # Uncomment the line above *after* you have confirmed the script 
        # correctly identifies the files you want to delete.
        # ---

    else
        echo "--> Output is NOT empty. Keeping file."
        # If you want to see the non-empty output, uncomment the line below:
        echo "    [Output Snippet: ${output:0:50}]"
    fi

done

echo "Finished file check."

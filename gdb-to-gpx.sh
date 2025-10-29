#!/bin/bash

# Script to convert all .gdb files in the current directory to .gpx format using gpsbabel.

# Check if gpsbabel is installed
if ! command -v gpsbabel &> /dev/null
then
    echo "Error: gpsbabel is not found. Please install it to run this script."
    exit 1
fi

echo "Starting conversion of .gdb files to .gpx..."
echo "---------------------------------------------"

# Loop through all files in the current directory that end with .gdb
for gdb_file in *.gdb
do
    # Check if any .gdb files were found (to handle the case where no files match)
    if [ -e "$gdb_file" ]; then
        # Create the output filename by replacing the .gdb extension with .gpx
        output_file="${gdb_file%.gdb}.gpx"

        echo "Converting '$gdb_file' to '$output_file'..."

        # Run gpsbabel conversion
        # -i gdb: specifies the input format is Garmin GDB
        # -f "$gdb_file": specifies the input file
        # -o gpx: specifies the output format is GPX XML
        # -F "$output_file": specifies the output file
        if gpsbabel -i gdb -f "$gdb_file" -o gpx -F "$output_file"; then
            echo "✅ Success: '$output_file' created."
        else
            echo "❌ Error: Failed to convert '$gdb_file'."
        fi
    else
        echo "⚠️ Warning: No .gdb files found in the current directory."
        break # Exit the loop if no files were found initially
    fi
done

echo "---------------------------------------------"
echo "Conversion complete."

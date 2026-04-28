#!/bin/bash

# Fetch the latest version from GitHub API and parse it from the URL
RELEASE_INFO=$(curl -s https://api.github.com/repos/sinelaw/fresh/releases/latest)
ASSET_URL=$(echo "$RELEASE_INFO" | grep "browser_download_url.*\.$(uname -m)\.rpm" | cut -d '"' -f 4)

# Extract version from the URL (e.g., /v0.1.83/fresh-editor-0.1.83-)
VERSION=$(echo "$ASSET_URL" | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')

if [ -z "$VERSION" ]; then
	echo "Error: Could not parse version from release URL"
	exit 1
fi

URL="$ASSET_URL"

# Display what we're going to do
echo "Upgrading fresh-editor to version $VERSION via rpm..."
echo "URL: $URL"

# Install the package
sudo dnf install "$URL"

# Check if installation was successful
if [ $? -eq 0 ]; then
	echo "Successfully installed fresh-editor version $VERSION"
else
	echo "Failed to install fresh-editor version $VERSION"
	exit 1
fi

#!/bin/bash

# Update gemini-cli to the latest version globally
echo "Updating Gemini CLI..."
sudo npm install -g @google/gemini-cli@latest

if [ $? -eq 0 ]; then
    echo "Successfully updated Gemini CLI to the latest version."
    gemini --version
else
    echo "Failed to update Gemini CLI. Please check your npm permissions."
    exit 1
fi

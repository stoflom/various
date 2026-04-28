#!/bin/bash

# Update pi coding agent to the latest version globally
echo "Updating Pi..."
sudo npm install -g @mariozechner/pi-coding-agent@latest

if [ $? -eq 0 ]; then
    echo "Successfully updated Pi coding agent to the latest version."
    pi --version
else
    echo "Failed to update Pi. Please check your npm permissions."
    exit 1
fi

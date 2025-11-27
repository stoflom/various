# Makefile for bashrc utilities

SHELL := /bin/bash

# --- Configuration ---
# Directory for shell functions to be sourced on login.
# Fedora automatically sources all files in this directory.
BASHRC_D_DIR := $(HOME)/.bashrc.d

# Directory for standalone executable scripts.
# Ensure this directory is in your $PATH.
BIN_DIR := $(HOME)/.local/bin

# Standalone executable scripts.
EXEC_SCRIPTS := compare_and_delete \
extags \
gdb-to-gpx \
gpsinfo \
gpstags \
ffile-copy \
btrfs_backup.sh \
btrfs_backup_main.sh \
combine_img_tags.sh	 \
#test_and_clean \
#test_sort_hash_and_clean \
#xmlgpx.pl \


# --- Targets ---

.DEFAULT_GOAL := install
.PHONY: install uninstall list all

# Default target: install everything.
all: install

install:
	@echo "Installing executable scripts to $(BIN_DIR)..."
	@mkdir -p $(BIN_DIR)
	@# Install executable scripts with execute permissions (755).
	install -m 755 $(EXEC_SCRIPTS) $(BIN_DIR)
	
	@echo "✅ Installation complete."
	@echo "-> Executable scripts are now in $(BIN_DIR)."

uninstall:
	@echo "Uninstalling scripts..."
	-rm -f $(addprefix $(BIN_DIR)/, $(notdir $(EXEC_SCRIPTS)))
	@echo "✅ Uninstallation complete."

list:
	@echo "Executable scripts to be installed in $(BIN_DIR):"
	@echo "  $(EXEC_SCRIPTS)"

#!/bin/bash

echo "Configuring SSH access ..."

CONFIG_FILE="$HOME/.ssh/config"
GENERATED_CONFIG="ssh_config_per_connect.txt"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

echo "" >> "$CONFIG_FILE"
echo "# --- Lab Terraform Pt1.6 $(date) ---" >> "$CONFIG_FILE"
cat "$GENERATED_CONFIG" >> "$CONFIG_FILE"
echo "Configuration compleated!"

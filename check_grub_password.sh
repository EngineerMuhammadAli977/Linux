#!/bin/bash
# ---------------------------------------------------------
# Script Name: check_grub_password.sh
# Purpose: Check if GRUB password is configured on Ubuntu
# Author: MicroTech DevOps Engineer M.Ali
# ---------------------------------------------------------

echo "----------------------------------------"
echo "🔍 Checking GRUB password configuration..."
echo "----------------------------------------"

# Paths to check
GRUB_CFG="/boot/grub/grub.cfg"
GRUB_CUSTOM="/etc/grub.d/40_custom"

# Check if main grub.cfg exists
if [ ! -f "$GRUB_CFG" ]; then
    echo "❌ GRUB configuration file not found at $GRUB_CFG"
    exit 1
fi

# Search for password entries in grub configs
PASSWORD_LINES=$(grep -i "password" "$GRUB_CFG" 2>/dev/null)
CUSTOM_PASSWORD_LINES=$(grep -i "password" "$GRUB_CUSTOM" 2>/dev/null)

if [[ -n "$PASSWORD_LINES" || -n "$CUSTOM_PASSWORD_LINES" ]]; then
    echo "✅ GRUB password IS configured."
    echo
    echo "🔎 Details found:"
    echo "----------------------------------------"
    echo "$PASSWORD_LINES"
    echo "$CUSTOM_PASSWORD_LINES"
    echo "----------------------------------------"
else
    echo "⚠️  GRUB password is NOT configured!"
    echo "👉 To secure it, use:"
    echo "    sudo grub-mkpasswd-pbkdf2"
    echo "    sudo nano /etc/grub.d/40_custom"
    echo "    sudo update-grub"
fi

echo
echo "Check complete ✅"

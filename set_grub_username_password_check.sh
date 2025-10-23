#!/bin/bash
# -------------------------------------------------------------------
# Author: Muhammad Ali - DevOps Engineer at MicroTech
# Description:
#   This script checks if a GRUB username/password is configured.
#   If missing, it prompts user to securely enter username & password,
#   generates a PBKDF2 hash, updates GRUB config,
#   and logs all actions with timestamps for audit purposes.
# -------------------------------------------------------------------

# ==== CONFIGURATION ====
LOG_FILE="/var/log/grub_password_setup.log"
CUSTOM_CFG="/etc/grub.d/40_custom"
GRUB_CFG="/boot/grub/grub.cfg"
BACKUP_DIR="/etc/grub.d/backups"

# ==== FUNCTIONS ====
log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# ==== START ====
clear
echo "------------------------------------------------------------"
echo "🔧 GRUB Username & Password Setup Script - by Muhammad Ali (DevOps Engineer at MicroTech)"
echo "------------------------------------------------------------"
echo

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

log "------------------------------------------------------------"
log "Script execution started by user: $(whoami)"
log "Hostname: $(hostname)"
log "------------------------------------------------------------"

# ==== STEP 1: CHECK EXISTING PASSWORD ====
log "Checking if GRUB password is already set..."
if grep -q "grub.pbkdf2" "$GRUB_CFG"; then
    log "✅ GRUB password already configured. No action required."
    echo "✅ GRUB password already set. Exiting safely."
    log "------------------------------------------------------------"
    exit 0
else
    log "⚠️  No GRUB username/password detected. Proceeding with setup."
fi

# ==== STEP 2: ASK FOR USERNAME ====
echo
read -p "Enter GRUB username (example: admin): " grub_user

if [ -z "$grub_user" ]; then
    log "❌ No username entered. Aborting setup."
    echo "❌ Username cannot be empty. Exiting."
    exit 1
fi
log "👤 Username set as: $grub_user"

# ==== STEP 3: PROMPT USER FOR PASSWORD ====
echo
read -s -p "Enter GRUB password for user '$grub_user': " grub_password
echo
read -s -p "Confirm GRUB password: " grub_password_confirm
echo

if [ "$grub_password" != "$grub_password_confirm" ]; then
    log "❌ Password confirmation failed. Aborting."
    echo "❌ Passwords do not match. Exiting."
    exit 1
fi

# ==== STEP 4: GENERATE HASH ====
log "Generating GRUB password hash..."
hashed_password=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 | awk '/PBKDF2 hash of your password is/{print $NF}')

if [ -z "$hashed_password" ]; then
    log "❌ Failed to generate password hash."
    echo "❌ Error: Could not generate password hash. Check log for details."
    exit 1
fi

log "✅ Password hash generated successfully."

# ==== STEP 5: BACKUP CONFIG ====
BACKUP_FILE="$BACKUP_DIR/40_custom_$(date +%F_%H-%M-%S).bak"
cp "$CUSTOM_CFG" "$BACKUP_FILE" 2>/dev/null
log "📦 Backup created at $BACKUP_FILE"

# ==== STEP 6: UPDATE GRUB CONFIG ====
cat <<EOF >> "$CUSTOM_CFG"

# Added by Muhammad Ali - DevOps Engineer at MicroTech
set superusers="$grub_user"
password_pbkdf2 $grub_user $hashed_password
EOF

log "🧩 GRUB configuration updated with user '$grub_user' and password hash."

# ==== STEP 7: APPLY CHANGES ====
if update-grub > /dev/null 2>&1; then
    log "⚙️  GRUB configuration successfully rebuilt."
    echo "✅ GRUB username/password configured successfully for user '$grub_user'."
else
    log "❌ Failed to update GRUB configuration."
    echo "❌ Failed to apply GRUB configuration. Check $LOG_FILE for details."
    exit 1
fi

# ==== COMPLETE ====
log "✅ GRUB username/password setup completed successfully by Muhammad Ali - DevOps Engineer at MicroTech"
log "------------------------------------------------------------"
echo
echo "📜 Log file: $LOG_FILE"
echo "🔑 Verify with: grep 'password_pbkdf2' $GRUB_CFG"
echo "------------------------------------------------------------"

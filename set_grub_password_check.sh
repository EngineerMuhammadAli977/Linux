#!/bin/bash
# -------------------------------------------------------------------
# Author: Muhammad Ali - DevOps Engineer at MicroTech
# Description:
#   This script checks if a GRUB password is configured.
#   If missing, it prompts the user to securely enter one,
#   generates a PBKDF2 hash, updates GRUB config,
#   and logs all actions with timestamps for audit purposes.
# -------------------------------------------------------------------

# ==== CONFIGURATION ====
LOG_FILE="/var/log/grub_password_setup.log"
CUSTOM_CFG="/etc/grub.d/40_custom"
GRUB_CFG="/boot/grub/grub.cfg"
BACKUP_DIR="/etc/grub.d/backups"
ADMIN_USER="admin"

# ==== FUNCTIONS ====
log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# ==== START ====
clear
echo "------------------------------------------------------------"
echo "🔧 GRUB Password Setup Script - by Muhammad Ali (DevOps Engineer at MicroTech)"
echo "------------------------------------------------------------"
echo

# Create directories and log file if missing
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
    log "⚠️  No GRUB password detected. Proceeding with setup."
fi

# ==== STEP 2: PROMPT USER FOR PASSWORD ====
echo
read -s -p "Enter new GRUB password: " grub_password
echo
read -s -p "Confirm GRUB password: " grub_password_confirm
echo

if [ "$grub_password" != "$grub_password_confirm" ]; then
    log "❌ Password confirmation failed. Aborting."
    echo "❌ Passwords do not match. Exiting."
    exit 1
fi

# ==== STEP 3: GENERATE HASH ====
log "Generating GRUB password hash..."
hashed_password=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 | awk '/PBKDF2 hash of your password is/{print $NF}')

if [ -z "$hashed_password" ]; then
    log "❌ Failed to generate password hash."
    echo "❌ Error: Could not generate password hash. Check log for details."
    exit 1
fi

log "✅ Password hash generated successfully."

# ==== STEP 4: BACKUP CONFIG ====
BACKUP_FILE="$BACKUP_DIR/40_custom_$(date +%F_%H-%M-%S).bak"
cp "$CUSTOM_CFG" "$BACKUP_FILE" 2>/dev/null
log "📦 Backup created at $BACKUP_FILE"

# ==== STEP 5: UPDATE GRUB CONFIG ====
cat <<EOF >> "$CUSTOM_CFG"

# Added by Muhammad Ali - DevOps Engineer at MicroTech
set superusers="$ADMIN_USER"
password_pbkdf2 $ADMIN_USER $hashed_password
EOF

log "🧩 GRUB configuration updated with admin user and password hash."

# ==== STEP 6: APPLY CHANGES SAFELY ====
if update-grub > /dev/null 2>&1; then
    log "⚙️  GRUB configuration successfully rebuilt."
    echo "✅ GRUB password configured successfully for user '$ADMIN_USER'."
else
    log "❌ Failed to update GRUB configuration."
    echo "❌ Failed to apply GRUB configuration. Check $LOG_FILE for details."
    exit 1
fi

# ==== STEP 7: COMPLETE ====
log "✅ GRUB password setup completed successfully by Muhammad Ali - DevOps Engineer at MicroTech"
log "------------------------------------------------------------"
echo
echo "📜 Log file: $LOG_FILE"
echo "🔑 Verify with: grep 'password_pbkdf2' $GRUB_CFG"
echo "------------------------------------------------------------"

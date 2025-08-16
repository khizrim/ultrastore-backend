#!/bin/bash
# Theme deployment script for production

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if required variables are set
if [ -z "$PRODUCTION_HOST" ] || [ -z "$PRODUCTION_USER" ] || [ -z "$PRODUCTION_THEME_PATH" ]; then
    echo "Error: Production server configuration not found in .env file"
    exit 1
fi

THEME_NAME="ultrastore-headless"
LOCAL_THEME_PATH="./themes/$THEME_NAME"

echo "==================================="
echo "Deploying $THEME_NAME to Production"
echo "==================================="
echo "Server: $PRODUCTION_HOST"
echo "Theme path: $PRODUCTION_THEME_PATH"
echo ""

# Check if local theme exists
if [ ! -d "$LOCAL_THEME_PATH" ]; then
    echo "Error: Theme directory not found at $LOCAL_THEME_PATH"
    exit 1
fi

# Create a temporary archive of the theme
echo "Creating theme archive..."
TEMP_ARCHIVE="/tmp/${THEME_NAME}-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$TEMP_ARCHIVE" -C ./themes "$THEME_NAME"

# Upload the theme to the server
echo "Uploading theme to server..."
scp -P "${PRODUCTION_PORT:-22}" "$TEMP_ARCHIVE" "${PRODUCTION_USER}@${PRODUCTION_HOST}:/tmp/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload theme to server"
    rm -f "$TEMP_ARCHIVE"
    exit 1
fi

# Deploy the theme on the server
echo "Deploying theme on server..."
ssh -p "${PRODUCTION_PORT:-22}" "${PRODUCTION_USER}@${PRODUCTION_HOST}" << EOF
    set -e
    
    # Backup existing theme if it exists
    if [ -d "${PRODUCTION_THEME_PATH}${THEME_NAME}" ]; then
        echo "Backing up existing theme..."
        BACKUP_NAME="${THEME_NAME}-backup-\$(date +%Y%m%d-%H%M%S).tar.gz"
        cd "${PRODUCTION_THEME_PATH}"
        tar -czf "/tmp/\$BACKUP_NAME" "${THEME_NAME}"
        echo "Backup saved to /tmp/\$BACKUP_NAME"
    fi
    
    # Extract new theme
    echo "Extracting new theme..."
    cd "${PRODUCTION_THEME_PATH}"
    tar -xzf "/tmp/$(basename $TEMP_ARCHIVE)"
    
    # Set proper permissions
    echo "Setting permissions..."
    chown -R www-data:www-data "${THEME_NAME}"
    find "${THEME_NAME}" -type d -exec chmod 755 {} \;
    find "${THEME_NAME}" -type f -exec chmod 644 {} \;
    
    # Clean up
    rm -f "/tmp/$(basename $TEMP_ARCHIVE)"
    
    echo "Theme deployed successfully!"
EOF

# Clean up local temp file
rm -f "$TEMP_ARCHIVE"

echo ""
echo "==================================="
echo "Deployment Complete!"
echo "==================================="
echo "Theme $THEME_NAME has been deployed to $PRODUCTION_HOST"
echo "====================================="

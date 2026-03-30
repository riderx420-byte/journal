#!/bin/bash
# Local APK build script for Daily Journal App
# Requires: Node.js, Java JDK, Bubblewrap CLI

set -e

echo "📦 Building Daily Journal APK..."

# Check prerequisites
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required. Install from https://nodejs.org"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java JDK is required. Install JDK 17+"
    exit 1
fi

# Install Bubblewrap if not present
if ! command -v bubblewrap &> /dev/null; then
    echo "📥 Installing Bubblewrap CLI..."
    npm install -g @bubblewrap/cli
fi

# Create keystore if it doesn't exist
if [ ! -f "keystore.jks" ]; then
    echo "🔐 Generating new keystore..."
    keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias journal-key \
        -storepass android -keypass android \
        -dname "CN=Journal App, OU=Development, O=Daily Journal, L=Unknown, ST=Unknown, C=US"
    echo "⚠️  Keystore created with password: android"
    echo "⚠️  Store this safely! You'll need it for future updates."
fi

# Get the URL where the app will be hosted
echo ""
echo "Enter your GitHub Pages URL (e.g., https://username.github.io/journal):"
read -p "> " APP_URL

if [ -z "$APP_URL" ]; then
    echo "❌ URL is required"
    exit 1
fi

# Remove trailing slash
APP_URL="${APP_URL%/}"

# Initialize Bubblewrap project
echo "🔧 Initializing TWA project..."
if [ ! -d "twa" ]; then
    bubblewrap init --manifest ${APP_URL}/manifest.json --directory twa --skipValidation
fi

# Update bubblewrap config with correct URLs
cd twa
cat > bubblewrap-config.json << EOF
{
    "appVersionName": "1.0.0",
    "appVersionCode": 1,
    "applicationId": "com.dailyjournal.app",
    "appName": "Daily Journal",
    "display": "standalone",
    "fallbackType": "customtabs",
    "enableNotifications": true,
    "startUrl": "${APP_URL}/",
    "iconUrl": "${APP_URL}/icons/icon-512.svg",
    "splashScreenFadeOutDuration": 300,
    "enableSiteSettingsShortcut": true,
    "shortcuts": [],
    "generatorApp": "bubblewrap-cli",
    "webManifestUrl": "${APP_URL}/manifest.json",
    "features": {},
    "alphaDependencies": {
        "enabled": false
    },
    "appBuild": 1,
    "retainedBundles": [],
    "signing": {
        "keyStoreUrl": "file:///$(pwd)/../keystore.jks",
        "keyStorePassword": "android",
        "keyPassword": "android"
    },
    "additionalTrustedOrigins": []
}
EOF

# Build the APK
echo "🏗️  Building APK..."
bubblewrap build --skipValidation

# Copy APK to project root
if [ -f "app-release-signed.apk" ]; then
    cp app-release-signed.apk ../daily-journal.apk
    echo ""
    echo "✅ Build complete!"
    echo "📱 APK saved as: daily-journal.apk"
    echo ""
    echo "To install on Android:"
    echo "  adb install daily-journal.apk"
    echo ""
    echo "Or transfer the APK to your device and install manually."
else
    echo "❌ Build failed - APK not found"
    exit 1
fi

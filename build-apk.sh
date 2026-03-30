#!/bin/bash
# Simple APK builder for Daily Journal
# Uses pwabuilder or manual WebView approach

set -e

echo "📦 Building Daily Journal APK..."

APP_NAME="Daily Journal"
PACKAGE_NAME="com.dailyjournal.app"
VERSION="1.0.0"

# Get GitHub Pages URL or use default
if [ -n "$GITHUB_REPOSITORY_OWNER" ]; then
    WEB_URL="https://${GITHUB_REPOSITORY_OWNER}.github.io/${GITHUB_REPOSITORY##*/}/"
else
    WEB_URL="https://riderx420-byte.github.io/journal/"
fi

echo "📱 Web URL: ${WEB_URL}"

# Try pwabuilder first
if command -v pwabuilder &> /dev/null; then
    echo "🔨 Building with pwabuilder..."
    mkdir -p apk-output
    pwabuilder build "${WEB_URL}" \
        --platform android \
        --output ./apk-output \
        --packageId "${PACKAGE_NAME}" \
        --appName "${APP_NAME}" \
        --appVersion "${VERSION}" \
        --signingKey keystore.jks \
        --storePassword android \
        --keyPassword android \
        --alias journal-key 2>&1 || {
        echo "pwabuilder failed, trying manual build..."
    }
    
    if [ -f "apk-output/android/app-release.apk" ]; then
        cp apk-output/android/app-release.apk daily-journal.apk
        echo "✅ APK built: daily-journal.apk"
        exit 0
    fi
fi

# Fallback: Create simple WebView APK project
echo "🔧 Building manual WebView APK..."

mkdir -p android-project/app/src/main/java/com/dailyjournal/app
mkdir -p android-project/app/src/main/res/values
mkdir -p android-project/app/src/main/res/xml
mkdir -p android-project/app/src/main/res/mipmap-anydpi-v26
mkdir -p android-project/app/src/main/res/drawable
mkdir -p android-project/gradle/wrapper

# Create minimal gradle files
cat > android-project/settings.gradle << 'EOF'
rootProject.name = 'DailyJournal'
include ':app'
EOF

cat > android-project/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
EOF

cat > android-project/build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2'
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

cat > android-project/app/build.gradle << 'GRADLE_EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.dailyjournal.app'
    compileSdk 33

    defaultConfig {
        applicationId "com.dailyjournal.app"
        minSdk 24
        targetSdk 33
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
GRADLE_EOF

# AndroidManifest
cat > android-project/app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:allowBackup="true"
        android:label="Daily Journal"
        android:icon="@mipmap/ic_launcher"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# MainActivity
cat > android-project/app/src/main/java/com/dailyjournal/app/MainActivity.java << JAVAEOF
package com.dailyjournal.app;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebSettings;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebView webView = new WebView(this);
        setContentView(webView);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        webView.loadUrl("${WEB_URL}");
    }
    
    @Override
    public void onBackPressed() {
        WebView webView = (WebView) findViewById(android.R.id.content);
        if (webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }
}
JAVAEOF

# Resources
cat > android-project/app/src/main/res/values/strings.xml << 'EOF'
<string name="app_name">Daily Journal</string>
EOF

cat > android-project/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml << 'EOF'
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_bg"/>
    <foreground android:drawable="@drawable/ic_fg"/>
</adaptive-icon>
EOF

cat > android-project/app/src/main/res/values/colors.xml << 'EOF'
<color name="ic_bg">#0f0f1a</color>
EOF

cat > android-project/app/src/main/res/drawable/ic_fg.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#e94560"
        android:pathData="M54,30c-8,0-14,6-14,14v24c0,8 6,14 14,14s14,-6 14,-14V44c0,-8-6,-14-14,-14z"/>
</vector>
EOF

cat > android-project/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-bin.zip
EOF

echo ""
echo "⚠️  Full Android build requires Android Studio or command-line tools."
echo ""
echo "For a quick APK, use GitHub Actions (push to main) or:"
echo "  1. Open android-project/ in Android Studio"
echo "  2. Build > Build Bundle(s) / APK(s) > Build APK(s)"
echo ""
echo "Or download from GitHub Actions artifacts after push."

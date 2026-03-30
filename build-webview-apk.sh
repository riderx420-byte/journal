#!/bin/bash
# Fallback APK builder using Gradle and WebView
# Used when Bubblewrap fails in CI

set -e

echo "📦 Building APK with Gradle..."

APP_NAME="Daily Journal"
PACKAGE_NAME="com.dailyjournal.app"
GITHUB_OWNER="${GITHUB_REPOSITORY_OWNER:-riderx420-byte}"
REPO_NAME="${GITHUB_REPOSITORY##*/}"
WEB_URL="https://${GITHUB_OWNER}.github.io/${REPO_NAME}/"

# Create Android project structure
mkdir -p android-app/app/src/main/java/com/dailyjournal/app
mkdir -p android-app/app/src/main/res/values
mkdir -p android-app/app/src/main/res/xml
mkdir -p android-app/app/src/main/res/mipmap-anydpi-v26
mkdir -p android-app/app/src/main/res/drawable
mkdir -p android-app/gradle/wrapper

# Create build.gradle (project level)
cat > android-app/build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# Create settings.gradle
cat > android-app/settings.gradle << 'EOF'
rootProject.name = 'DailyJournal'
include ':app'
EOF

# Create gradle.properties
cat > android-app/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
EOF

# Create app/build.gradle
cat > android-app/app/build.gradle << 'GRADLE_EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.dailyjournal.app'
    compileSdk 34

    defaultConfig {
        applicationId "com.dailyjournal.app"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.webkit:webkit:1.9.0'
}
GRADLE_EOF

# Create proguard-rules.pro
cat > android-app/app/proguard-rules.pro << 'EOF'
-keepattributes *Annotation*
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
EOF

# Create AndroidManifest.xml
cat > android-app/app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.DailyJournal"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.DailyJournal"
            android:configChanges="orientation|screenSize|keyboardHidden"
            android:launchMode="singleTask">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# Create MainActivity.java with the actual GitHub Pages URL
cat > android-app/app/src/main/java/com/dailyjournal/app/MainActivity.java << JAVAEOF
package com.dailyjournal.app;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        webView = new WebView(this);
        setContentView(webView);
        
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setDatabaseEnabled(true);
        webSettings.setGeolocationEnabled(true);
        webSettings.setAllowFileAccess(true);
        
        webView.setWebViewClient(new WebViewClient());
        webView.loadUrl("${WEB_URL}");
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
JAVAEOF

# Create strings.xml
cat > android-app/app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Daily Journal</string>
</resources>
EOF

# Create themes.xml
cat > android-app/app/src/main/res/values/themes.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.DailyJournal" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:colorPrimary">#1a1a2e</item>
        <item name="android:colorPrimaryDark">#0f0f1a</item>
        <item name="android:colorAccent">#e94560</item>
        <item name="android:windowBackground">#0f0f1a</item>
    </style>
</resources>
EOF

# Create network_security_config.xml
cat > android-app/app/src/main/res/xml/network_security_config.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
EOF

# Create launcher icon
cat > android-app/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_background"/>
    <foreground android:drawable="@drawable/ic_foreground"/>
</adaptive-icon>
EOF

# Create colors.xml
cat > android-app/app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_background">#0f0f1a</color>
    <color name="ic_foreground">#e94560</color>
</resources>
EOF

# Create foreground drawable
cat > android-app/app/src/main/res/drawable/ic_foreground.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#e94560"
        android:pathData="M54,30c-8,0 -14,6 -14,14v24c0,8 6,14 14,14s14,-6 14,-14V44c0,-8 -6,-14 -14,-14zM46,44c0,-4.4 3.6,-8 8,-8s8,3.6 8,8v24c0,4.4 -3.6,8 -8,8s-8,-3.6 -8,-8V44z"/>
</vector>
EOF

# Create gradle wrapper properties
cat > android-app/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# Create local.properties with Android SDK path
echo "sdk.dir=/opt/android-sdk" > android-app/local.properties

cd android-app

# Download and setup Gradle wrapper if not present
if [ ! -f "gradlew" ]; then
    echo "Setting up Gradle wrapper..."
    gradle wrapper --gradle-version 8.2 || true
fi

# Build the APK
echo "Building release APK..."
./gradlew assembleRelease --no-daemon --stacktrace 2>&1 || {
    echo "Gradle build failed, trying with system gradle..."
    gradle assembleRelease --no-daemon --stacktrace 2>&1
}

# Find and copy the APK
if [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
    cp app/build/outputs/apk/release/app-release.apk ../daily-journal.apk
    echo "✅ APK built successfully: daily-journal.apk"
elif [ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
    cp app/build/outputs/apk/release/app-release-unsigned.apk ../daily-journal.apk
    echo "✅ APK built (unsigned): daily-journal.apk"
else
    echo "❌ APK not found in expected location"
    find . -name "*.apk" 2>/dev/null || true
    exit 1
fi

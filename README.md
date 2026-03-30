# Daily Journal App

A beautiful daily journaling PWA with reminders and streak tracking.

## Features

- ✨ Beautiful dark theme UI
- 📔 Daily journal entries with localStorage persistence
- 🔔 9 PM notification reminders
- 📊 Stats: total entries, streak count, word count
- 📤 Export entries to CSV
- 📱 PWA - install on your phone
- 📦 APK available via GitHub Actions

## Quick Start

### Run Locally

```bash
# Using Python
python3 -m http.server 8080

# Or using Node.js
npx serve .

# Then open http://localhost:8080
```

### Deploy to GitHub Pages

1. Push to GitHub
2. GitHub Actions will auto-deploy to GitHub Pages
3. Access at `https://yourusername.github.io/journal/`

### Build APK

The GitHub Actions workflow automatically builds an APK on every push to main/master.

**To download the APK:**
1. Go to your repo's **Actions** tab
2. Click on the latest "Build and Deploy" run
3. Scroll to "Artifacts" section
4. Download `journal-app-apk.zip`
5. Install on your Android device

## Local APK Build (Advanced)

If you want to build the APK locally:

```bash
# Install Bubblewrap
npm install -g @bubblewrap/cli

# Generate a keystore (one time)
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias journal-key

# Initialize TWA project
bubblewrap init --manifest https://your-url.com/manifest.json

# Build
cd twa
bubblewrap build
```

## GitHub Actions Setup

The workflow (`.github/workflows/build.yml`) does:
1. Deploys to GitHub Pages
2. Builds Android APK using Bubblewrap (TWA - Trusted Web Activity)
3. Uploads APK as artifact

## Tech Stack

- Pure HTML/CSS/JavaScript (no framework)
- PWA with Service Worker
- LocalStorage for data persistence
- Web Notifications API

## License

MIT

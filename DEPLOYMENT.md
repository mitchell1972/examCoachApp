# 🚀 Deployment Guide for Exam Coach Flutter App

This guide provides multiple options to deploy your secure Flutter Exam Coach app to central locations where you can view and share it.

## 📋 Prerequisites

- Flutter SDK installed (3.13.0 or later)
- Git repository hosting (GitHub, GitLab, etc.)
- Web browser for testing

## 🌐 Deployment Options

### Option 1: GitHub Pages (Recommended - Free & Easy)

**Step 1: Create GitHub Repository**
```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit: Secure Flutter Exam Coach App"

# Create repository on GitHub and push
git remote add origin https://github.com/YOUR_USERNAME/examCoachApp.git
git branch -M main
git push -u origin main
```

**Step 2: Enable GitHub Pages**
1. Go to your repository on GitHub
2. Navigate to Settings → Pages
3. Source: Deploy from a branch
4. Branch: Select `gh-pages` (will be created automatically)
5. Folder: `/ (root)`

**Step 3: Automatic Deployment**
The GitHub Actions workflow (`.github/workflows/deploy.yml`) will automatically:
- Build the Flutter web app
- Deploy to GitHub Pages
- Your app will be available at: `https://YOUR_USERNAME.github.io/examCoachApp/`

### Option 2: Netlify (Free with Custom Domain Support)

**Step 1: Prepare Build Script**
```bash
# Create netlify.toml configuration
cat > netlify.toml << EOF
[build]
  command = "flutter build web --release --web-renderer canvaskit"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.16.0"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOF
```

**Step 2: Deploy to Netlify**
1. Visit [netlify.com](https://netlify.com)
2. Connect your GitHub repository
3. Build settings will be auto-detected
4. Deploy site
5. Your app will be available at: `https://YOUR_SITE_NAME.netlify.app`

### Option 3: Vercel (Free with Edge Network)

**Step 1: Create Vercel Configuration**
```bash
# Create vercel.json
cat > vercel.json << EOF
{
  "buildCommand": "flutter build web --release --web-renderer canvaskit",
  "outputDirectory": "build/web",
  "framework": null,
  "installCommand": "curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz | tar -xJ && export PATH=\"$PWD/flutter/bin:$PATH\" && flutter config --enable-web && flutter pub get"
}
EOF
```

**Step 2: Deploy to Vercel**
1. Visit [vercel.com](https://vercel.com)
2. Import your GitHub repository
3. Deploy automatically
4. Your app will be available at: `https://YOUR_PROJECT.vercel.app`

### Option 4: Firebase Hosting (Google's Platform)

**Step 1: Install Firebase CLI**
```bash
npm install -g firebase-tools
firebase login
```

**Step 2: Initialize Firebase**
```bash
firebase init hosting
# Select your project or create new
# Public directory: build/web
# Single-page app: Yes
# Automatic builds with GitHub: Optional
```

**Step 3: Deploy**
```bash
flutter build web --release --web-renderer canvaskit
firebase deploy
```

## 🛠️ Local Development & Testing

### Build and Test Locally
```bash
# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Run in development
flutter run -d chrome

# Build for production
flutter build web --release --web-renderer canvaskit

# Serve locally to test
cd build/web
python -m http.server 8080
# Visit: http://localhost:8080
```

### Run Gherkin Tests
```bash
# Run BDD tests
flutter drive --target=test_driver/app.dart
flutter drive --target=test_driver/app_test.dart
```

## 🔧 Build Configurations

### Performance Optimized Build
```bash
flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --source-maps
```

### PWA (Progressive Web App) Build
```bash
flutter build web \
  --release \
  --web-renderer canvaskit \
  --pwa-strategy offline-first
```

## 📱 Features Available in Web Deployment

✅ **Working Features:**
- Complete UI/UX with animations
- Sign Up / Login buttons with haptic feedback
- Dark/Light theme support
- Responsive design
- Security error handling
- Accessibility features
- Progressive Web App capabilities

⚠️ **Limited Features (Web Constraints):**
- Secure storage (uses browser localStorage)
- Biometric authentication (not available)
- Device integrity checks (limited)
- Some native mobile features

## 🔍 Quick Preview Links

Once deployed, your app will be accessible at:

- **GitHub Pages**: `https://YOUR_USERNAME.github.io/examCoachApp/`
- **Netlify**: `https://YOUR_SITE_NAME.netlify.app`
- **Vercel**: `https://YOUR_PROJECT.vercel.app`
- **Firebase**: `https://YOUR_PROJECT.web.app`

## 🎯 Recommended Deployment Flow

1. **Start with GitHub Pages** (easiest, automatic)
2. **Upgrade to Netlify** (custom domain, better performance)
3. **Consider Vercel** (edge network, serverless functions)
4. **Use Firebase** (full Google ecosystem integration)

## 📊 Monitoring & Analytics

Each deployment option provides:
- Build logs and error tracking
- Performance monitoring
- Analytics integration
- SSL certificates (HTTPS)
- CDN for global distribution

## 🛡️ Security Considerations

- All platforms provide HTTPS by default
- CSP headers configured in `web/index.html`
- No sensitive data exposed in web builds
- Security service adapted for web constraints

---

## 🚀 One-Click Deploy Options

### Deploy to Netlify
[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/YOUR_USERNAME/examCoachApp)

### Deploy to Vercel
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/YOUR_USERNAME/examCoachApp)

---

**Need help?** Check the deployment logs in your chosen platform's dashboard for any build issues. 
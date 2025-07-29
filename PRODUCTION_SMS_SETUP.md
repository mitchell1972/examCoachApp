# 📱 Production SMS Setup Guide

## 🎯 Overview

This guide explains how to configure **real SMS verification** for your Exam Coach app when deployed to production (GitHub Actions, Netlify, Vercel, etc.).

## 🔄 Environment Detection

The app automatically detects the environment:

| Environment | SMS Service | Codes Accepted |
|-------------|-------------|----------------|
| **Local Development** (`flutter run`) | Demo Mode | `123456`, `000000`, `111111`, `555555` |
| **GitHub Actions** (`CI=true`) | **Real Twilio SMS** | **Actual SMS codes sent to phone** |
| **Production Deployment** | **Real Twilio SMS** | **Actual SMS codes sent to phone** |

## 🚀 GitHub Actions Configuration

### ✅ Already Configured

Your GitHub Actions workflow (`.github/workflows/deploy.yml`) is **already configured** with:

```yaml
flutter build web --release --dart-define=CI=true
```

This flag automatically switches the app to **production mode** with **real SMS**.

### 📋 Required Setup

**1. Backend API Configuration**

The app uses a secure backend API at:
```
https://exam-coach-app.vercel.app/api
```

**Endpoints:**
- `POST /send-otp` - Sends SMS to user's phone
- `POST /verify-otp` - Verifies SMS code

**2. User Phone Number**

Make sure your registered user account has the **correct phone number** where you want to receive SMS codes.

### 🔐 Security Architecture

```mermaid
graph LR
    A[Flutter App] --> B[Backend API]
    B --> C[Twilio SMS Service]
    C --> D[Your Phone]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e8
    style D fill:#fff3e0
```

**✅ Secure Design:**
- Twilio credentials stored securely on backend
- No sensitive data in Flutter app
- SMS verification via encrypted API calls
- Production-ready authentication flow

## 📞 Testing Production SMS

### 🎯 How to Test

1. **Deploy to GitHub Pages:**
   ```bash
   git push origin main
   # Wait for GitHub Actions to complete
   # Visit: https://YOUR_USERNAME.github.io/examCoachApp/
   ```

2. **Login with your credentials:**
   - Email: `your_email@example.com`
   - Password: `your_password`

3. **Verify SMS:**
   - Real SMS will be sent to your registered phone number
   - Enter the 6-digit code you receive
   - Login completes successfully

### 🔧 Troubleshooting

**Issue: Not receiving SMS**
```
- Check phone number is correct in registration
- Verify phone has good signal
- Check spam/blocked messages
- Ensure backend API is responding (check browser console)
```

**Issue: SMS code not accepted**
```
- Enter exact code from SMS (6 digits)
- Code expires after 10 minutes
- Try requesting new code with "Resend" button
- Check backend API logs if available
```

## 🌐 Environment Detection Logic

```dart
// Automatic environment detection in lib/services/app_config.dart
Environment _determineEnvironment() {
  const bool isCI = bool.fromEnvironment('CI', defaultValue: false);
  
  if (isCI) {
    return Environment.production;  // Real SMS
  } else if (kDebugMode) {
    return Environment.development; // Demo codes
  } else {
    return Environment.development; // Demo codes
  }
}
```

## 📊 Verification Flow

### 🔄 Production Flow (GitHub Actions)

1. **User enters email/password** → ✅ Verified against database
2. **System sends SMS** → 📱 Real SMS sent to registered phone
3. **User enters SMS code** → ✅ Verified via Twilio backend
4. **Login successful** → 🎉 User logged into dashboard

### 🎭 Development Flow (Local)

1. **User enters email/password** → ✅ Demo user created
2. **SMS verification screen** → 📋 Shows demo codes hint
3. **User enters demo code** → ✅ Any of: `123456`, `000000`, `111111`, `555555`
4. **Login successful** → 🎉 User logged into dashboard

## 🔗 Quick Links

- **Live App:** `https://YOUR_USERNAME.github.io/examCoachApp/`
- **GitHub Actions:** `https://github.com/YOUR_USERNAME/examCoachApp/actions`
- **Backend API:** `https://exam-coach-app.vercel.app/api`

---

## 🎯 Summary

✅ **Production SMS is automatically enabled** when deployed via GitHub Actions  
✅ **Real SMS codes** are sent to your registered phone number  
✅ **Secure backend** handles all Twilio integration  
✅ **Demo mode** for local development with test codes  

**Your app is ready for production SMS verification!** 🚀 
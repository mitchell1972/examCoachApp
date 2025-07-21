# 🔥 Firebase Authentication Setup Guide

## 📋 Prerequisites
- Firebase project (create at https://console.firebase.google.com)
- Phone authentication enabled
- reCAPTCHA configured for web

## 🚀 Step-by-Step Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name: `exam-coach-app`
4. Enable Google Analytics (recommended)

### 2. Enable Phone Authentication
1. In Firebase Console → Authentication → Sign-in method
2. Enable "Phone" provider
3. Add your domain to authorized domains:
   - `localhost` (for development)
   - `your-domain.github.io` (for GitHub Pages)
   - Your custom domain (if applicable)

### 3. Configure reCAPTCHA for Web
1. In Authentication → Settings → "Web" tab
2. Add your domain to "Authorized domains"
3. Configure reCAPTCHA settings:
   - Site key will be auto-generated
   - Make sure "Invisible reCAPTCHA" is enabled

### 4. Get Web Configuration
1. Project Settings → General → "Your apps"
2. Click "Web" icon (</>) 
3. Register your app: `exam-coach-web`
4. Copy the Firebase config object:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456789"
};
```

### 5. Update Flutter App Configuration

#### Replace in `lib/services/firebase_auth_service.dart`:
```dart
FirebaseOptions? _getFirebaseOptions() {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: "YOUR_ACTUAL_API_KEY",           // Replace
      authDomain: "your-project.firebaseapp.com",  // Replace
      projectId: "your-project-id",           // Replace
      storageBucket: "your-project.appspot.com",   // Replace
      messagingSenderId: "123456789012",      // Replace
      appId: "1:123456789012:web:abcdef123456789", // Replace
    );
  }
  return null;
}
```

### 6. Security Configuration

#### Enable App Check (Recommended for Production)
1. Firebase Console → Project Settings → App Check
2. Enable for Web apps
3. Use reCAPTCHA Enterprise for better security

#### Set Security Rules
In Firebase Console → Authentication → Settings:
- **Multi-factor authentication**: Enable for admin accounts
- **User actions**: Set appropriate rate limits
- **Authorized domains**: Only include your production domains

### 7. Environment Variables (Production Best Practice)

For production, use environment variables instead of hardcoded values:

```dart
// lib/config/firebase_config.dart
class FirebaseConfig {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  // ... other configs
}
```

Build with environment variables:
```bash
flutter build web --dart-define=FIREBASE_API_KEY=your_api_key --dart-define=FIREBASE_AUTH_DOMAIN=your_domain.firebaseapp.com
```

### 8. Testing Setup

#### Test Phone Numbers (for development)
1. Firebase Console → Authentication → Settings → "Test phone numbers"
2. Add test numbers like:
   - `+1 555-555-5555` → code: `123456`
   - `+44 7700 900000` → code: `654321`

### 9. Production Deployment Checklist

#### Security Checklist:
- ✅ API keys restricted to specific domains
- ✅ reCAPTCHA configured and tested
- ✅ Rate limiting enabled
- ✅ Test phone numbers removed
- ✅ Error messages don't expose sensitive info
- ✅ Logging configured appropriately
- ✅ App Check enabled (if available)

#### Performance Checklist:
- ✅ Firebase SDK optimized for web
- ✅ Lazy loading of Firebase services
- ✅ Proper error handling and timeouts
- ✅ Network connectivity checks

### 10. Monitoring & Analytics

#### Enable Monitoring:
1. Firebase Console → Performance
2. Enable Performance Monitoring
3. Set up custom traces for auth flows

#### Set up Crashlytics:
1. Firebase Console → Crashlytics
2. Enable for web (if available)
3. Configure crash reporting

## 🚨 Security Best Practices

### API Key Security:
- **Restrict API keys** to specific domains only
- **Use App Check** to prevent unauthorized API usage
- **Monitor usage** in Firebase Console

### Rate Limiting:
- Firebase automatically rate limits SMS sending
- Additional client-side rate limiting implemented in our service
- Monitor for abuse patterns

### Error Handling:
- Never expose sensitive Firebase errors to users
- Log detailed errors server-side only
- Provide user-friendly error messages

### Data Protection:
- Phone numbers are hashed/masked in logs
- No PII stored in client-side analytics
- Comply with GDPR/privacy regulations

## 🧪 Testing

### Test Cases to Verify:
1. ✅ Valid phone number → OTP sent
2. ✅ Invalid phone number → Proper error message  
3. ✅ Rate limiting → Prevents spam
4. ✅ Network offline → Graceful handling
5. ✅ OTP verification → Successful authentication
6. ✅ Invalid OTP → Clear error message
7. ✅ Timeout handling → User informed appropriately

### Manual Testing:
```bash
# Test with your phone number
1. Enter: +[your country code][your number]
2. Check: SMS received with 6-digit code
3. Enter: Correct OTP → Success
4. Enter: Wrong OTP → Error message
5. Test: Rate limiting after multiple attempts
```

## 🆘 Troubleshooting

### Common Issues:

#### "Operation not allowed"
- Enable Phone authentication in Firebase Console
- Check authorized domains

#### "Too many requests"
- Rate limiting triggered
- Wait 1 minute or use test phone numbers

#### "reCAPTCHA not working"
- Check domain authorization
- Verify site key configuration
- Test in incognito mode

#### "Network error"
- Check internet connection
- Verify Firebase configuration
- Check browser console for CORS errors

## 📞 Support

If you encounter issues:
1. Check Firebase Console logs
2. Review browser developer tools
3. Verify all configuration steps
4. Test with Firebase test phone numbers first

## 🔄 Updates

This guide is for Firebase SDK v9+. For the latest updates:
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth/web/phone-auth)
- [Flutter Firebase Documentation](https://firebase.flutter.dev/docs/auth/phone) 
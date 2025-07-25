# 📱 Twilio Authentication Setup Guide

## 📋 Prerequisites
- Twilio account (create at https://www.twilio.com/try-twilio)
- Verify Service created in Twilio Console
- Backend server configured (see TWILIO_BACKEND_SETUP.md)

## 🚀 Step-by-Step Setup

### 1. Create Twilio Account
1. Go to [Twilio Console](https://console.twilio.com)
2. Sign up for a free trial account
3. Note your Account SID and Auth Token from the dashboard

### 2. Create Verify Service
1. In Twilio Console → Verify → Services
2. Click "Create new"
3. Enter service name: `exam-coach-app`
4. Enable "SMS" channel
5. Save and note the Service SID

### 3. Set Up Backend
Follow the instructions in `TWILIO_BACKEND_SETUP.md` to create secure backend endpoints for sending and verifying OTPs. This keeps your Twilio credentials secure.

### 4. Configure Flutter App
1. Update `lib/services/twilio_auth_service.dart` with your backend URL:

```dart
static const String _baseUrl = 'https://your-backend-api.com/api';
```

2. For local development, you can use:
```dart
static const String _baseUrl = 'http://localhost:3000/api';
```

### 5. Security Configuration

#### Implement Rate Limiting
- Use Twilio's built-in rate limits
- Add client-side cooldowns in the app

#### Set Security Rules
- Restrict API access to your app's domains
- Enable fraud prevention in Twilio Verify

### 6. Environment Variables (Production Best Practice)

For production, use environment variables in your backend instead of hardcoded values.

### 7. Testing Setup

#### Test Phone Numbers
- Use Twilio's magic numbers for testing (e.g., +15005550006 always succeeds)
- Add to your backend for development testing

### 8. Production Deployment Checklist

#### Security Checklist:
- ✅ Credentials stored securely in backend
- ✅ Rate limiting enabled
- ✅ Test phone numbers removed
- ✅ Error messages don't expose sensitive info
- ✅ Logging configured appropriately

#### Performance Checklist:
- ✅ Use Twilio SDK optimized for web
- ✅ Lazy loading of services
- ✅ Proper error handling and timeouts
- ✅ Network connectivity checks

### 9. Monitoring & Analytics

#### Enable Monitoring:
1. Twilio Console → Monitor
2. Set up alerts for verification failures

#### Set up Logging:
1. Implement backend logging for all requests
2. Monitor usage in Twilio Console

## 🚨 Security Best Practices

### Credential Security:
- **Never expose credentials** in client-side code
- **Use environment variables** in backend
- **Monitor usage** in Twilio Console

### Rate Limiting:
- Twilio automatically rate limits SMS sending
- Implement additional backend rate limiting

### Error Handling:
- Never expose Twilio errors to users
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
- Check Twilio account status
- Verify Service SID

#### "Too many requests"
- Rate limiting triggered
- Wait and try again

#### "Network error"
- Check internet connection
- Verify backend URL
- Check browser console for CORS errors

## 📞 Support

If you encounter issues:
1. Check Twilio Console logs
2. Review browser developer tools
3. Verify all configuration steps
4. Test with Twilio magic numbers first

## 🔄 Updates

For the latest updates:
- [Twilio Verify Documentation](https://www.twilio.com/docs/verify)
- [Flutter HTTP Documentation](https://docs.flutter.dev/cookbook/networking/send-data)

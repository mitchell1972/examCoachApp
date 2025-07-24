# Twilio Backend Setup Guide

## Overview

This guide explains how to set up the backend endpoints required for Twilio phone verification in your Exam Coach app. The backend is necessary to keep your Twilio credentials secure.

## Why You Need a Backend

- **Security**: Twilio credentials (Account SID, Auth Token, Service SID) should NEVER be exposed in your Flutter app
- **Control**: Backend allows you to implement rate limiting, logging, and additional verification logic
- **Flexibility**: Easy to switch SMS providers or add additional verification methods

## Required Twilio Setup

1. **Create a Twilio Account**
   - Go to [https://www.twilio.com/try-twilio](https://www.twilio.com/try-twilio)
   - Sign up for a free trial account (includes $15 credit)

2. **Set Up Twilio Verify Service**
   - Navigate to Verify > Services in the Twilio Console
   - Click "Create Service"
   - Name it "Exam Coach" or similar
   - Save the Service SID (you'll need this)

3. **Get Your Credentials**
   - Account SID: Found on your Twilio Console dashboard
   - Auth Token: Found on your Twilio Console dashboard
   - Verify Service SID: From the service you just created

## Backend Implementation Options

### Option 1: Node.js/Express Backend

```javascript
// server.js
const express = require('express');
const twilio = require('twilio');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Initialize Twilio client
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
const client = twilio(accountSid, authToken);

// Endpoint to send OTP
app.post('/api/send-otp', async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    
    // Validate phone number format
    if (!phoneNumber || !phoneNumber.match(/^\+[1-9]\d{1,14}$/)) {
      return res.status(400).json({ error: 'Invalid phone number format' });
    }
    
    // Send verification code
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verifications
      .create({ to: phoneNumber, channel: 'sms' });
    
    res.json({ 
      status: 'success', 
      message: 'Verification code sent',
      sid: verification.sid 
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({ error: 'Failed to send verification code' });
  }
});

// Endpoint to verify OTP
app.post('/api/verify-otp', async (req, res) => {
  try {
    const { phoneNumber, code } = req.body;
    
    // Validate inputs
    if (!phoneNumber || !code) {
      return res.status(400).json({ error: 'Phone number and code are required' });
    }
    
    // Verify the code
    const verificationCheck = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks
      .create({ to: phoneNumber, code: code });
    
    if (verificationCheck.status === 'approved') {
      // Generate a user ID or retrieve from database
      const userId = `user_${Date.now()}`;
      
      res.json({ 
        status: 'success',
        userId: userId,
        phoneNumber: phoneNumber,
        message: 'Phone number verified successfully'
      });
    } else {
      res.status(400).json({ error: 'Invalid verification code' });
    }
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Environment Variables (.env file):**
```
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_VERIFY_SERVICE_SID=your_verify_service_sid_here
PORT=3000
```

### Option 2: Firebase Cloud Functions

```javascript
// functions/index.js
const functions = require('firebase-functions');
const twilio = require('twilio');

// Initialize Twilio client
const accountSid = functions.config().twilio.account_sid;
const authToken = functions.config().twilio.auth_token;
const verifyServiceSid = functions.config().twilio.verify_service_sid;
const client = twilio(accountSid, authToken);

exports.sendOTP = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }
  
  try {
    const { phoneNumber } = req.body;
    
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verifications
      .create({ to: phoneNumber, channel: 'sms' });
    
    res.json({ status: 'success', message: 'Verification code sent' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to send verification code' });
  }
});

exports.verifyOTP = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }
  
  try {
    const { phoneNumber, code } = req.body;
    
    const verificationCheck = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks
      .create({ to: phoneNumber, code: code });
    
    if (verificationCheck.status === 'approved') {
      const userId = `user_${Date.now()}`;
      res.json({ 
        status: 'success',
        userId: userId,
        phoneNumber: phoneNumber
      });
    } else {
      res.status(400).json({ error: 'Invalid verification code' });
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});
```

**Set Firebase Functions Config:**
```bash
firebase functions:config:set twilio.account_sid="your_account_sid" \
  twilio.auth_token="your_auth_token" \
  twilio.verify_service_sid="your_verify_service_sid"
```

### Option 3: Vercel/Netlify Serverless Functions

**Vercel Example (api/send-otp.js):**
```javascript
const twilio = require('twilio');

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  try {
    const { phoneNumber } = req.body;
    
    const verification = await client.verify.v2
      .services(process.env.TWILIO_VERIFY_SERVICE_SID)
      .verifications
      .create({ to: phoneNumber, channel: 'sms' });
    
    res.status(200).json({ 
      status: 'success', 
      message: 'Verification code sent' 
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to send verification code' });
  }
}
```

## Updating Your Flutter App

Once your backend is set up, update the `_baseUrl` in `lib/services/twilio_auth_service.dart`:

```dart
// Replace with your actual backend URL
static const String _baseUrl = 'https://your-backend-api.com/api';
// Or for local development:
// static const String _baseUrl = 'http://localhost:3000/api';
```

## Security Best Practices

1. **Rate Limiting**: Implement rate limiting to prevent abuse
2. **Phone Number Validation**: Validate phone numbers before sending OTP
3. **Logging**: Log all verification attempts for security monitoring
4. **HTTPS**: Always use HTTPS in production
5. **CORS**: Configure CORS properly to only allow your app's domain

## Testing

1. **Development Mode**: The app includes a demo mode that doesn't require a backend
2. **Test with Real Backend**: Once deployed, update the `_baseUrl` and test with real phone numbers
3. **Twilio Test Numbers**: Use Twilio's test phone numbers during development

## Cost Considerations

- Twilio Verify pricing: ~$0.05 per verification
- Free trial includes $15 credit (approximately 300 verifications)
- Monitor usage in Twilio Console

## Troubleshooting

1. **"Failed to send OTP" Error**
   - Check Twilio credentials
   - Verify phone number format (must include country code: +1234567890)
   - Check Twilio account balance

2. **"Invalid verification code" Error**
   - Codes expire after 10 minutes
   - Ensure correct phone number is used for verification
   - Check for typos in the code

3. **CORS Issues**
   - Ensure backend allows requests from your Flutter app's domain
   - Check CORS headers in backend responses

## Support

For Twilio-specific issues:
- [Twilio Verify Documentation](https://www.twilio.com/docs/verify/api)
- [Twilio Support](https://support.twilio.com)

For implementation help:
- Review the example backend implementations above
- Check the Flutter app logs for detailed error messages 
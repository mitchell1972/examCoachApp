const twilio = require('twilio');

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  try {
    // Check for required environment variables
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
    
    if (!accountSid || !authToken || !verifyServiceSid) {
      console.error('Missing Twilio environment variables:', {
        accountSid: !!accountSid,
        authToken: !!authToken,
        verifyServiceSid: !!verifyServiceSid
      });
      return res.status(500).json({ 
        error: 'Server configuration error: Missing Twilio credentials',
        details: 'Please configure TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_VERIFY_SERVICE_SID environment variables'
      });
    }
    
    const { phoneNumber } = req.body;
    
    if (!phoneNumber) {
      return res.status(400).json({ error: 'Phone number is required' });
    }
    
    // Initialize Twilio client with validated credentials
    const client = twilio(accountSid, authToken);
    
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verifications
      .create({ to: phoneNumber, channel: 'sms' });
    
    res.status(200).json({ 
      status: 'success', 
      message: 'Verification code sent',
      sid: verification.sid 
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    
    // Provide more specific error messages
    if (error.code === 21211) {
      return res.status(400).json({ error: 'Invalid phone number format' });
    } else if (error.code === 20003) {
      return res.status(401).json({ error: 'Invalid Twilio credentials' });
    } else if (error.code === 21608) {
      return res.status(400).json({ error: 'Phone number is not verified for trial account' });
    }
    
    res.status(500).json({ 
      error: 'Failed to send verification code',
      details: error.message || 'Unknown error occurred'
    });
  }
};

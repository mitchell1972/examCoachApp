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
    
    const { phoneNumber, code } = req.body;
    
    if (!phoneNumber || !code) {
      return res.status(400).json({ error: 'Phone number and code are required' });
    }
    
    // Initialize Twilio client with validated credentials
    const client = twilio(accountSid, authToken);
    
    const verificationCheck = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks
      .create({ to: phoneNumber, code: code });
    
    if (verificationCheck.status === 'approved') {
      // In a real app, you'd generate a proper user ID, perhaps from a database
      const userId = `user_${Date.now()}`;
      
      res.status(200).json({ 
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
    
    // Provide more specific error messages
    if (error.code === 20404) {
      return res.status(400).json({ error: 'Verification code not found or expired' });
    } else if (error.code === 20003) {
      return res.status(401).json({ error: 'Invalid Twilio credentials' });
    } else if (error.code === 60200) {
      return res.status(400).json({ error: 'Invalid verification code' });
    }
    
    res.status(500).json({ 
      error: 'Verification failed',
      details: error.message || 'Unknown error occurred'
    });
  }
};

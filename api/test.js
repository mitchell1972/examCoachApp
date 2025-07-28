module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  res.status(200).json({ 
    message: 'Test function working',
    method: req.method,
    env_vars: {
      twilio_account_sid: process.env.TWILIO_ACCOUNT_SID ? 'SET' : 'NOT_SET',
      twilio_auth_token: process.env.TWILIO_AUTH_TOKEN ? 'SET' : 'NOT_SET',
      twilio_verify_service_sid: process.env.TWILIO_VERIFY_SERVICE_SID ? 'SET' : 'NOT_SET'
    }
  });
};

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  // Check environment variables without exposing sensitive data
  const config = {
    timestamp: new Date().toISOString(),
    hasAccountSid: !!process.env.TWILIO_ACCOUNT_SID,
    hasAuthToken: !!process.env.TWILIO_AUTH_TOKEN,
    hasVerifyServiceSid: !!process.env.TWILIO_VERIFY_SERVICE_SID,
    nodeEnv: process.env.NODE_ENV || 'not set',
    vercelEnv: process.env.VERCEL_ENV || 'not set',
    deploymentId: process.env.VERCEL_DEPLOYMENT_ID || 'not set'
  };

  res.status(200).json({
    status: 'success',
    message: 'Configuration check endpoint',
    config: config,
    allConfigured: config.hasAccountSid && config.hasAuthToken && config.hasVerifyServiceSid
  });
};

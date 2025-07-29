# Supabase Database Setup Guide

## Overview
This guide walks you through setting up Supabase as the database backend for the Exam Coach App, supporting up to 200,000+ users with hybrid authentication.

## Step 1: Create Supabase Project

### 1.1 Sign Up for Supabase
1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project" 
3. Sign up with GitHub, Google, or email
4. Verify your email if required

### 1.2 Create New Project
1. Click "New Project"
2. Choose your organization (or create one)
3. Fill in project details:
   - **Project Name**: `exam-coach-app`
   - **Database Password**: Generate a strong password (save this!)
   - **Region**: Choose closest to your users (e.g., US East, Europe West)
4. Click "Create new project"
5. Wait 2-3 minutes for project setup

### 1.3 Get Project Credentials
1. Go to **Settings** → **API**
2. Copy the following values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **service_role secret key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (keep this secure!)

## Step 2: Configure Database Schema

### 2.1 Run SQL Setup
1. Go to **SQL Editor** in your Supabase dashboard
2. Click "New query"
3. Copy and paste the following SQL:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username VARCHAR(50) UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  current_class VARCHAR(50),
  school_type VARCHAR(100),
  study_focus TEXT[], -- Array of exam types
  science_subjects TEXT[], -- Array of subjects
  exam_types TEXT[], -- Mapped from study_focus
  subjects TEXT[], -- Mapped from science_subjects
  exam_type VARCHAR(100), -- Legacy field for backward compatibility
  subject VARCHAR(100), -- Legacy field for backward compatibility
  status VARCHAR(20) DEFAULT 'trial',
  trial_start_date TIMESTAMPTZ,
  trial_expires TIMESTAMPTZ,
  last_login_date TIMESTAMPTZ,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User sessions for tracking active users
CREATE TABLE public.user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  device_info JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true
);

-- User preferences and settings
CREATE TABLE public.user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  notifications_enabled BOOLEAN DEFAULT true,
  theme_preference VARCHAR(20) DEFAULT 'system',
  language_preference VARCHAR(10) DEFAULT 'en',
  quiz_difficulty VARCHAR(20) DEFAULT 'medium',
  study_reminders BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_phone_number ON public.users(phone_number);
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_status ON public.users(status);
CREATE INDEX idx_users_trial_expires ON public.users(trial_expires);
CREATE INDEX idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON public.user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires ON public.user_sessions(expires_at);

-- Row Level Security (RLS) policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own sessions" ON public.user_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

4. Click "Run" to execute the SQL
5. Verify tables are created in **Table Editor**

### 2.2 Configure Authentication
1. Go to **Authentication** → **Settings**
2. Configure the following:

**Site URL**: `https://your-app-domain.com` (or `http://localhost:3000` for development)

**Redirect URLs**: Add these URLs:
- `https://your-app-domain.com/auth/callback`
- `http://localhost:3000/auth/callback`

**Email Templates**: Customize if needed

**Phone Auth**: 
- Enable "Enable phone confirmations"
- Configure SMS provider (Twilio recommended)

## Step 3: Configure Flutter App

### 3.1 Create Environment File
1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Edit `.env` with your Supabase credentials:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Twilio Configuration (existing)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone-number
```

### 3.2 Install Dependencies
```bash
flutter pub get
```

### 3.3 Test Database Connection
1. Run the app:
```bash
flutter run
```

2. Check logs for successful initialization:
```
✅ Environment variables loaded successfully
✅ Supabase initialized successfully
✅ Database Service initialized successfully
```

## Step 4: Authentication Setup

### 4.1 Phone Authentication (OTP)
The app supports phone-based OTP authentication through Supabase:

1. **Registration**: User enters phone number → OTP sent → User verifies → Account created
2. **Login**: User enters phone number → OTP sent → User verifies → Logged in

### 4.2 Username/Password Authentication
The app also supports traditional username/password authentication:

1. **Registration**: User creates username, password, email → Account created
2. **Login**: User enters username/email + password → Logged in

### 4.3 Hybrid Authentication Flow
Users can choose their preferred authentication method:
- **Primary**: Phone + OTP (existing users)
- **Secondary**: Username + Password (new option)
- **Future**: Email + Password, Social logins

## Step 5: Data Migration

### 5.1 Migrate Existing Users
If you have existing users in local storage, create a migration script:

```dart
// Example migration function
Future<void> migrateExistingUsers() async {
  final storageService = StorageService();
  final databaseService = DatabaseService();
  
  // Get existing user data
  final existingUser = await storageService.getUser();
  
  if (existingUser != null) {
    // Create user in Supabase
    await databaseService.createUserWithPhone(
      phoneNumber: existingUser.phoneNumber,
      fullName: existingUser.fullName,
      currentClass: existingUser.currentClass,
      schoolType: existingUser.schoolType,
      studyFocus: existingUser.studyFocus,
      scienceSubjects: existingUser.scienceSubjects,
    );
    
    // Clear local storage after successful migration
    await storageService.clearUser();
  }
}
```

### 5.2 Test Migration
1. Create test users in both authentication methods
2. Verify data integrity
3. Test login flows
4. Verify trial system works correctly

## Step 6: Production Deployment

### 6.1 Environment Variables
Set up environment variables in your deployment platform:

**Vercel**:
```bash
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
```

**Netlify**:
Add in Site Settings → Environment Variables

**Firebase Hosting**:
```bash
firebase functions:config:set supabase.url="your-url" supabase.key="your-key"
```

### 6.2 Security Checklist
- [ ] RLS policies are enabled and tested
- [ ] Service role key is kept secure (server-side only)
- [ ] CORS is configured correctly
- [ ] Rate limiting is enabled
- [ ] Backup strategy is in place

### 6.3 Monitoring Setup
1. **Supabase Dashboard**: Monitor database performance
2. **Authentication**: Track login success/failure rates
3. **Usage**: Monitor API calls and storage usage
4. **Alerts**: Set up alerts for errors and limits

## Step 7: Testing

### 7.1 Unit Tests
Run existing tests to ensure compatibility:
```bash
flutter test
```

### 7.2 Integration Tests
Test database operations:
```bash
flutter test test/database_integration_test.dart
```

### 7.3 Load Testing
Test with multiple concurrent users:
- Use tools like Artillery or k6
- Test authentication flows
- Monitor database performance

## Step 8: Scaling Considerations

### 8.1 Performance Optimization
- **Connection Pooling**: Enabled by default in Supabase
- **Indexing**: Already configured for common queries
- **Caching**: Implement Redis for frequently accessed data
- **CDN**: Use Supabase's built-in CDN for static assets

### 8.2 Cost Management
- **Free Tier**: 50,000 monthly active users
- **Pro Tier**: $25/month for 100,000 monthly active users
- **Team Tier**: $599/month for 200,000 monthly active users
- **Monitoring**: Set up billing alerts

### 8.3 Backup Strategy
- **Automatic Backups**: Enabled by default (7-day retention)
- **Point-in-time Recovery**: Available on Pro tier and above
- **Manual Backups**: Export data regularly for critical applications

## Troubleshooting

### Common Issues

**1. Connection Errors**
```
Error: Invalid API key
```
- Verify SUPABASE_URL and SUPABASE_ANON_KEY in .env
- Check if keys are correctly copied (no extra spaces)

**2. RLS Policy Errors**
```
Error: Row Level Security policy violation
```
- Verify RLS policies are correctly configured
- Check if user is authenticated before database operations

**3. Phone Auth Issues**
```
Error: Phone number verification failed
```
- Verify phone auth is enabled in Supabase
- Check SMS provider configuration
- Ensure phone number format is correct

**4. Migration Issues**
```
Error: Duplicate key value violates unique constraint
```
- Check for existing users with same phone/email
- Implement proper conflict resolution

### Getting Help

1. **Supabase Documentation**: [https://supabase.com/docs](https://supabase.com/docs)
2. **Supabase Discord**: [https://discord.supabase.com](https://discord.supabase.com)
3. **GitHub Issues**: Create issues for bugs or feature requests
4. **Support**: Contact Supabase support for Pro/Team tier users

## Next Steps

After successful setup:

1. **Implement Advanced Features**:
   - Real-time notifications
   - User analytics
   - Advanced search
   - Data export/import

2. **Enhance Security**:
   - Multi-factor authentication
   - Session management
   - Audit logging
   - Compliance features

3. **Scale the Application**:
   - Implement caching
   - Optimize queries
   - Add monitoring
   - Plan for growth

4. **Business Intelligence**:
   - User behavior analytics
   - Performance metrics
   - Revenue tracking
   - Growth insights

## Conclusion

With Supabase integrated, your Exam Coach App now has:
- ✅ Scalable database for 200K+ users
- ✅ Hybrid authentication (OTP + username/password)
- ✅ Real-time capabilities
- ✅ Built-in security and compliance
- ✅ Professional-grade infrastructure
- ✅ Cost-effective scaling path

The app is now ready for production deployment and can scale seamlessly as your user base grows.

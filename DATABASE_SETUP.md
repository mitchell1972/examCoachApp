# Database Setup Guide - Supabase Integration

## Overview
This document outlines the implementation of Supabase as the primary database for the Exam Coach App, supporting up to 200,000+ users with hybrid authentication.

## Architecture Decision

### Why Supabase?
- **Scalability**: PostgreSQL backend can handle 200K+ users
- **Free Tier**: 50,000 monthly active users to start
- **Built-in Auth**: Supports OTP, email/password, and social logins
- **Real-time**: Built-in real-time subscriptions for live features
- **Flutter SDK**: Excellent Flutter integration with supabase_flutter package
- **Easy Migration**: Seamless upgrade path as the app grows

### Database Schema Design

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

## Implementation Plan

### Phase 1: Setup and Configuration
1. Create Supabase project
2. Configure database schema
3. Set up authentication policies
4. Add Flutter dependencies

### Phase 2: Authentication Integration
1. Implement Supabase auth service
2. Add username/password authentication
3. Maintain OTP authentication
4. Create hybrid login flow

### Phase 3: Data Migration
1. Create migration utilities
2. Migrate existing user data
3. Update storage service
4. Test data integrity

### Phase 4: Enhanced Features
1. Real-time user status
2. Session management
3. User preferences
4. Analytics and monitoring

## Security Features

### Authentication Methods
- **Phone + OTP**: Primary method (existing)
- **Username + Password**: Secondary method (new)
- **Email + Password**: Optional method
- **Social Login**: Future enhancement

### Security Measures
- Row Level Security (RLS) enabled
- JWT token-based authentication
- Secure password hashing (bcrypt)
- Session management with expiration
- Rate limiting on authentication attempts
- IP-based access logging

## Scalability Considerations

### Performance Optimizations
- Database indexing on frequently queried fields
- Connection pooling for high concurrency
- Caching layer for frequently accessed data
- Pagination for large data sets

### Monitoring and Analytics
- User activity tracking
- Performance metrics
- Error logging and alerting
- Usage analytics for optimization

## Cost Structure

### Supabase Pricing Tiers
- **Free Tier**: Up to 50,000 monthly active users
- **Pro Tier**: $25/month for up to 100,000 monthly active users
- **Team Tier**: $599/month for up to 200,000 monthly active users
- **Enterprise**: Custom pricing for 200K+ users

### Estimated Costs for 200K Users
- **Year 1**: Free tier (0-50K users) = $0
- **Year 2**: Pro tier (50K-100K users) = $300/year
- **Year 3**: Team tier (100K-200K users) = $7,188/year

## Next Steps

1. **Create Supabase Project**: Set up the database and authentication
2. **Implement Flutter Integration**: Add Supabase SDK to the app
3. **Create Database Schema**: Run the SQL scripts to set up tables
4. **Implement Authentication Service**: Create the hybrid auth system
5. **Data Migration**: Move existing users to the new system
6. **Testing**: Comprehensive testing of all features
7. **Deployment**: Deploy the enhanced app with database integration

## Benefits of This Approach

### For Users
- Faster login with username/password option
- Secure data storage and backup
- Real-time features and notifications
- Better app performance and reliability

### For Development
- Scalable architecture for growth
- Built-in security and compliance
- Real-time capabilities
- Comprehensive analytics and monitoring
- Easy maintenance and updates

### For Business
- Cost-effective scaling path
- Professional-grade infrastructure
- Built-in backup and disaster recovery
- Compliance with data protection regulations
- Analytics for business insights

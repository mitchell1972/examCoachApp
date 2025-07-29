import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  
  // Default values for development (replace with your actual Supabase project values)
  static const String _defaultUrl = 'https://your-project.supabase.co';
  static const String _defaultAnonKey = 'your-anon-key';
  
  static String get supabaseUrl {
    return dotenv.env[_supabaseUrlKey] ?? _defaultUrl;
  }
  
  static String get supabaseAnonKey {
    return dotenv.env[_supabaseAnonKeyKey] ?? _defaultAnonKey;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false, // Set to true for development
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
}

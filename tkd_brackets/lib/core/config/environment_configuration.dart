/// Environment configuration holder.
/// Values are passed from main_*.dart entry points.
class EnvironmentConfiguration {
  const EnvironmentConfiguration({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// Current environment name (development, staging, production).
  final String environment;
  
  /// Supabase project URL.
  final String supabaseUrl;
  
  /// Supabase anonymous key.
  final String supabaseAnonKey;

  /// Whether the app is running in development mode.
  bool get isDevelopment => environment == 'development';
  
  /// Whether the app is running in staging mode.
  bool get isStaging => environment == 'staging';
  
  /// Whether the app is running in production mode.
  bool get isProduction => environment == 'production';
}

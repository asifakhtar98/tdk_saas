import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'development',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    // Empty string = Sentry disabled in development
    sentryDsn: '',
  );
}

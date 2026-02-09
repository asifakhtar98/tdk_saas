import 'package:tkd_brackets/bootstrap.dart';
import 'package:tkd_brackets/core/config/env.dart';

void main() {
  bootstrap(
    environment: 'development',
    supabaseUrl: Env.supabaseUrl,
    supabaseAnonKey: Env.supabaseAnonKey,
    // Empty string = Sentry disabled in development
    sentryDsn: '',
  );
}

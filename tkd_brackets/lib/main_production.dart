import 'package:tkd_brackets/bootstrap.dart';
import 'package:tkd_brackets/core/config/env.dart';

void main() {
  bootstrap(
    environment: 'production',
    supabaseUrl: Env.supabaseUrl,
    supabaseAnonKey: Env.supabaseAnonKey,
    sentryDsn: Env.sentryDsn ?? '',
  );
}

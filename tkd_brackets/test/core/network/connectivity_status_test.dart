import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';

void main() {
  group('ConnectivityStatus', () {
    test('should have online status', () {
      expect(ConnectivityStatus.online, isNotNull);
      expect(ConnectivityStatus.online.name, equals('online'));
    });

    test('should have offline status', () {
      expect(ConnectivityStatus.offline, isNotNull);
      expect(ConnectivityStatus.offline.name, equals('offline'));
    });

    test('should have slow status', () {
      expect(ConnectivityStatus.slow, isNotNull);
      expect(ConnectivityStatus.slow.name, equals('slow'));
    });

    test('should have exactly 3 values', () {
      expect(ConnectivityStatus.values.length, equals(3));
    });
  });
}

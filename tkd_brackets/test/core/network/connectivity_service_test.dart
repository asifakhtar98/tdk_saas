import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockInternetConnection extends Mock implements InternetConnection {}

void main() {
  late MockConnectivity mockConnectivity;
  late MockInternetConnection mockInternetConnection;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late StreamController<InternetStatus> internetStatusController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockInternetConnection = MockInternetConnection();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();
    internetStatusController = StreamController<InternetStatus>.broadcast();

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(
      () => mockInternetConnection.onStatusChange,
    ).thenAnswer((_) => internetStatusController.stream);
  });

  tearDown(() {
    connectivityController.close();
    internetStatusController.close();
  });

  group('ConnectivityServiceImplementation', () {
    test('should start with offline status before initial check', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => false);

      final service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      // Allow initial check to complete
      await Future<void>.delayed(Duration.zero);

      expect(service.currentStatus, equals(ConnectivityStatus.offline));

      service.dispose();
    });

    test('should update to online when internet is available', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => true);

      final service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      // Allow initial check to complete
      await Future<void>.delayed(Duration.zero);

      expect(service.currentStatus, equals(ConnectivityStatus.online));

      service.dispose();
    });

    test('should emit status changes on stream', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => true);

      final service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      final statuses = <ConnectivityStatus>[];
      final subscription = service.statusStream.listen(statuses.add);

      // Allow initial check to complete
      await Future<void>.delayed(Duration.zero);

      // Simulate going offline
      internetStatusController.add(InternetStatus.disconnected);
      await Future<void>.delayed(Duration.zero);

      // Simulate going online
      internetStatusController.add(InternetStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(ConnectivityStatus.online));
      expect(statuses, contains(ConnectivityStatus.offline));

      await subscription.cancel();
      service.dispose();
    });

    test('should return correct value from hasInternetConnection', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => true);

      final service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      final result = await service.hasInternetConnection();

      expect(result, isTrue);

      service.dispose();
    });

    test('should handle connectivity result none as offline', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => true);

      final service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      // Allow initial check
      await Future<void>.delayed(Duration.zero);

      // Simulate no network interface
      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentStatus, equals(ConnectivityStatus.offline));

      service.dispose();
    });

    test('should update status when connectivity changes to wifi', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => false);

      final service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      // Allow initial check (offline)
      await Future<void>.delayed(Duration.zero);
      expect(service.currentStatus, equals(ConnectivityStatus.offline));

      // Now change the mock to return online
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => true);

      // Simulate wifi connected
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentStatus, equals(ConnectivityStatus.online));

      service.dispose();
    });
  });

  group('ConnectivityService interface', () {
    test('implementation should satisfy interface contract', () async {
      when(
        () => mockInternetConnection.hasInternetAccess,
      ).thenAnswer((_) async => true);

      final ConnectivityService service = ConnectivityServiceImplementation(
        mockConnectivity,
        mockInternetConnection,
      );

      // Allow initial async operations to complete before assertions
      await Future<void>.delayed(Duration.zero);

      expect(service.statusStream, isA<Stream<ConnectivityStatus>>());
      expect(service.currentStatus, isA<ConnectivityStatus>());

      service.dispose();
    });
  });
}

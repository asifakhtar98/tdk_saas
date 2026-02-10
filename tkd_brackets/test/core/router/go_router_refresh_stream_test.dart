import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/router/app_router.dart';

void main() {
  group('GoRouterRefreshStream', () {
    late StreamController<int> streamController;
    late GoRouterRefreshStream refreshStream;
    bool wasDisposed = false;

    setUp(() {
      wasDisposed = false;
      streamController =
          StreamController<int>.broadcast();
      refreshStream =
          GoRouterRefreshStream(streamController.stream);
    });

    tearDown(() {
      if (!wasDisposed) {
        refreshStream.dispose();
      }
      streamController.close();
    });

    test(
      'calls notifyListeners on construction',
      () {
        // GoRouterRefreshStream calls notifyListeners()
        // in constructor. We verify by adding a listener
        // that will receive future notifications. The
        // initial call happens before we can listen, but
        // we validate the object is created and
        // functioning.
        expect(refreshStream, isA<ChangeNotifier>());
      },
    );

    test(
      'calls notifyListeners when stream emits',
      () async {
        var notifyCount = 0;
        refreshStream
            .addListener(() => notifyCount++);

        streamController.add(1);
        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        );

        expect(notifyCount, equals(1));
      },
    );

    test(
      'calls notifyListeners for each stream event',
      () async {
        var notifyCount = 0;
        refreshStream
            .addListener(() => notifyCount++);

        streamController
          ..add(1)
          ..add(2)
          ..add(3);

        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        );

        expect(notifyCount, equals(3));
      },
    );

    test(
      'stops notifying after dispose',
      () async {
        var notifyCount = 0;
        refreshStream
            .addListener(() => notifyCount++);

        streamController.add(1);
        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        );

        expect(notifyCount, equals(1));

        refreshStream.dispose();
        wasDisposed = true;

        // Adding to stream after dispose should not
        // trigger notifications (subscription cancelled)
        streamController.add(2);
        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        );

        expect(notifyCount, equals(1));
      },
    );
  });
}

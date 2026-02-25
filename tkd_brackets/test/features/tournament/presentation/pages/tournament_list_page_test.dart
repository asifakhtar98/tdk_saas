import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournaments_usecase.dart';
import 'package:tkd_brackets/features/tournament/presentation/pages/tournament_list_page.dart';

// Mock classes
class MockGetTournamentsUseCase extends Mock implements GetTournamentsUseCase {}

class MockArchiveTournamentUseCase extends Mock
    implements ArchiveTournamentUseCase {}

class MockDeleteTournamentUseCase extends Mock
    implements DeleteTournamentUseCase {}

class MockCreateTournamentUseCase extends Mock
    implements CreateTournamentUseCase {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockGetTournamentsUseCase mockGetTournaments;
  late MockArchiveTournamentUseCase mockArchiveTournament;
  late MockDeleteTournamentUseCase mockDeleteTournament;
  late MockCreateTournamentUseCase mockCreateTournament;
  late MockSyncService mockSyncService;
  late StreamController<SyncStatus> statusController;

  setUpAll(() {
    // Register fallback values for custom param types used with any()
    // String params work without fallback, but this future-proofs
    // against adding stubs with custom param types.
  });

  setUp(() {
    mockGetTournaments = MockGetTournamentsUseCase();
    mockArchiveTournament = MockArchiveTournamentUseCase();
    mockDeleteTournament = MockDeleteTournamentUseCase();
    mockCreateTournament = MockCreateTournamentUseCase();
    mockSyncService = MockSyncService();
    statusController = StreamController<SyncStatus>.broadcast();

    // Register mock use cases in GetIt
    GetIt.instance
        .registerSingleton<GetTournamentsUseCase>(mockGetTournaments);
    GetIt.instance
        .registerSingleton<ArchiveTournamentUseCase>(mockArchiveTournament);
    GetIt.instance
        .registerSingleton<DeleteTournamentUseCase>(mockDeleteTournament);
    GetIt.instance
        .registerSingleton<CreateTournamentUseCase>(mockCreateTournament);

    // Register mock SyncService (needed by SyncStatusIndicatorWidget)
    GetIt.instance.registerSingleton<SyncService>(mockSyncService);

    // Stub SyncService
    when(
      () => mockSyncService.statusStream,
    ).thenAnswer((_) => statusController.stream);
    when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);
    when(() => mockSyncService.currentError).thenReturn(null);

    // Default: GetTournaments returns empty list
    when(
      () => mockGetTournaments.call(any()),
    ).thenAnswer((_) async => const Right(<TournamentEntity>[]));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await statusController.close();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: TournamentListPage());
  }

  group('TournamentListPage', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TournamentListPage), findsOneWidget);
    });

    testWidgets('displays Tournaments in AppBar title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tournaments'), findsOneWidget);
    });

    testWidgets('shows Create Tournament FAB', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // FAB label + empty state button both show 'Create Tournament'
      expect(find.text('Create Tournament'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state text when no tournaments', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No tournaments yet'), findsOneWidget);
    });

    testWidgets('displays filter chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
    });
  });
}

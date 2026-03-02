import 'dart:ui' show Size;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/bracket_layout_engine.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_bloc.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_state.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockBracketLayoutEngine extends Mock implements BracketLayoutEngine {}

class MockLockBracketUseCase extends Mock implements LockBracketUseCase {}

class MockUnlockBracketUseCase extends Mock implements UnlockBracketUseCase {}

class FakeLockBracketParams extends Fake implements LockBracketParams {}

class FakeUnlockBracketParams extends Fake implements UnlockBracketParams {}

void main() {
  late MockBracketRepository bracketRepository;
  late MockMatchRepository matchRepository;
  late MockBracketLayoutEngine layoutEngine;
  late MockLockBracketUseCase lockBracketUseCase;
  late MockUnlockBracketUseCase unlockBracketUseCase;

  const bracketId = 'b1';
  final testBracket = BracketEntity(
    id: bracketId,
    divisionId: 'd1',
    bracketType: BracketType.winners,
    totalRounds: 2,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );
  final testMatches = <MatchEntity>[];
  const testLayout = BracketLayout(
    format: BracketFormat.singleElimination,
    rounds: [],
    canvasSize: Size.zero,
  );

  setUpAll(() {
    registerFallbackValue(testBracket);
    registerFallbackValue(testMatches);
    registerFallbackValue(const BracketLayoutOptions());
    registerFallbackValue(FakeLockBracketParams());
    registerFallbackValue(FakeUnlockBracketParams());
  });

  setUp(() {
    bracketRepository = MockBracketRepository();
    matchRepository = MockMatchRepository();
    layoutEngine = MockBracketLayoutEngine();
    lockBracketUseCase = MockLockBracketUseCase();
    unlockBracketUseCase = MockUnlockBracketUseCase();
  });

  BracketBloc buildBloc() => BracketBloc(
    bracketRepository,
    matchRepository,
    layoutEngine,
    lockBracketUseCase,
    unlockBracketUseCase,
  );

  void setupSuccessfulLoad() {
    when(
      () => bracketRepository.getBracketById(bracketId),
    ).thenAnswer((_) async => Right(testBracket));
    when(
      () => matchRepository.getMatchesForBracket(bracketId),
    ).thenAnswer((_) async => Right(testMatches));
    when(
      () => layoutEngine.calculateLayout(
        bracket: any(named: 'bracket'),
        matches: any(named: 'matches'),
        options: any(named: 'options'),
      ),
    ).thenReturn(testLayout);
  }

  group('BracketBloc', () {
    test('initial state is BracketInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const BracketInitial());
      bloc.close();
    });

    blocTest<BracketBloc, BracketState>(
      'emits [LoadInProgress, LoadSuccess] when loadRequested succeeds',
      setUp: setupSuccessfulLoad,
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketLoadRequested(bracketId: bracketId)),
      expect: () => [
        const BracketLoadInProgress(),
        BracketLoadSuccess(
          bracket: testBracket,
          matches: testMatches,
          layout: testLayout,
        ),
      ],
    );

    blocTest<BracketBloc, BracketState>(
      'emits [LoadInProgress, LoadFailure] when bracketRepo fails',
      setUp: () {
        when(() => bracketRepository.getBracketById(bracketId)).thenAnswer(
          (_) async =>
              const Left(ServerResponseFailure(userFriendlyMessage: 'Error')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketLoadRequested(bracketId: bracketId)),
      expect: () => [
        const BracketLoadInProgress(),
        const BracketLoadFailure(userFriendlyMessage: 'Error'),
      ],
    );

    blocTest<BracketBloc, BracketState>(
      'emits [LoadInProgress, LoadFailure] when matchRepo fails',
      setUp: () {
        when(
          () => bracketRepository.getBracketById(bracketId),
        ).thenAnswer((_) async => Right(testBracket));
        when(() => matchRepository.getMatchesForBracket(bracketId)).thenAnswer(
          (_) async => const Left(
            ServerResponseFailure(userFriendlyMessage: 'Match error'),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketLoadRequested(bracketId: bracketId)),
      expect: () => [
        const BracketLoadInProgress(),
        const BracketLoadFailure(userFriendlyMessage: 'Match error'),
      ],
    );

    blocTest<BracketBloc, BracketState>(
      'matchSelected updates selectedMatchId when in LoadSuccess',
      setUp: setupSuccessfulLoad,
      build: buildBloc,
      seed: () => BracketLoadSuccess(
        bracket: testBracket,
        matches: testMatches,
        layout: testLayout,
      ),
      act: (bloc) => bloc.add(const BracketMatchSelected('m1')),
      expect: () => [
        BracketLoadSuccess(
          bracket: testBracket,
          matches: testMatches,
          layout: testLayout,
          selectedMatchId: 'm1',
        ),
      ],
    );

    blocTest<BracketBloc, BracketState>(
      'matchSelected emits nothing when not in LoadSuccess',
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketMatchSelected('m1')),
      expect: () => <BracketState>[],
    );

    blocTest<BracketBloc, BracketState>(
      'lockRequested calls LockBracketUseCase and refreshes on success',
      setUp: () {
        setupSuccessfulLoad();
        when(
          () => lockBracketUseCase(any()),
        ).thenAnswer((_) async => Right(testBracket));
      },
      build: buildBloc,
      seed: () => BracketLoadSuccess(
        bracket: testBracket,
        matches: testMatches,
        layout: testLayout,
      ),
      act: (bloc) => bloc.add(const BracketLockRequested()),
      verify: (_) {
        verify(() => lockBracketUseCase(any())).called(1);
      },
    );

    blocTest<BracketBloc, BracketState>(
      'lockRequested emits LoadFailure on use case failure',
      setUp: () {
        when(() => lockBracketUseCase(any())).thenAnswer(
          (_) async => const Left(
            ServerResponseFailure(userFriendlyMessage: 'Lock failed'),
          ),
        );
      },
      build: buildBloc,
      seed: () => BracketLoadSuccess(
        bracket: testBracket,
        matches: testMatches,
        layout: testLayout,
      ),
      act: (bloc) => bloc.add(const BracketLockRequested()),
      expect: () => [
        const BracketLockInProgress(),
        const BracketLoadFailure(userFriendlyMessage: 'Lock failed'),
      ],
    );

    blocTest<BracketBloc, BracketState>(
      'unlockRequested calls UnlockBracketUseCase',
      setUp: () {
        setupSuccessfulLoad();
        when(
          () => unlockBracketUseCase(any()),
        ).thenAnswer((_) async => Right(testBracket));
      },
      build: buildBloc,
      seed: () => BracketLoadSuccess(
        bracket: testBracket,
        matches: testMatches,
        layout: testLayout,
      ),
      act: (bloc) => bloc.add(const BracketUnlockRequested()),
      verify: (_) {
        verify(() => unlockBracketUseCase(any())).called(1);
      },
    );
  });
}

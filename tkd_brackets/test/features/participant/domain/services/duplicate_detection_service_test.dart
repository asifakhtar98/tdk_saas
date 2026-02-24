import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_detection_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match_type.dart';
import 'package:tkd_brackets/features/participant/domain/services/participant_check_data.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

void main() {
  late DuplicateDetectionService service;
  late MockDivisionRepository mockDivisionRepository;

  setUp(() {
    mockDivisionRepository = MockDivisionRepository();
    service = DuplicateDetectionService(mockDivisionRepository);
  });

  ParticipantEntity createTestParticipant({
    required String id,
    required String firstName,
    required String lastName,
    String? schoolOrDojangName,
    DateTime? dateOfBirth,
    Gender? gender,
    String? beltRank,
  }) {
    return ParticipantEntity(
      id: id,
      divisionId: 'test-division-id',
      firstName: firstName,
      lastName: lastName,
      schoolOrDojangName: schoolOrDojangName,
      beltRank: beltRank ?? 'blue',
      dateOfBirth: dateOfBirth,
      gender: gender ?? Gender.male,
      checkInStatus: ParticipantStatus.pending,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
      syncVersion: 1,
      isDeleted: false,
    );
  }

  group('checkForDuplicates with existingParticipants parameter', () {
    test('exact match detection (case-insensitive)', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'JOHN',
        lastName: 'smith',
        schoolOrDojangName: "KIM'S TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.matchType, DuplicateMatchType.exact);
        expect(matches.first.confidenceScore, 1.0);
        expect(matches.first.matchedFields['firstName'], 'John');
        expect(matches.first.matchedFields['lastName'], 'Smith');
      });
    });

    test('fuzzy match with Levenshtein distance 1 (typo)', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'Jhohn',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.matchType, DuplicateMatchType.fuzzy);
        expect(matches.first.confidenceScore, 0.9);
      });
    });

    test('fuzzy match with Levenshtein distance 2', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'Jhon',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.matchType, DuplicateMatchType.fuzzy);
        expect(matches.first.confidenceScore, 0.7);
      });
    });

    test('different dojang = low confidence', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: 'Different Dojang',
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.confidenceScore, 0.1);
      });
    });

    test('same DOB increases confidence', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
        dateOfBirth: DateTime(2010, 5, 15),
      );

      final newParticipant = ParticipantCheckData(
        firstName: 'Jon',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
        dateOfBirth: DateTime(2010, 5, 15),
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.confidenceScore, 1.0);
        expect(matches.first.matchedFields.containsKey('dateOfBirth'), true);
      });
    });

    test('multiple matches returned correctly', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final existingJonSmith = createTestParticipant(
        id: 'existing-2',
        firstName: 'Jon',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith, existingJonSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 2);
      });
    });

    test('empty existing participants = no matches', () async {
      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 0);
      });
    });

    test('null/missing DOB handling', () async {
      final existingNoDob = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
        dateOfBirth: null,
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
        dateOfBirth: null,
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingNoDob],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.confidenceScore, 1.0);
        expect(matches.first.matchedFields.containsKey('dateOfBirth'), false);
      });
    });

    test('confidence score boundary values', () async {
      final existing = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const exactMatch = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: exactMatch,
        existingParticipants: [existing],
      );

      result.fold((failure) => fail('Should not fail'), (matches) {
        final match = matches.first;
        expect(match.isHighConfidence, true);
        expect(match.isMediumConfidence, false);
        expect(match.isLowConfidence, false);
      });
    });

    test('null dojang on existing participant = low confidence', () async {
      final existingNullDojang = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: null,
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingNullDojang],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.confidenceScore, 0.1);
      });
    });

    test('both participants have null/empty dojang = low confidence', () async {
      final existingEmptyDojang = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: '',
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: '',
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingEmptyDojang],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.confidenceScore, 0.1);
      });
    });

    test('empty string dojang treated same as null', () async {
      final existing = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: '',
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: '',
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existing],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.first.confidenceScore, 0.1);
      });
    });
  });

  group('checkForDuplicatesBatch', () {
    test('batch check returns correct row number mapping', () async {
      final division = DivisionEntity(
        id: 'division-1',
        tournamentId: 'tournament-1',
        name: 'Test Division',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        ageMin: 8,
        ageMax: 12,
        weightMinKg: 30,
        weightMaxKg: 40,
        beltRankMin: 'blue',
        beltRankMax: 'blue',
        bracketFormat: BracketFormat.singleElimination,
        assignedRingNumber: 1,
        status: DivisionStatus.ready,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );

      final participantEntry = ParticipantEntry(
        id: 'existing-1',
        divisionId: 'division-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
        beltRank: 'blue',
        checkInStatus: 'pending',
        syncVersion: 1,
        isBye: false,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );

      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer((_) async => Right([division]));
      when(
        () =>
            mockDivisionRepository.getParticipantsForDivisions(['division-1']),
      ).thenAnswer((_) async => Right([participantEntry]));

      final newParticipants = [
        const ParticipantCheckData(
          firstName: 'John',
          lastName: 'Smith',
          schoolOrDojangName: "Kim's TKD",
        ),
        const ParticipantCheckData(
          firstName: 'Jane',
          lastName: 'Doe',
          schoolOrDojangName: 'Other TKD',
        ),
      ];

      final result = await service.checkForDuplicatesBatch(
        tournamentId: 'tournament-1',
        newParticipants: newParticipants,
        sourceRowNumbers: [5, 10],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.containsKey(5), true);
        expect(matches.containsKey(10), true);
        expect(matches[5]!.length, 1);
        expect(matches[10]!.length, 0);
      });
    });

    test(
      'batch check with multiple new participants and multiple existing',
      () async {
        final division = DivisionEntity(
          id: 'division-1',
          tournamentId: 'tournament-1',
          name: 'Test Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          ageMin: 8,
          ageMax: 12,
          weightMinKg: 30,
          weightMaxKg: 40,
          beltRankMin: 'blue',
          beltRankMax: 'blue',
          bracketFormat: BracketFormat.singleElimination,
          assignedRingNumber: 1,
          status: DivisionStatus.ready,
          createdAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );

        final participantEntry1 = ParticipantEntry(
          id: 'existing-1',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Smith',
          schoolOrDojangName: "Kim's TKD",
          beltRank: 'blue',
          checkInStatus: 'pending',
          syncVersion: 1,
          isBye: false,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );

        final participantEntry2 = ParticipantEntry(
          id: 'existing-2',
          divisionId: 'division-1',
          firstName: 'Jane',
          lastName: 'Doe',
          schoolOrDojangName: "Kim's TKD",
          beltRank: 'blue',
          checkInStatus: 'pending',
          syncVersion: 1,
          isBye: false,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );

        when(
          () =>
              mockDivisionRepository.getDivisionsForTournament('tournament-1'),
        ).thenAnswer((_) async => Right([division]));
        when(
          () => mockDivisionRepository.getParticipantsForDivisions([
            'division-1',
          ]),
        ).thenAnswer(
          (_) async => Right([participantEntry1, participantEntry2]),
        );

        final newParticipants = [
          const ParticipantCheckData(
            firstName: 'John',
            lastName: 'Smith',
            schoolOrDojangName: "Kim's TKD",
          ),
          const ParticipantCheckData(
            firstName: 'Jane',
            lastName: 'Doe',
            schoolOrDojangName: "Kim's TKD",
          ),
          const ParticipantCheckData(
            firstName: 'Bob',
            lastName: 'Wilson',
            schoolOrDojangName: 'Elite TKD',
          ),
        ];

        final result = await service.checkForDuplicatesBatch(
          tournamentId: 'tournament-1',
          newParticipants: newParticipants,
        );

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (matches) {
          expect(matches[1]!.length, 1);
          expect(matches[2]!.length, 1);
          expect(matches[3]!.length, 0);
        });
      },
    );
  });

  group('error handling', () {
    test(
      'checkForDuplicatesBatch returns map with empty lists on fetch failure',
      () async {
        when(
          () =>
              mockDivisionRepository.getDivisionsForTournament('tournament-1'),
        ).thenAnswer((_) async => const Left(ServerConnectionFailure()));

        final newParticipants = [
          const ParticipantCheckData(
            firstName: 'John',
            lastName: 'Smith',
            schoolOrDojangName: "Kim's TKD",
          ),
        ];

        final result = await service.checkForDuplicatesBatch(
          tournamentId: 'tournament-1',
          newParticipants: newParticipants,
        );

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (matches) {
          expect(matches.length, 1);
          expect(matches[1], isEmpty);
        });
      },
    );

    test(
      'checkForDuplicatesBatch returns map with empty lists when getParticipants fails',
      () async {
        final division = DivisionEntity(
          id: 'division-1',
          tournamentId: 'tournament-1',
          name: 'Test Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          ageMin: 8,
          ageMax: 12,
          weightMinKg: 30,
          weightMaxKg: 40,
          beltRankMin: 'blue',
          beltRankMax: 'blue',
          bracketFormat: BracketFormat.singleElimination,
          assignedRingNumber: 1,
          status: DivisionStatus.ready,
          createdAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );

        when(
          () =>
              mockDivisionRepository.getDivisionsForTournament('tournament-1'),
        ).thenAnswer((_) async => Right([division]));
        when(
          () => mockDivisionRepository.getParticipantsForDivisions([
            'division-1',
          ]),
        ).thenAnswer((_) async => const Left(ServerConnectionFailure()));

        final newParticipants = [
          const ParticipantCheckData(
            firstName: 'John',
            lastName: 'Smith',
            schoolOrDojangName: "Kim's TKD",
          ),
        ];

        final result = await service.checkForDuplicatesBatch(
          tournamentId: 'tournament-1',
          newParticipants: newParticipants,
        );

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (matches) {
          expect(matches.isEmpty, true);
        });
      },
    );
  });

  group('Levenshtein distance edge cases', () {
    test('fuzzy match with substitution (Johm vs John) - distance 1', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'Johm',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 1);
        expect(matches.first.matchType, DuplicateMatchType.fuzzy);
        expect(matches.first.confidenceScore, 0.9);
      });
    });

    test('no match when distance > 2', () async {
      final existingJohnSmith = createTestParticipant(
        id: 'existing-1',
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      const newParticipant = ParticipantCheckData(
        firstName: 'Jonathan',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
      );

      final result = await service.checkForDuplicates(
        tournamentId: 'tournament-1',
        newParticipant: newParticipant,
        existingParticipants: [existingJohnSmith],
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (matches) {
        expect(matches.length, 0);
      });
    });
  });
}

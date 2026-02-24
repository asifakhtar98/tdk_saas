import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/conflict_warning.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/services/conflict_detection_service.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  late ConflictDetectionService service;
  late MockDivisionRepository mockDivisionRepository;

  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
  });

  setUp(() {
    mockDivisionRepository = MockDivisionRepository();
    service = ConflictDetectionService(mockDivisionRepository);
  });

  DivisionEntity createDivision({
    required String id,
    required String tournamentId,
    required String name,
    int? assignedRingNumber,
    bool isDeleted = false,
  }) {
    return DivisionEntity(
      id: id,
      tournamentId: tournamentId,
      name: name,
      category: DivisionCategory.sparring,
      gender: DivisionGender.male,
      bracketFormat: BracketFormat.singleElimination,
      isCustom: true,
      status: DivisionStatus.setup,
      assignedRingNumber: assignedRingNumber,
      displayOrder: 1,
      syncVersion: 1,
      isDeleted: isDeleted,
      isDemoData: false,
      createdAtTimestamp: DateTime(2026, 1, 1),
      updatedAtTimestamp: DateTime(2026, 1, 1),
    );
  }

  ParticipantEntry createParticipant({
    required String id,
    required String divisionId,
    required String firstName,
    required String lastName,
    String? schoolOrDojangName,
    bool isDeleted = false,
  }) {
    return ParticipantEntry(
      id: id,
      divisionId: divisionId,
      firstName: firstName,
      lastName: lastName,
      schoolOrDojangName: schoolOrDojangName,
      isDeleted: isDeleted,
      isDemoData: false,
      syncVersion: 1,
      isBye: false,
      checkInStatus: 'pending',
      createdAtTimestamp: DateTime(2026, 1, 1),
      updatedAtTimestamp: DateTime(2026, 1, 1),
    );
  }

  group('ConflictDetectionService - detectConflicts', () {
    test('should return empty list when no divisions exist', () async {
      const tournamentId = 'tournament-001';

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => const Right([]));

      final result = await service.detectConflicts(tournamentId);

      result.fold(
        (failure) => fail('Expected Right'),
        (conflicts) => expect(conflicts, isEmpty),
      );
    });

    test(
      'should return empty list when divisions have no ring assignments',
      () async {
        const tournamentId = 'tournament-001';

        final divisions = [
          createDivision(
            id: 'div-001',
            tournamentId: tournamentId,
            name: 'Division A',
          ),
        ];

        when(
          () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
        ).thenAnswer((_) async => Right(divisions));
        when(
          () => mockDivisionRepository.getParticipantsForDivisions(any()),
        ).thenAnswer((_) async => const Right([]));

        final result = await service.detectConflicts(tournamentId);

        result.fold(
          (failure) => fail('Expected Right'),
          (conflicts) => expect(conflicts, isEmpty),
        );
      },
    );

    test(
      'should NOT report conflict when divisions on different rings',
      () async {
        const tournamentId = 'tournament-001';

        final divisions = [
          createDivision(
            id: 'div-001',
            tournamentId: tournamentId,
            name: 'Division A',
            assignedRingNumber: 1,
          ),
          createDivision(
            id: 'div-002',
            tournamentId: tournamentId,
            name: 'Division B',
            assignedRingNumber: 2,
          ),
        ];

        final participants = [
          createParticipant(
            id: 'part-001',
            divisionId: 'div-001',
            firstName: 'John',
            lastName: 'Doe',
          ),
          createParticipant(
            id: 'part-001',
            divisionId: 'div-002',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ];

        when(
          () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
        ).thenAnswer((_) async => Right(divisions));
        when(
          () => mockDivisionRepository.getParticipantsForDivisions(any()),
        ).thenAnswer((_) async => Right(participants));

        final result = await service.detectConflicts(tournamentId);

        result.fold(
          (failure) => fail('Expected Right'),
          (conflicts) => expect(conflicts, isEmpty),
        );
      },
    );

    test(
      'should detect same-ring conflict when same participant is in multiple divisions on same ring',
      () async {
        const tournamentId = 'tournament-001';

        final divisions = [
          createDivision(
            id: 'div-001',
            tournamentId: tournamentId,
            name: 'Division A',
            assignedRingNumber: 1,
          ),
          createDivision(
            id: 'div-002',
            tournamentId: tournamentId,
            name: 'Division B',
            assignedRingNumber: 1,
          ),
        ];

        final participants = [
          createParticipant(
            id: 'part-001',
            divisionId: 'div-001',
            firstName: 'John',
            lastName: 'Doe',
          ),
          createParticipant(
            id: 'part-001',
            divisionId: 'div-002',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ];

        when(
          () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
        ).thenAnswer((_) async => Right(divisions));
        when(
          () => mockDivisionRepository.getParticipantsForDivisions(any()),
        ).thenAnswer((_) async => Right(participants));

        final result = await service.detectConflicts(tournamentId);

        result.fold((failure) => fail('Expected Right'), (conflicts) {
          expect(conflicts.length, 1);
          expect(conflicts.first.conflictType, ConflictType.sameRing);
          expect(conflicts.first.participantId, 'part-001');
        });
      },
    );

    test('should ignore deleted divisions', () async {
      const tournamentId = 'tournament-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
          isDeleted: true,
        ),
        createDivision(
          id: 'div-002',
          tournamentId: tournamentId,
          name: 'Division B',
          assignedRingNumber: 1,
          isDeleted: false,
        ),
      ];

      final participants = [
        createParticipant(
          id: 'part-001',
          divisionId: 'div-001',
          firstName: 'John',
          lastName: 'Doe',
        ),
        createParticipant(
          id: 'part-002',
          divisionId: 'div-002',
          firstName: 'John',
          lastName: 'Doe',
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => Right(participants));

      final result = await service.detectConflicts(tournamentId);

      result.fold(
        (failure) => fail('Expected Right'),
        (conflicts) => expect(conflicts, isEmpty),
      );
    });

    test('should ignore deleted participants', () async {
      const tournamentId = 'tournament-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
        createDivision(
          id: 'div-002',
          tournamentId: tournamentId,
          name: 'Division B',
          assignedRingNumber: 1,
        ),
      ];

      final participants = [
        createParticipant(
          id: 'part-001',
          divisionId: 'div-001',
          firstName: 'John',
          lastName: 'Doe',
          isDeleted: false,
        ),
        createParticipant(
          id: 'part-002',
          divisionId: 'div-002',
          firstName: 'John',
          lastName: 'Doe',
          isDeleted: true,
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => Right(participants));

      final result = await service.detectConflicts(tournamentId);

      result.fold(
        (failure) => fail('Expected Right'),
        (conflicts) => expect(conflicts, isEmpty),
      );
    });

    test(
      'should return empty list when division query returns empty',
      () async {
        const tournamentId = 'tournament-001';

        when(
          () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
        ).thenAnswer((_) async => const Right([]));

        final result = await service.detectConflicts(tournamentId);

        result.fold(
          (failure) => fail('Expected Right'),
          (conflicts) => expect(conflicts, isEmpty),
        );
      },
    );
  });

  group('ConflictDetectionService - failure propagation', () {
    test('should return failure when division query fails', () async {
      const tournamentId = 'tournament-001';

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer(
        (_) async => const Left(
          LocalCacheAccessFailure(technicalDetails: 'Database error'),
        ),
      );

      final result = await service.detectConflicts(tournamentId);

      expect(result.isLeft(), true);
    });

    test('should return failure when participant query fails', () async {
      const tournamentId = 'tournament-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer(
        (_) async => const Left(
          LocalCacheAccessFailure(technicalDetails: 'Database error'),
        ),
      );

      final result = await service.detectConflicts(tournamentId);

      expect(result.isLeft(), true);
    });
  });

  group('ConflictDetectionService - hasConflicts', () {
    test('should return true when conflicts exist', () async {
      const tournamentId = 'tournament-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
        createDivision(
          id: 'div-002',
          tournamentId: tournamentId,
          name: 'Division B',
          assignedRingNumber: 1,
        ),
      ];

      final participants = [
        createParticipant(
          id: 'part-001',
          divisionId: 'div-001',
          firstName: 'John',
          lastName: 'Doe',
        ),
        createParticipant(
          id: 'part-001',
          divisionId: 'div-002',
          firstName: 'John',
          lastName: 'Doe',
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => Right(participants));

      final result = await service.hasConflicts(tournamentId);

      result.fold(
        (failure) => fail('Expected Right'),
        (hasConflicts) => expect(hasConflicts, true),
      );
    });

    test('should return false when no conflicts exist', () async {
      const tournamentId = 'tournament-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => const Right([]));

      final result = await service.hasConflicts(tournamentId);

      result.fold(
        (failure) => fail('Expected Right'),
        (hasConflicts) => expect(hasConflicts, false),
      );
    });
  });

  group('ConflictDetectionService - getConflictCount', () {
    test('should return correct conflict count', () async {
      const tournamentId = 'tournament-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
        createDivision(
          id: 'div-002',
          tournamentId: tournamentId,
          name: 'Division B',
          assignedRingNumber: 1,
        ),
      ];

      final participants = [
        createParticipant(
          id: 'part-001',
          divisionId: 'div-001',
          firstName: 'John',
          lastName: 'Doe',
        ),
        createParticipant(
          id: 'part-001',
          divisionId: 'div-002',
          firstName: 'John',
          lastName: 'Doe',
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => Right(participants));

      final result = await service.getConflictCount(tournamentId);

      result.fold(
        (failure) => fail('Expected Right'),
        (count) => expect(count, 1),
      );
    });
  });

  group('ConflictDetectionService - detectConflictsForParticipant', () {
    test('should return empty when participant has no conflicts', () async {
      const tournamentId = 'tournament-001';
      const participantId = 'part-001';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
      ];

      final participants = [
        createParticipant(
          id: participantId,
          divisionId: 'div-001',
          firstName: 'John',
          lastName: 'Doe',
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => Right(participants));

      final result = await service.detectConflictsForParticipant(
        tournamentId,
        participantId,
      );

      result.fold(
        (failure) => fail('Expected Right'),
        (conflicts) => expect(conflicts, isEmpty),
      );
    });

    test('should return empty when participant does not exist', () async {
      const tournamentId = 'tournament-001';
      const participantId = 'non-existent';

      final divisions = [
        createDivision(
          id: 'div-001',
          tournamentId: tournamentId,
          name: 'Division A',
          assignedRingNumber: 1,
        ),
      ];

      when(
        () => mockDivisionRepository.getDivisionsForTournament(tournamentId),
      ).thenAnswer((_) async => Right(divisions));
      when(
        () => mockDivisionRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => const Right([]));

      final result = await service.detectConflictsForParticipant(
        tournamentId,
        participantId,
      );

      result.fold(
        (failure) => fail('Expected Right'),
        (conflicts) => expect(conflicts, isEmpty),
      );
    });
  });
}

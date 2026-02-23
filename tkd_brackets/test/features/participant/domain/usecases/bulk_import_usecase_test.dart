import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_parser_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_error.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_detection_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match_type.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview_row.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_usecase.dart';

class MockCSVParserService extends Mock implements CSVParserService {}

class MockDuplicateDetectionService extends Mock
    implements DuplicateDetectionService {}

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class FakeCSVRowData extends Fake implements CSVRowData {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late BulkImportUseCase useCase;
  late MockCSVParserService mockCSVParserService;
  late MockDuplicateDetectionService mockDuplicateDetectionService;
  late MockParticipantRepository mockParticipantRepository;

  setUpAll(() {
    registerFallbackValue(FakeCSVRowData());
    registerFallbackValue(FakeParticipantEntity());
  });

  setUp(() {
    mockCSVParserService = MockCSVParserService();
    mockDuplicateDetectionService = MockDuplicateDetectionService();
    mockParticipantRepository = MockParticipantRepository();
    useCase = BulkImportUseCase(
      mockCSVParserService,
      mockDuplicateDetectionService,
      mockParticipantRepository,
    );
  });

  const validCsvContent = '''
FirstName,LastName,Dojang,Belt,Weight
John,Smith,Kim's TKD,blue,45.5
Jane,Doe,Elite TKD,red,52.0
''';

  const csvWithErrors = '''
FirstName,LastName,Dojang,Belt
John,,Kim's TKD,blue
,Smith,Elite TKD,red
''';

  CSVRowData createCSVRow({
    required int sourceRowNumber,
    String firstName = 'John',
    String lastName = 'Doe',
    String schoolOrDojangName = 'Test Dojang',
    String beltRank = 'Blue',
  }) {
    return CSVRowData(
      firstName: firstName,
      lastName: lastName,
      schoolOrDojangName: schoolOrDojangName,
      beltRank: beltRank,
      sourceRowNumber: sourceRowNumber,
    );
  }

  ParticipantEntity createParticipant({
    required String id,
    String divisionId = 'division-123',
    String firstName = 'John',
    String lastName = 'Doe',
  }) {
    return ParticipantEntity(
      id: id,
      divisionId: divisionId,
      firstName: firstName,
      lastName: lastName,
      schoolOrDojangName: 'Test Dojang',
      beltRank: 'Blue',
      checkInStatus: ParticipantStatus.pending,
      createdAtTimestamp: DateTime(2024),
      updatedAtTimestamp: DateTime(2024),
    );
  }

  group('BulkImportUseCase', () {
    group('generatePreview', () {
      test('returns preview with all valid rows when CSV is valid', () async {
        final csvResult = CSVImportResult(
          validRows: [
            createCSVRow(sourceRowNumber: 1),
            createCSVRow(
              sourceRowNumber: 2,
              firstName: 'Jane',
              lastName: 'Smith',
            ),
          ],
          errors: [],
          totalRows: 2,
        );

        when(
          () => mockCSVParserService.parseCSV(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
          ),
        ).thenAnswer((_) async => Right(csvResult));

        when(
          () => mockDuplicateDetectionService.checkForDuplicatesBatch(
            tournamentId: any(named: 'tournamentId'),
            newParticipants: any(named: 'newParticipants'),
            sourceRowNumbers: any(named: 'sourceRowNumbers'),
          ),
        ).thenAnswer((_) async => const Right({}));

        final result = await useCase.generatePreview(
          csvContent: validCsvContent,
          divisionId: 'division-123',
          tournamentId: 'tournament-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (preview) {
          expect(preview.totalRows, equals(2));
          expect(preview.validCount, equals(2));
          expect(preview.warningCount, equals(0));
          expect(preview.errorCount, equals(0));
          expect(
            preview.rows.every((r) => r.status == BulkImportRowStatus.valid),
            isTrue,
          );
        });
      });

      test(
        'returns preview with error rows when CSV has parsing errors',
        () async {
          final csvResult = CSVImportResult(
            validRows: [],
            errors: [
              const CSVRowError(
                rowNumber: 1,
                fieldName: 'lastName',
                errorMessage: 'Last name is required',
                rawValue: null,
              ),
              const CSVRowError(
                rowNumber: 2,
                fieldName: 'firstName',
                errorMessage: 'First name is required',
                rawValue: null,
              ),
            ],
            totalRows: 2,
          );

          when(
            () => mockCSVParserService.parseCSV(
              csvContent: any(named: 'csvContent'),
              divisionId: any(named: 'divisionId'),
            ),
          ).thenAnswer((_) async => Right(csvResult));

          final result = await useCase.generatePreview(
            csvContent: csvWithErrors,
            divisionId: 'division-123',
            tournamentId: 'tournament-123',
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (preview) {
            expect(preview.totalRows, equals(2));
            expect(preview.errorCount, equals(2));
            expect(preview.validCount, equals(0));
            expect(
              preview.rows.every((r) => r.status == BulkImportRowStatus.error),
              isTrue,
            );
            expect(
              preview.rows[0].validationErrors['lastName'],
              equals('Last name is required'),
            );
            expect(
              preview.rows[1].validationErrors['firstName'],
              equals('First name is required'),
            );
          });
        },
      );

      test('returns preview with warning rows when duplicates found', () async {
        final csvResult = CSVImportResult(
          validRows: [createCSVRow(sourceRowNumber: 1)],
          errors: [],
          totalRows: 1,
        );

        final existingParticipant = createParticipant(
          id: 'existing-123',
          firstName: 'John',
          lastName: 'Doe',
        );

        when(
          () => mockCSVParserService.parseCSV(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
          ),
        ).thenAnswer((_) async => Right(csvResult));

        when(
          () => mockDuplicateDetectionService.checkForDuplicatesBatch(
            tournamentId: any(named: 'tournamentId'),
            newParticipants: any(named: 'newParticipants'),
            sourceRowNumbers: any(named: 'sourceRowNumbers'),
          ),
        ).thenAnswer(
          (_) async => Right({
            1: [
              DuplicateMatch(
                existingParticipant: existingParticipant,
                matchType: DuplicateMatchType.exact,
                confidenceScore: 1.0,
                matchedFields: {'firstName': 'John', 'lastName': 'Doe'},
              ),
            ],
          }),
        );

        final result = await useCase.generatePreview(
          csvContent: validCsvContent,
          divisionId: 'division-123',
          tournamentId: 'tournament-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (preview) {
          expect(preview.totalRows, equals(1));
          expect(preview.warningCount, equals(1));
          expect(preview.validCount, equals(0));
          expect(
            preview.rows.first.status == BulkImportRowStatus.warning,
            isTrue,
          );
          expect(preview.rows.first.hasDuplicates, isTrue);
        });
      });

      test(
        'returns mixed preview with valid, warning, and error rows',
        () async {
          final csvResult = CSVImportResult(
            validRows: [
              createCSVRow(sourceRowNumber: 1),
              createCSVRow(
                sourceRowNumber: 3,
                firstName: 'Jane',
                lastName: 'Smith',
              ),
            ],
            errors: [
              const CSVRowError(
                rowNumber: 2,
                fieldName: 'lastName',
                errorMessage: 'Last name is required',
                rawValue: null,
              ),
            ],
            totalRows: 3,
          );

          final existingParticipant = createParticipant(
            id: 'existing-123',
            firstName: 'John',
            lastName: 'Doe',
          );

          when(
            () => mockCSVParserService.parseCSV(
              csvContent: any(named: 'csvContent'),
              divisionId: any(named: 'divisionId'),
            ),
          ).thenAnswer((_) async => Right(csvResult));

          when(
            () => mockDuplicateDetectionService.checkForDuplicatesBatch(
              tournamentId: any(named: 'tournamentId'),
              newParticipants: any(named: 'newParticipants'),
              sourceRowNumbers: any(named: 'sourceRowNumbers'),
            ),
          ).thenAnswer(
            (_) async => Right({
              1: [
                DuplicateMatch(
                  existingParticipant: existingParticipant,
                  matchType: DuplicateMatchType.exact,
                  confidenceScore: 1.0,
                  matchedFields: {'firstName': 'John', 'lastName': 'Doe'},
                ),
              ],
              3: <DuplicateMatch>[],
            }),
          );

          final result = await useCase.generatePreview(
            csvContent: validCsvContent,
            divisionId: 'division-123',
            tournamentId: 'tournament-123',
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (preview) {
            expect(preview.totalRows, equals(3));
            expect(preview.errorCount, equals(1));
            expect(preview.warningCount, equals(1));
            expect(preview.validCount, equals(1));
          });
        },
      );

      test('preview counts are accurate', () async {
        final csvResult = CSVImportResult(
          validRows: [
            createCSVRow(sourceRowNumber: 1),
            createCSVRow(sourceRowNumber: 2, firstName: 'Jane'),
            createCSVRow(sourceRowNumber: 3, firstName: 'Bob'),
          ],
          errors: [
            const CSVRowError(
              rowNumber: 4,
              fieldName: 'firstName',
              errorMessage: 'First name is required',
              rawValue: null,
            ),
          ],
          totalRows: 4,
        );

        when(
          () => mockCSVParserService.parseCSV(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
          ),
        ).thenAnswer((_) async => Right(csvResult));

        when(
          () => mockDuplicateDetectionService.checkForDuplicatesBatch(
            tournamentId: any(named: 'tournamentId'),
            newParticipants: any(named: 'newParticipants'),
            sourceRowNumbers: any(named: 'sourceRowNumbers'),
          ),
        ).thenAnswer(
          (_) async => Right({
            1: [
              DuplicateMatch(
                existingParticipant: createParticipant(id: 'e1'),
                matchType: DuplicateMatchType.exact,
                confidenceScore: 1.0,
                matchedFields: {},
              ),
            ],
            2: <DuplicateMatch>[],
            3: <DuplicateMatch>[],
          }),
        );

        final result = await useCase.generatePreview(
          csvContent: validCsvContent,
          divisionId: 'division-123',
          tournamentId: 'tournament-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (preview) {
          expect(preview.validCount, equals(2));
          expect(preview.warningCount, equals(1));
          expect(preview.errorCount, equals(1));
          expect(preview.totalRows, equals(4));
        });
      });

      test('preview rows are sorted by sourceRowNumber ascending', () async {
        final csvResult = CSVImportResult(
          validRows: [
            createCSVRow(sourceRowNumber: 3),
            createCSVRow(sourceRowNumber: 1),
          ],
          errors: [
            const CSVRowError(
              rowNumber: 2,
              fieldName: 'firstName',
              errorMessage: 'First name is required',
              rawValue: null,
            ),
          ],
          totalRows: 3,
        );

        when(
          () => mockCSVParserService.parseCSV(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
          ),
        ).thenAnswer((_) async => Right(csvResult));

        when(
          () => mockDuplicateDetectionService.checkForDuplicatesBatch(
            tournamentId: any(named: 'tournamentId'),
            newParticipants: any(named: 'newParticipants'),
            sourceRowNumbers: any(named: 'sourceRowNumbers'),
          ),
        ).thenAnswer((_) async => const Right({}));

        final result = await useCase.generatePreview(
          csvContent: validCsvContent,
          divisionId: 'division-123',
          tournamentId: 'tournament-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (preview) {
          expect(preview.rows[0].sourceRowNumber, equals(1));
          expect(preview.rows[1].sourceRowNumber, equals(2));
          expect(preview.rows[2].sourceRowNumber, equals(3));
        });
      });

      test('gracefully handles duplicate detection failure', () async {
        final csvResult = CSVImportResult(
          validRows: [createCSVRow(sourceRowNumber: 1)],
          errors: [],
          totalRows: 1,
        );

        when(
          () => mockCSVParserService.parseCSV(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
          ),
        ).thenAnswer((_) async => Right(csvResult));

        when(
          () => mockDuplicateDetectionService.checkForDuplicatesBatch(
            tournamentId: any(named: 'tournamentId'),
            newParticipants: any(named: 'newParticipants'),
            sourceRowNumbers: any(named: 'sourceRowNumbers'),
          ),
        ).thenAnswer(
          (_) async =>
              Left(LocalCacheAccessFailure(technicalDetails: 'DB error')),
        );

        final result = await useCase.generatePreview(
          csvContent: validCsvContent,
          divisionId: 'division-123',
          tournamentId: 'tournament-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (preview) {
          expect(preview.validCount, equals(1));
          expect(preview.warningCount, equals(0));
          expect(preview.rows.first.hasDuplicates, isFalse);
        });
      });

      test('returns ValidationFailure when CSV parsing fails', () async {
        when(
          () => mockCSVParserService.parseCSV(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ValidationFailure(userFriendlyMessage: 'Invalid CSV format'),
          ),
        );

        final result = await useCase.generatePreview(
          csvContent: 'invalid',
          divisionId: 'division-123',
          tournamentId: 'tournament-123',
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'aggregates multiple validation errors for same row into validationErrors map',
        () async {
          final csvResult = CSVImportResult(
            validRows: [],
            errors: [
              const CSVRowError(
                rowNumber: 1,
                fieldName: 'firstName',
                errorMessage: 'First name is required',
                rawValue: null,
              ),
              const CSVRowError(
                rowNumber: 1,
                fieldName: 'lastName',
                errorMessage: 'Last name is required',
                rawValue: null,
              ),
              const CSVRowError(
                rowNumber: 1,
                fieldName: 'beltRank',
                errorMessage: 'Belt rank is required',
                rawValue: null,
              ),
            ],
            totalRows: 1,
          );

          when(
            () => mockCSVParserService.parseCSV(
              csvContent: any(named: 'csvContent'),
              divisionId: any(named: 'divisionId'),
            ),
          ).thenAnswer((_) async => Right(csvResult));

          final result = await useCase.generatePreview(
            csvContent: csvWithErrors,
            divisionId: 'division-123',
            tournamentId: 'tournament-123',
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (preview) {
            expect(preview.rows.length, equals(1));
            expect(preview.rows[0].validationErrors.length, equals(3));
            expect(
              preview.rows[0].validationErrors['firstName'],
              equals('First name is required'),
            );
            expect(
              preview.rows[0].validationErrors['lastName'],
              equals('Last name is required'),
            );
            expect(
              preview.rows[0].validationErrors['beltRank'],
              equals('Belt rank is required'),
            );
          });
        },
      );
    });

    group('importSelected', () {
      test('imports all valid rows successfully', () async {
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
          BulkImportPreviewRow(
            sourceRowNumber: 2,
            rowData: createCSVRow(sourceRowNumber: 2, firstName: 'Jane'),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
        ];

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer((invocation) async {
          final participants =
              invocation.positionalArguments.first as List<ParticipantEntity>;
          return Right(participants);
        });

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (importResult) {
          expect(importResult.successCount, equals(2));
          expect(importResult.failureCount, equals(0));
          expect(importResult.errorMessages, isEmpty);
        });
      });

      test('returns zero-count result for empty selection', () async {
        final result = await useCase.importSelected(
          selectedRows: [],
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (importResult) {
          expect(importResult.successCount, equals(0));
          expect(importResult.failureCount, equals(0));
          expect(importResult.errorMessages, isEmpty);
        });
      });

      test('skips error rows and reports in errorMessages', () async {
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.error,
            duplicateMatches: [],
            validationErrors: {'firstName': 'First name is required'},
          ),
        ];

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (importResult) {
          expect(importResult.successCount, equals(0));
          expect(importResult.failureCount, equals(1));
          expect(importResult.errorMessages, hasLength(1));
          expect(importResult.errorMessages.first, contains('Row 1'));
          expect(importResult.errorMessages.first, contains('firstName'));
        });
      });

      test('imports valid rows while skipping error rows', () async {
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
          BulkImportPreviewRow(
            sourceRowNumber: 2,
            rowData: createCSVRow(sourceRowNumber: 2),
            status: BulkImportRowStatus.error,
            duplicateMatches: [],
            validationErrors: {'lastName': 'Last name is required'},
          ),
        ];

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer((invocation) async {
          final participants =
              invocation.positionalArguments.first as List<ParticipantEntity>;
          return Right(participants);
        });

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (importResult) {
          expect(importResult.successCount, equals(1));
          expect(importResult.failureCount, equals(1));
          expect(importResult.errorMessages, hasLength(1));
        });
      });

      test('imports warning rows (duplicates)', () async {
        final existingParticipant = createParticipant(id: 'existing-123');
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.warning,
            duplicateMatches: [
              DuplicateMatch(
                existingParticipant: existingParticipant,
                matchType: DuplicateMatchType.exact,
                confidenceScore: 1.0,
                matchedFields: {},
              ),
            ],
            validationErrors: {},
          ),
        ];

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer((invocation) async {
          final participants =
              invocation.positionalArguments.first as List<ParticipantEntity>;
          return Right(participants);
        });

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (importResult) {
          expect(importResult.successCount, equals(1));
        });
      });

      test('returns LocalCacheWriteFailure when batch insert fails', () async {
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
        ];

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer(
          (_) async => const Left(
            LocalCacheWriteFailure(userFriendlyMessage: 'Failed to save'),
          ),
        );

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LocalCacheWriteFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('generates UUID for each participant', () async {
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
        ];

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer((invocation) async {
          final participants =
              invocation.positionalArguments.first as List<ParticipantEntity>;
          return Right(participants);
        });

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        final captured =
            verify(
                  () => mockParticipantRepository.createParticipantsBatch(
                    captureAny(),
                  ),
                ).captured.single
                as List<ParticipantEntity>;

        expect(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ).hasMatch(captured.first.id),
          isTrue,
        );
      });

      test('sets correct default values for new participants', () async {
        final previewRows = [
          BulkImportPreviewRow(
            sourceRowNumber: 1,
            rowData: createCSVRow(sourceRowNumber: 1),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
        ];

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer((invocation) async {
          final participants =
              invocation.positionalArguments.first as List<ParticipantEntity>;
          return Right(participants);
        });

        await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        final captured =
            verify(
                  () => mockParticipantRepository.createParticipantsBatch(
                    captureAny(),
                  ),
                ).captured.single
                as List<ParticipantEntity>;

        final participant = captured.first;
        expect(participant.divisionId, equals('division-123'));
        expect(participant.checkInStatus, equals(ParticipantStatus.pending));
        expect(participant.syncVersion, equals(1));
        expect(participant.isDeleted, isFalse);
      });
    });

    group('batch insert in repository', () {
      test(
        'calls createParticipantsBatch with correct participant count',
        () async {
          final previewRows = [
            BulkImportPreviewRow(
              sourceRowNumber: 1,
              rowData: createCSVRow(sourceRowNumber: 1),
              status: BulkImportRowStatus.valid,
              duplicateMatches: [],
              validationErrors: {},
            ),
            BulkImportPreviewRow(
              sourceRowNumber: 2,
              rowData: createCSVRow(sourceRowNumber: 2, firstName: 'Jane'),
              status: BulkImportRowStatus.valid,
              duplicateMatches: [],
              validationErrors: {},
            ),
            BulkImportPreviewRow(
              sourceRowNumber: 3,
              rowData: createCSVRow(sourceRowNumber: 3, firstName: 'Bob'),
              status: BulkImportRowStatus.valid,
              duplicateMatches: [],
              validationErrors: {},
            ),
          ];

          when(
            () => mockParticipantRepository.createParticipantsBatch(any()),
          ).thenAnswer((invocation) async {
            final participants =
                invocation.positionalArguments.first as List<ParticipantEntity>;
            return Right(participants);
          });

          await useCase.importSelected(
            selectedRows: previewRows,
            divisionId: 'division-123',
          );

          final captured =
              verify(
                    () => mockParticipantRepository.createParticipantsBatch(
                      captureAny(),
                    ),
                  ).captured.single
                  as List<ParticipantEntity>;

          expect(captured.length, equals(3));
        },
      );

      test('handles large batch import (50+ rows)', () async {
        final previewRows = List.generate(
          50,
          (i) => BulkImportPreviewRow(
            sourceRowNumber: i + 1,
            rowData: createCSVRow(sourceRowNumber: i + 1, firstName: 'User$i'),
            status: BulkImportRowStatus.valid,
            duplicateMatches: [],
            validationErrors: {},
          ),
        );

        when(
          () => mockParticipantRepository.createParticipantsBatch(any()),
        ).thenAnswer((invocation) async {
          final participants =
              invocation.positionalArguments.first as List<ParticipantEntity>;
          return Right(participants);
        });

        final result = await useCase.importSelected(
          selectedRows: previewRows,
          divisionId: 'division-123',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (importResult) {
          expect(importResult.successCount, equals(50));
          expect(importResult.failureCount, equals(0));
        });

        final captured =
            verify(
                  () => mockParticipantRepository.createParticipantsBatch(
                    captureAny(),
                  ),
                ).captured.single
                as List<ParticipantEntity>;

        expect(captured.length, equals(50));
      });
    });
  });
}

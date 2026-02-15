import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_use_case.dart';

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockErrorReportingService extends Mock implements ErrorReportingService {}

class FakeOrganizationEntity extends Fake implements OrganizationEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late CreateOrganizationUseCase useCase;
  late MockOrganizationRepository mockOrganizationRepository;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;
  late MockErrorReportingService mockErrorReportingService;

  setUpAll(() {
    registerFallbackValue(FakeOrganizationEntity());
    registerFallbackValue(FakeUserEntity());
  });

  // Test user fixture
  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: '',
    role: UserRole.viewer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockOrganizationRepository = MockOrganizationRepository();
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
    mockErrorReportingService = MockErrorReportingService();

    // Default: Authenticated user matches params.userId
    when(
      () => mockAuthRepository.getCurrentAuthenticatedUser(),
    ).thenAnswer((_) async => Right(testUser));

    useCase = CreateOrganizationUseCase(
      mockOrganizationRepository,
      mockUserRepository,
      mockAuthRepository,
      mockErrorReportingService,
    );
  });

  group('CreateOrganizationUseCase', () {
    group('security check', () {
      test('returns AuthFailure when authenticated user id mismatch', () async {
        final otherUser = testUser.copyWith(id: 'other-id');
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(otherUser));

        final result = await useCase(
          const CreateOrganizationParams(
            name: 'New Org',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        
        // Check for specific failure type
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected Left'),
        );

        verify(() => mockAuthRepository.getCurrentAuthenticatedUser()).called(1);
        verifyZeroInteractions(mockOrganizationRepository);
        verifyZeroInteractions(mockUserRepository);
      });

      test('returns Failure if getCurrentAuthenticatedUser fails', () async {
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => const Left(AuthenticationFailure(userFriendlyMessage: 'Error')),
        );

        final result = await useCase(
          const CreateOrganizationParams(
            name: 'New Org',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        verify(() => mockAuthRepository.getCurrentAuthenticatedUser()).called(1);
        verifyZeroInteractions(mockOrganizationRepository);
      });
    });

    group('name validation', () {
      test('returns InputValidationFailure for empty name', () async {
        final result = await useCase(
          const CreateOrganizationParams(name: '', userId: 'user-123'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockOrganizationRepository);
        verifyZeroInteractions(mockUserRepository);
      });

      test('returns InputValidationFailure for whitespace-only name', () async {
        final result = await useCase(
          const CreateOrganizationParams(name: '   ', userId: 'user-123'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockOrganizationRepository);
      });

      test('returns InputValidationFailure for name exceeding 255 characters', () async {
        final longName = 'A' * 256;
        final result = await useCase(
          CreateOrganizationParams(name: longName, userId: 'user-123'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockOrganizationRepository);
      });

      test('accepts name with exactly 255 characters', () async {
        final exactName = 'A' * 255;
        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer(
          (_) async => Right(
            OrganizationEntity(
              id: 'org-1',
              name: exactName,
              slug: 'a' * 255,
              subscriptionTier: SubscriptionTier.free,
              subscriptionStatus: SubscriptionStatus.active,
              maxTournamentsPerMonth: 2,
              maxActiveBrackets: 3,
              maxParticipantsPerBracket: 32,
              maxParticipantsPerTournament: 100,
              maxScorers: 2,
              isActive: true,
              createdAt: DateTime(2024),
            ),
          ),
        );
        when(
          () => mockUserRepository.getUserById('user-123'),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer((_) async => Right(testUser));

        final result = await useCase(
          CreateOrganizationParams(name: exactName, userId: 'user-123'),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockOrganizationRepository.createOrganization(any()),
        ).called(1);
      });

      test('trims whitespace from name before processing', () async {
        late OrganizationEntity capturedOrg;
        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer((invocation) async {
          capturedOrg =
              invocation.positionalArguments.first as OrganizationEntity;
          return Right(capturedOrg);
        });
        when(
          () => mockUserRepository.getUserById('user-123'),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer((_) async => Right(testUser));

        await useCase(
          const CreateOrganizationParams(
            name: '  Dragon Dojang  ',
            userId: 'user-123',
          ),
        );

        expect(capturedOrg.name, 'Dragon Dojang');
      });

      test('returns InputValidationFailure for name with no alphanumeric characters', () async {
        final result = await useCase(
          const CreateOrganizationParams(name: '!!!@#\$%', userId: 'user-123'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockOrganizationRepository);
      });
    });

    group('slug generation', () {
      test('generates lowercase hyphenated slug', () {
        expect(
          CreateOrganizationUseCase.generateSlug('Dragon Martial Arts'),
          'dragon-martial-arts',
        );
      });

      test('removes special characters', () {
        expect(
          CreateOrganizationUseCase.generateSlug("Dragon's Dojang!"),
          'dragons-dojang',
        );
      });

      test('collapses consecutive hyphens', () {
        expect(
          CreateOrganizationUseCase.generateSlug('Dragon  --  Dojang'),
          'dragon-dojang',
        );
      });

      test('trims leading and trailing hyphens', () {
        expect(
          CreateOrganizationUseCase.generateSlug('-Dragon Dojang-'),
          'dragon-dojang',
        );
      });

      test('handles underscores by converting to hyphens', () {
        expect(
          CreateOrganizationUseCase.generateSlug('Dragon_Dojang'),
          'dragon-dojang',
        );
      });

      test('handles unicode/accents by removing', () {
        expect(
          CreateOrganizationUseCase.generateSlug('Café Dojang'),
          'caf-dojang',
        );
      });

      test('handles single word', () {
        expect(CreateOrganizationUseCase.generateSlug('DRAGONS'), 'dragons');
      });

      test('handles mixed whitespace', () {
        expect(
          CreateOrganizationUseCase.generateSlug("Dragon\tDojang\nAcademy"),
          'dragon-dojang-academy',
        );
      });

      test('returns empty string for all-special-characters', () {
        expect(CreateOrganizationUseCase.generateSlug('!!!@#\$%'), '');
      });
    });

    group('successful organization creation', () {
      test('creates organization and updates user role to owner', () async {
        late OrganizationEntity capturedOrg;
        late UserEntity capturedUser;

        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer((invocation) async {
          capturedOrg =
              invocation.positionalArguments.first as OrganizationEntity;
          return Right(capturedOrg);
        });

        when(
          () => mockUserRepository.getUserById('user-123'),
        ).thenAnswer((_) async => Right(testUser));

        when(() => mockUserRepository.updateUser(any())).thenAnswer((
          invocation,
        ) async {
          capturedUser = invocation.positionalArguments.first as UserEntity;
          return Right(capturedUser);
        });

        final result = await useCase(
          const CreateOrganizationParams(
            name: 'Dragon Martial Arts',
            userId: 'user-123',
          ),
        );

        // Verify organization was created correctly
        expect(result.isRight(), isTrue);
        
        result.fold((_) => fail('Expected Right'), (org) {
          expect(org.name, 'Dragon Martial Arts');
          expect(org.slug, 'dragon-martial-arts');
          expect(org.subscriptionTier, SubscriptionTier.free);
          expect(org.subscriptionStatus, SubscriptionStatus.active);
          expect(org.isActive, isTrue);
          expect(org.maxTournamentsPerMonth, 2);
          expect(org.maxActiveBrackets, 3);
          expect(org.maxParticipantsPerBracket, 32);
          expect(org.maxParticipantsPerTournament, 100);
          expect(org.maxScorers, 2);
          expect(org.id, isNotEmpty);
        });

        // Verify user was updated with owner role
        expect(capturedUser.organizationId, capturedOrg.id);
        expect(capturedUser.role, UserRole.owner);

        // Verify call order
        verifyInOrder([
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
          () => mockOrganizationRepository.createOrganization(any()),
          () => mockUserRepository.getUserById('user-123'),
          () => mockUserRepository.updateUser(any()),
        ]);
      });

      test('generates a valid UUID for the organization ID', () async {
        late OrganizationEntity capturedOrg;

        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer((invocation) async {
          capturedOrg =
              invocation.positionalArguments.first as OrganizationEntity;
          return Right(capturedOrg);
        });
        when(
          () => mockUserRepository.getUserById('user-123'),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer((_) async => Right(testUser));

        await useCase(
          const CreateOrganizationParams(name: 'Test Org', userId: 'user-123'),
        );

        // UUID v4 format:
        // 8-4-4-4-12 hex chars
        expect(
          capturedOrg.id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-'
              r'4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
              r'[0-9a-f]{12}$',
            ),
          ),
        );
      });
    });

    group('error handling', () {
      final testOrg = OrganizationEntity(
        id: 'org-1',
        name: 'Dragon Dojang',
        slug: 'dragon-dojang',
        subscriptionTier: SubscriptionTier.free,
        subscriptionStatus: SubscriptionStatus.active,
        maxTournamentsPerMonth: 2,
        maxActiveBrackets: 3,
        maxParticipantsPerBracket: 32,
        maxParticipantsPerTournament: 100,
        maxScorers: 2,
        isActive: true,
        createdAt: DateTime(2024),
      );

      test('returns failure when organization repository fails', () async {
        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer(
          (_) async => const Left(
            LocalCacheWriteFailure(
              userFriendlyMessage: 'Failed to create organization.',
            ),
          ),
        );

        final result = await useCase(
          const CreateOrganizationParams(
            name: 'Dragon Dojang',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        
        result.fold(
          (failure) => expect(failure, isA<LocalCacheWriteFailure>()),
          (_) => fail('Expected Left'),
        );
        // User should NOT be updated if org creation failed
        verifyNever(() => mockUserRepository.getUserById(any()));
        verifyNever(() => mockUserRepository.updateUser(any()));
      });

      test('returns failure when getUserById fails after org creation', () async {
        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer((_) async => Right(testOrg));
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => const Left(
            LocalCacheAccessFailure(userFriendlyMessage: 'User not found.'),
          ),
        );

        final result = await useCase(
          const CreateOrganizationParams(
            name: 'Dragon Dojang',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LocalCacheAccessFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(() => mockUserRepository.updateUser(any()));
        verifyZeroInteractions(mockErrorReportingService);
      });

      test('returns failure and reports critical error when updateUser fails after org creation', () async {
        when(
          () => mockOrganizationRepository.createOrganization(any()),
        ).thenAnswer((_) async => Right(testOrg));
        when(
          () => mockUserRepository.getUserById('user-123'),
        ).thenAnswer((_) async => Right(testUser));
        
        const expectedFailure = LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to update user.',
        );
        when(() => mockUserRepository.updateUser(any())).thenAnswer(
          (_) async => const Left(expectedFailure),
        );

        final result = await useCase(
          const CreateOrganizationParams(
            name: 'Dragon Dojang',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LocalCacheWriteFailure>()),
          (_) => fail('Expected Left'),
        );

        // Verify ErrorReportingService was called
        verify(
          () => mockErrorReportingService.reportError(
            any(
              that: contains(
                'CRITICAL DATA INCONSISTENCY: Organization created but user update failed',
              ),
            ),
            error: expectedFailure,
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
        
        verify(
           () => mockErrorReportingService.addBreadcrumb(
             message: any(named: 'message'),
             category: any(named: 'category'),
             data: any(named: 'data'),
           ),
        ).called(1);
      });
    });
  });
}

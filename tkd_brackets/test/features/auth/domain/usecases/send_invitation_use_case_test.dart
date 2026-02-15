import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_use_case.dart';

class MockInvitationRepository extends Mock implements InvitationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeInvitationEntity extends Fake implements InvitationEntity {}

void main() {
  late SendInvitationUseCase useCase;
  late MockInvitationRepository mockInvitationRepository;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;

  final testOwner = UserEntity(
    id: 'owner-123',
    email: 'owner@test.com',
    displayName: 'Owner',
    organizationId: 'org-1',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(FakeInvitationEntity());
  });

  setUp(() {
    mockInvitationRepository = MockInvitationRepository();
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();

    when(
      () => mockAuthRepository.getCurrentAuthenticatedUser(),
    ).thenAnswer((_) async => Right(testOwner));
    when(
      () => mockUserRepository.getUserById('owner-123'),
    ).thenAnswer((_) async => Right(testOwner));

    useCase = SendInvitationUseCase(
      mockInvitationRepository,
      mockUserRepository,
      mockAuthRepository,
    );
  });

  group('SendInvitationUseCase', () {
    group('security checks', () {
      test('returns AuthenticationFailure when user ID mismatch', () async {
        final otherUser = testOwner.copyWith(id: 'other-id');
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(otherUser));

        final result = await useCase(
          const SendInvitationParams(
            email: 'invite@test.com',
            organizationId: 'org-1',
            role: UserRole.admin,
            invitedByUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<AuthenticationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns AuthorizationFailure when non-owner tries to invite',
        () async {
          final scorer = testOwner.copyWith(role: UserRole.scorer);
          when(
            () => mockUserRepository.getUserById('owner-123'),
          ).thenAnswer((_) async => Right(scorer));

          final result = await useCase(
            const SendInvitationParams(
              email: 'invite@test.com',
              organizationId: 'org-1',
              role: UserRole.admin,
              invitedByUserId: 'owner-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('returns Failure if getCurrentAuthenticatedUser fails', () async {
        when(() => mockAuthRepository.getCurrentAuthenticatedUser()).thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(userFriendlyMessage: 'Auth error'),
          ),
        );

        final result = await useCase(
          const SendInvitationParams(
            email: 'invite@test.com',
            organizationId: 'org-1',
            role: UserRole.admin,
            invitedByUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        verifyZeroInteractions(mockInvitationRepository);
      });
    });

    group('validation', () {
      test('returns InputValidationFailure for empty email', () async {
        final result = await useCase(
          const SendInvitationParams(
            email: '',
            organizationId: 'org-1',
            role: UserRole.admin,
            invitedByUserId: 'owner-123',
          ),
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for invalid email format', () async {
        final result = await useCase(
          const SendInvitationParams(
            email: 'not-an-email',
            organizationId: 'org-1',
            role: UserRole.admin,
            invitedByUserId: 'owner-123',
          ),
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure when role is owner', () async {
        final result = await useCase(
          const SendInvitationParams(
            email: 'invite@test.com',
            organizationId: 'org-1',
            role: UserRole.owner,
            invitedByUserId: 'owner-123',
          ),
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns InputValidationFailure for duplicate pending invitation',
        () async {
          when(
            () => mockInvitationRepository.getExistingPendingInvitation(
              'invite@test.com',
              'org-1',
            ),
          ).thenAnswer(
            (_) async => Right(
              InvitationEntity(
                id: 'inv-1',
                organizationId: 'org-1',
                email: 'invite@test.com',
                role: UserRole.admin,
                invitedBy: 'owner-123',
                status: InvitationStatus.pending,
                token: 'token-1',
                expiresAt: DateTime.now().add(const Duration(days: 7)),
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ),
          );

          final result = await useCase(
            const SendInvitationParams(
              email: 'invite@test.com',
              organizationId: 'org-1',
              role: UserRole.admin,
              invitedByUserId: 'owner-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<InputValidationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('successful invitation', () {
      test('creates invitation with correct fields', () async {
        when(
          () => mockInvitationRepository.getExistingPendingInvitation(
            'invite@test.com',
            'org-1',
          ),
        ).thenAnswer((_) async => const Right(null));

        late InvitationEntity captured;
        when(() => mockInvitationRepository.createInvitation(any())).thenAnswer(
          (inv) async {
            captured = inv.positionalArguments.first as InvitationEntity;
            return Right(captured);
          },
        );

        final result = await useCase(
          const SendInvitationParams(
            email: 'INVITE@TEST.COM',
            organizationId: 'org-1',
            role: UserRole.admin,
            invitedByUserId: 'owner-123',
          ),
        );

        expect(result.isRight(), isTrue);
        expect(captured.email, 'invite@test.com'); // lowercased
        expect(captured.role, UserRole.admin);
        expect(captured.organizationId, 'org-1');
        expect(captured.invitedBy, 'owner-123');
        expect(captured.status, InvitationStatus.pending);
        expect(captured.id, isNotEmpty);
        expect(captured.token, isNotEmpty);
        expect(captured.expiresAt.isAfter(DateTime.now()), isTrue);
      });
    });
  });
}

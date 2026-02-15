import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/accept_invitation_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/accept_invitation_use_case.dart';

class MockInvitationRepository extends Mock implements InvitationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeInvitationEntity extends Fake implements InvitationEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late AcceptInvitationUseCase useCase;
  late MockInvitationRepository mockInvitationRepository;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;

  final testUser = UserEntity(
    id: 'user-123',
    email: 'invitee@test.com',
    displayName: 'Invitee',
    organizationId: '',
    role: UserRole.viewer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final testInvitation = InvitationEntity(
    id: 'inv-1',
    organizationId: 'org-1',
    email: 'invitee@test.com',
    role: UserRole.admin,
    invitedBy: 'owner-123',
    status: InvitationStatus.pending,
    token: 'valid-token',
    expiresAt: DateTime.now().add(const Duration(days: 7)),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(FakeInvitationEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockInvitationRepository = MockInvitationRepository();
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();

    when(
      () => mockAuthRepository.getCurrentAuthenticatedUser(),
    ).thenAnswer((_) async => Right(testUser));

    useCase = AcceptInvitationUseCase(
      mockInvitationRepository,
      mockUserRepository,
      mockAuthRepository,
    );
  });

  group('AcceptInvitationUseCase', () {
    group('security checks', () {
      test('returns AuthenticationFailure when user ID mismatch', () async {
        final otherUser = testUser.copyWith(id: 'other-id');
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(otherUser));

        final result = await useCase(
          const AcceptInvitationParams(
            token: 'valid-token',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<AuthenticationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockInvitationRepository);
      });

      test('returns Failure if getCurrentAuthenticatedUser fails', () async {
        when(() => mockAuthRepository.getCurrentAuthenticatedUser()).thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(userFriendlyMessage: 'Auth error'),
          ),
        );

        final result = await useCase(
          const AcceptInvitationParams(
            token: 'valid-token',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        verifyZeroInteractions(mockInvitationRepository);
      });
    });

    group('invitation validation', () {
      test('returns failure when invitation not found', () async {
        when(
          () => mockInvitationRepository.getInvitationByToken('invalid'),
        ).thenAnswer(
          (_) async => const Left(
            LocalCacheAccessFailure(
              userFriendlyMessage: 'Invitation not found.',
            ),
          ),
        );

        final result = await useCase(
          const AcceptInvitationParams(token: 'invalid', userId: 'user-123'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocalCacheAccessFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure when status != pending', () async {
        final acceptedInvitation = testInvitation.copyWith(
          status: InvitationStatus.accepted,
        );
        when(
          () => mockInvitationRepository.getInvitationByToken('valid-token'),
        ).thenAnswer((_) async => Right(acceptedInvitation));

        final result = await useCase(
          const AcceptInvitationParams(
            token: 'valid-token',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold((f) {
          expect(f, isA<InputValidationFailure>());
          expect(
            (f as InputValidationFailure).userFriendlyMessage,
            contains('no longer valid'),
          );
        }, (_) => fail('Expected Left'));
        verifyZeroInteractions(mockUserRepository);
      });

      test(
        'returns InputValidationFailure and marks as expired when past expiresAt',
        () async {
          final expiredInvitation = testInvitation.copyWith(
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          );
          when(
            () => mockInvitationRepository.getInvitationByToken('valid-token'),
          ).thenAnswer((_) async => Right(expiredInvitation));
          when(
            () => mockInvitationRepository.updateInvitation(any()),
          ).thenAnswer((inv) async {
            final updated = inv.positionalArguments.first as InvitationEntity;
            return Right(updated);
          });

          final result = await useCase(
            const AcceptInvitationParams(
              token: 'valid-token',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold((f) {
            expect(f, isA<InputValidationFailure>());
            expect(
              (f as InputValidationFailure).userFriendlyMessage,
              contains('expired'),
            );
          }, (_) => fail('Expected Left'));

          verify(
            () => mockInvitationRepository.updateInvitation(
              any(
                that: predicate<InvitationEntity>(
                  (inv) => inv.status == InvitationStatus.expired,
                ),
              ),
            ),
          ).called(1);
          verifyZeroInteractions(mockUserRepository);
        },
      );
    });

    group('successful acceptance', () {
      test(
        'updates user organizationId and role, marks invitation accepted',
        () async {
          late UserEntity capturedUser;
          late InvitationEntity capturedInvitation;

          when(
            () => mockInvitationRepository.getInvitationByToken('valid-token'),
          ).thenAnswer((_) async => Right(testInvitation));
          when(
            () => mockUserRepository.getUserById('user-123'),
          ).thenAnswer((_) async => Right(testUser));
          when(() => mockUserRepository.updateUser(any())).thenAnswer((
            inv,
          ) async {
            capturedUser = inv.positionalArguments.first as UserEntity;
            return Right(capturedUser);
          });
          when(
            () => mockInvitationRepository.updateInvitation(any()),
          ).thenAnswer((inv) async {
            capturedInvitation =
                inv.positionalArguments.first as InvitationEntity;
            return Right(capturedInvitation);
          });

          final result = await useCase(
            const AcceptInvitationParams(
              token: 'valid-token',
              userId: 'user-123',
            ),
          );

          expect(result.isRight(), isTrue);

          expect(capturedUser.organizationId, 'org-1');
          expect(capturedUser.role, UserRole.admin);

          expect(capturedInvitation.status, InvitationStatus.accepted);

          verifyInOrder([
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
            () => mockInvitationRepository.getInvitationByToken('valid-token'),
            () => mockUserRepository.getUserById('user-123'),
            () => mockUserRepository.updateUser(any()),
            () => mockInvitationRepository.updateInvitation(any()),
          ]);
        },
      );
    });

    group('error handling', () {
      test('returns failure when getUserById fails', () async {
        when(
          () => mockInvitationRepository.getInvitationByToken('valid-token'),
        ).thenAnswer((_) async => Right(testInvitation));
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => const Left(
            LocalCacheAccessFailure(userFriendlyMessage: 'User not found.'),
          ),
        );

        final result = await useCase(
          const AcceptInvitationParams(
            token: 'valid-token',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocalCacheAccessFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(() => mockUserRepository.updateUser(any()));
        verifyNever(() => mockInvitationRepository.updateInvitation(any()));
      });

      test('returns failure when updateUser fails', () async {
        when(
          () => mockInvitationRepository.getInvitationByToken('valid-token'),
        ).thenAnswer((_) async => Right(testInvitation));
        when(
          () => mockUserRepository.getUserById('user-123'),
        ).thenAnswer((_) async => Right(testUser));
        when(() => mockUserRepository.updateUser(any())).thenAnswer(
          (_) async => const Left(
            LocalCacheWriteFailure(
              userFriendlyMessage: 'Failed to update user.',
            ),
          ),
        );

        final result = await useCase(
          const AcceptInvitationParams(
            token: 'valid-token',
            userId: 'user-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocalCacheWriteFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(() => mockInvitationRepository.updateInvitation(any()));
      });
    });
  });
}

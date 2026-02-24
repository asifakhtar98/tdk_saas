import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_out_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignOutUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockAuthRepository);
  });

  group('SignOutUseCase', () {
    test('returns Right(unit) on successful sign out', () async {
      when(
        () => mockAuthRepository.signOut(),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const NoParams());

      expect(result.isRight(), isTrue);
      verify(() => mockAuthRepository.signOut()).called(1);
    });

    test('returns Left(SignOutFailure) when sign out '
        'fails', () async {
      when(() => mockAuthRepository.signOut()).thenAnswer(
        (_) async =>
            const Left(SignOutFailure(technicalDetails: 'Sign out failed')),
      );

      final result = await useCase(const NoParams());

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<SignOutFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}

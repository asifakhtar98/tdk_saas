import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

class _TestUseCase extends UseCase<String, String> {
  _TestUseCase({required this.shouldSucceed});

  final bool shouldSucceed;

  @override
  Future<Either<Failure, String>> call(String params) async {
    return shouldSucceed
        ? Right('Result: $params')
        : const Left(ServerConnectionFailure());
  }
}

void main() {
  group('UseCase', () {
    test('returns Right on success', () async {
      final result = await _TestUseCase(shouldSucceed: true)('input');
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ''), 'Result: input');
    });

    test('returns Left on failure', () async {
      final result = await _TestUseCase(shouldSucceed: false)('input');
      expect(result.isLeft(), isTrue);
    });
  });

  test('NoParams can be instantiated', () {
    expect(const NoParams(), isNotNull);
  });
}

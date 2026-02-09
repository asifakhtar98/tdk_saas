import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('can be instantiated', () {
      final user = UserEntity(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-1',
        role: UserRole.viewer,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.viewer);
    });

    test('equality works correctly', () {
      final user1 = UserEntity(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-1',
        role: UserRole.viewer,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final user2 = UserEntity(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-1',
        role: UserRole.viewer,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user1, equals(user2));
    });

    test('different users are not equal', () {
      final user1 = UserEntity(
        id: 'test-id-1',
        email: 'test1@example.com',
        displayName: 'Test User 1',
        organizationId: 'org-1',
        role: UserRole.viewer,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final user2 = UserEntity(
        id: 'test-id-2',
        email: 'test2@example.com',
        displayName: 'Test User 2',
        organizationId: 'org-1',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user1, isNot(equals(user2)));
    });

    test('copyWith creates new instance with updated fields', () {
      final user = UserEntity(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-1',
        role: UserRole.viewer,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final updatedUser = user.copyWith(displayName: 'Updated Name');

      expect(updatedUser.id, user.id);
      expect(updatedUser.displayName, 'Updated Name');
      expect(updatedUser.email, user.email);
    });
  });

  group('UserRole', () {
    test('fromString parses valid roles', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('scorer'), UserRole.scorer);
      expect(UserRole.fromString('viewer'), UserRole.viewer);
    });

    test('fromString defaults to viewer for invalid roles', () {
      expect(UserRole.fromString('invalid'), UserRole.viewer);
      expect(UserRole.fromString(''), UserRole.viewer);
    });

    test('value getter returns correct string', () {
      expect(UserRole.owner.value, 'owner');
      expect(UserRole.admin.value, 'admin');
      expect(UserRole.scorer.value, 'scorer');
      expect(UserRole.viewer.value, 'viewer');
    });
  });
}

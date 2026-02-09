import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    final testModel = UserModel(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      organizationId: 'org-1',
      role: 'admin',
      isActive: true,
      createdAtTimestamp: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 15),
      syncVersion: 1,
      isDeleted: false,
      isDemoData: false,
      lastSignInAtTimestamp: DateTime(2024, 1, 15),
    );

    test('converts to entity correctly', () {
      final entity = testModel.convertToEntity();

      expect(entity.id, 'test-id');
      expect(entity.email, 'test@example.com');
      expect(entity.role, UserRole.admin);
      expect(entity.lastSignInAt, DateTime(2024, 1, 15));
    });

    test('converts from entity correctly', () {
      final entity = UserEntity(
        id: 'entity-id',
        email: 'entity@example.com',
        displayName: 'Entity User',
        organizationId: 'org-2',
        role: UserRole.scorer,
        isActive: true,
        createdAt: DateTime(2024, 2, 1),
      );

      final model = UserModel.convertFromEntity(entity);

      expect(model.id, 'entity-id');
      expect(model.role, 'scorer');
      expect(model.syncVersion, 1);
    });

    test('fromJson parses correctly', () {
      final json = <String, dynamic>{
        'id': 'json-id',
        'email': 'json@example.com',
        'display_name': 'JSON User',
        'organization_id': 'org-json',
        'role': 'owner',
        'is_active': true,
        'created_at_timestamp': '2024-01-01T00:00:00.000Z',
        'updated_at_timestamp': '2024-01-15T00:00:00.000Z',
        'sync_version': 2,
        'is_deleted': false,
        'is_demo_data': false,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'json-id');
      expect(model.displayName, 'JSON User');
      expect(model.role, 'owner');
      expect(model.syncVersion, 2);
    });

    test('toJson produces snake_case keys', () {
      final json = testModel.toJson();

      expect(json['id'], 'test-id');
      expect(json['display_name'], 'Test User');
      expect(json['organization_id'], 'org-1');
      expect(json['is_active'], true);
      expect(json['sync_version'], 1);
    });

    test('convertFromEntity with custom sync version', () {
      final entity = UserEntity(
        id: 'entity-id',
        email: 'entity@example.com',
        displayName: 'Entity User',
        organizationId: 'org-2',
        role: UserRole.scorer,
        isActive: true,
        createdAt: DateTime(2024, 2, 1),
      );

      final model = UserModel.convertFromEntity(entity, syncVersion: 5);

      expect(model.syncVersion, 5);
    });

    test('equality works correctly (freezed)', () {
      final model1 = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-1',
        role: 'admin',
        isActive: true,
        createdAtTimestamp: DateTime(2024, 1, 1),
        updatedAtTimestamp: DateTime(2024, 1, 15),
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
      );

      final model2 = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-1',
        role: 'admin',
        isActive: true,
        createdAtTimestamp: DateTime(2024, 1, 1),
        updatedAtTimestamp: DateTime(2024, 1, 15),
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
      );

      expect(model1, equals(model2));
    });

    test('copyWith creates new instance with updated fields', () {
      final updatedModel = testModel.copyWith(displayName: 'Updated Name');

      expect(updatedModel.id, testModel.id);
      expect(updatedModel.displayName, 'Updated Name');
      expect(updatedModel.email, testModel.email);
    });
  });
}

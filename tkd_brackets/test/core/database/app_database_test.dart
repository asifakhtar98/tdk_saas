import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Use in-memory SQLite for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase', () {
    test('should create database successfully', () {
      expect(database, isNotNull);
      expect(database.schemaVersion, 2);
    });

    test('should have organizations table', () {
      expect(database.organizations, isNotNull);
    });

    test('should have users table', () {
      expect(database.users, isNotNull);
    });
  });

  group('Organizations CRUD', () {
    test('should insert and retrieve organization', () async {
      const orgId = 'test-org-id-123';

      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: orgId,
          name: 'Test Dojang',
          slug: 'test-dojang',
        ),
      );

      final result = await database.getOrganizationById(orgId);

      expect(result, isNotNull);
      expect(result!.name, 'Test Dojang');
      expect(result.slug, 'test-dojang');
      expect(result.subscriptionTier, 'free');
      expect(result.isDeleted, false);
      expect(result.isDemoData, false);
    });

    test('should return null for non-existent organization', () async {
      final result = await database.getOrganizationById('non-existent');
      expect(result, isNull);
    });

    test('should get only active organizations', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-1',
          name: 'Active Org',
          slug: 'active-org',
        ),
      );

      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-2',
          name: 'Deleted Org',
          slug: 'deleted-org',
          isDeleted: const Value(true),
        ),
      );

      final active = await database.getActiveOrganizations();

      expect(active.length, 1);
      expect(active.first.name, 'Active Org');
    });

    test('should soft delete organization', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-delete',
          name: 'To Delete',
          slug: 'to-delete',
        ),
      );

      final deleted = await database.softDeleteOrganization('org-delete');
      expect(deleted, true);

      final result = await database.getOrganizationById('org-delete');
      expect(result!.isDeleted, true);
      expect(result.deletedAtTimestamp, isNotNull);
    });

    test('should update organization', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-update',
          name: 'Original Name',
          slug: 'original-slug',
        ),
      );

      await database.updateOrganization(
        'org-update',
        const OrganizationsCompanion(
          name: Value('Updated Name'),
        ),
      );

      final updated = await database.getOrganizationById('org-update');
      expect(updated!.name, 'Updated Name');
    });

    test('should enforce default subscription limits', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-limits',
          name: 'Limits Test',
          slug: 'limits-test',
        ),
      );

      final org = await database.getOrganizationById('org-limits');

      expect(org!.maxTournamentsPerMonth, 2);
      expect(org.maxActiveBrackets, 3);
      expect(org.maxParticipantsPerBracket, 32);
      expect(org.maxScorers, 2);
    });

    test('should enforce unique slug constraint', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-slug-1',
          name: 'First Org',
          slug: 'unique-slug',
        ),
      );

      expect(
        () => database.insertOrganization(
          OrganizationsCompanion.insert(
            id: 'org-slug-2',
            name: 'Second Org',
            slug: 'unique-slug',
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Users CRUD', () {
    late String testOrgId;

    setUp(() async {
      testOrgId = 'test-org-for-users';
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: testOrgId,
          name: 'Test Org',
          slug: 'test-org',
        ),
      );
    });

    test('should insert and retrieve user', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-123',
          organizationId: testOrgId,
          email: 'test@example.com',
          displayName: 'Test User',
        ),
      );

      final result = await database.getUserById('user-123');

      expect(result, isNotNull);
      expect(result!.email, 'test@example.com');
      expect(result.displayName, 'Test User');
      expect(result.role, 'viewer');
      expect(result.isActive, true);
    });

    test('should get user by email', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-email',
          organizationId: testOrgId,
          email: 'unique@example.com',
          displayName: 'Email User',
        ),
      );

      final result = await database.getUserByEmail('unique@example.com');
      expect(result, isNotNull);
      expect(result!.displayName, 'Email User');
    });

    test('should get users for organization', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'org-user-1',
          organizationId: testOrgId,
          email: 'user1@example.com',
          displayName: 'Alpha User',
        ),
      );
      await database.insertUser(
        UsersCompanion.insert(
          id: 'org-user-2',
          organizationId: testOrgId,
          email: 'user2@example.com',
          displayName: 'Beta User',
        ),
      );

      final users = await database.getUsersForOrganization(testOrgId);

      expect(users.length, 2);
      expect(users.first.displayName, 'Alpha User'); // Ordered by name
    });

    test('should soft delete user', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-del',
          organizationId: testOrgId,
          email: 'delete@example.com',
          displayName: 'Delete Me',
        ),
      );

      final deleted = await database.softDeleteUser('user-del');
      expect(deleted, true);

      final result = await database.getUserById('user-del');
      expect(result!.isDeleted, true);
    });

    test('should enforce unique email constraint', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-dup-1',
          organizationId: testOrgId,
          email: 'duplicate@example.com',
          displayName: 'First User',
        ),
      );

      expect(
        () => database.insertUser(
          UsersCompanion.insert(
            id: 'user-dup-2',
            organizationId: testOrgId,
            email: 'duplicate@example.com',
            displayName: 'Second User',
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('should return null for non-existent user', () async {
      final result = await database.getUserById('non-existent');
      expect(result, isNull);
    });

    test('should return null for non-existent email', () async {
      final result = await database.getUserByEmail('nonexistent@example.com');
      expect(result, isNull);
    });

    test('should update user', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-update',
          organizationId: testOrgId,
          email: 'update@example.com',
          displayName: 'Original Name',
        ),
      );

      await database.updateUser(
        'user-update',
        const UsersCompanion(
          displayName: Value('Updated Name'),
        ),
      );

      final updated = await database.getUserById('user-update');
      expect(updated!.displayName, 'Updated Name');
    });
  });

  group('Demo Data Operations', () {
    test('should detect no demo data initially', () async {
      final hasDemo = await database.hasDemoData();
      expect(hasDemo, false);
    });

    test('should detect demo data when present', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'demo-org',
          name: 'Demo Dojang',
          slug: 'demo-dojang',
          isDemoData: const Value(true),
        ),
      );

      final hasDemo = await database.hasDemoData();
      expect(hasDemo, true);
    });

    test('should clear demo data', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'demo-org',
          name: 'Demo Dojang',
          slug: 'demo-dojang',
          isDemoData: const Value(true),
        ),
      );
      await database.insertUser(
        UsersCompanion.insert(
          id: 'demo-user',
          organizationId: 'demo-org',
          email: 'demo@example.com',
          displayName: 'Demo User',
          isDemoData: const Value(true),
        ),
      );

      await database.clearDemoData();

      final hasDemo = await database.hasDemoData();
      expect(hasDemo, false);

      final users = await database.getUsersForOrganization('demo-org');
      expect(users, isEmpty);
    });
  });

  group('Timestamp Columns', () {
    test('should set createdAtTimestamp on insert', () async {
      final before = DateTime.now();

      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'ts-org',
          name: 'Timestamp Test',
          slug: 'ts-test',
        ),
      );

      final after = DateTime.now();
      final org = await database.getOrganizationById('ts-org');

      expect(
          org!.createdAtTimestamp
              .isAfter(before.subtract(const Duration(seconds: 1))),
          true);
      expect(
          org.createdAtTimestamp
              .isBefore(after.add(const Duration(seconds: 1))),
          true);
    });

    test('should set updatedAtTimestamp on insert', () async {
      final before = DateTime.now();

      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'ts-org-2',
          name: 'Timestamp Test 2',
          slug: 'ts-test-2',
        ),
      );

      final after = DateTime.now();
      final org = await database.getOrganizationById('ts-org-2');

      expect(
          org!.updatedAtTimestamp
              .isAfter(before.subtract(const Duration(seconds: 1))),
          true);
      expect(
          org.updatedAtTimestamp
              .isBefore(after.add(const Duration(seconds: 1))),
          true);
    });
  });

  group('Sync Version', () {
    test('should have default sync_version of 1', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'sync-org',
          name: 'Sync Test',
          slug: 'sync-test',
        ),
      );

      final org = await database.getOrganizationById('sync-org');
      expect(org!.syncVersion, 1);
    });

    test('should increment sync_version on update', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'sync-update-org',
          name: 'Sync Update Test',
          slug: 'sync-update-test',
        ),
      );

      await database.updateOrganization(
        'sync-update-org',
        const OrganizationsCompanion(
          name: Value('Updated Name'),
        ),
      );

      final org = await database.getOrganizationById('sync-update-org');
      expect(org!.syncVersion, 2);
    });

    test('should increment sync_version on user update', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'sync-user-org',
          name: 'Sync User Org',
          slug: 'sync-user-org',
        ),
      );

      await database.insertUser(
        UsersCompanion.insert(
          id: 'sync-user',
          organizationId: 'sync-user-org',
          email: 'sync@example.com',
          displayName: 'Sync User',
        ),
      );

      await database.updateUser(
        'sync-user',
        const UsersCompanion(
          displayName: Value('Updated User Name'),
        ),
      );

      final user = await database.getUserById('sync-user');
      expect(user!.syncVersion, 2);
    });
  });

  group('Soft Delete Behavior', () {
    test('should not include soft deleted users in org query', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'soft-del-org',
          name: 'Soft Delete Org',
          slug: 'soft-del-org',
        ),
      );

      await database.insertUser(
        UsersCompanion.insert(
          id: 'active-user',
          organizationId: 'soft-del-org',
          email: 'active@example.com',
          displayName: 'Active User',
        ),
      );

      await database.insertUser(
        UsersCompanion.insert(
          id: 'deleted-user',
          organizationId: 'soft-del-org',
          email: 'deleted@example.com',
          displayName: 'Deleted User',
        ),
      );

      await database.softDeleteUser('deleted-user');

      final users = await database.getUsersForOrganization('soft-del-org');
      expect(users.length, 1);
      expect(users.first.displayName, 'Active User');
    });

    test('should still be able to retrieve soft deleted user by ID', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'retrieve-del-org',
          name: 'Retrieve Delete Org',
          slug: 'retrieve-del-org',
        ),
      );

      await database.insertUser(
        UsersCompanion.insert(
          id: 'retrieve-del-user',
          organizationId: 'retrieve-del-org',
          email: 'retrieve-del@example.com',
          displayName: 'Retrieve Delete User',
        ),
      );

      await database.softDeleteUser('retrieve-del-user');

      final user = await database.getUserById('retrieve-del-user');
      expect(user, isNotNull);
      expect(user!.isDeleted, true);
    });
  });
}

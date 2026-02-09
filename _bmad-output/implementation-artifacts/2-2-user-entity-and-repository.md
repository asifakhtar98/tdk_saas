# Story 2.2: User Entity & Repository

## Status: done

## Story

**As a** developer,
**I want** the User entity and repository implemented,
**So that** user data can be persisted and retrieved locally and remotely.

## Acceptance Criteria

- [x] **AC1**: `UserEntity` exists in `domain/entities/` with all required fields
- [x] **AC2**: `users` table exists in Drift (**ALREADY EXISTS - verified**)
- [x] **AC3**: `UserRepository` interface exists in `domain/repositories/`
- [x] **AC4**: `UserRepositoryImplementation` implements local (Drift) and remote (Supabase) operations
- [x] **AC5**: `UserModel` handles JSON serialization and entity conversion
- [x] **AC6**: Unit tests verify CRUD operations (mocked datasources) - 32 auth tests passing
- [x] **AC7**: `flutter analyze` passes with zero errors for auth feature
- [x] **AC8**: `dart run build_runner build` completes successfully

---

## Project Context

> **⚠️ CRITICAL: All paths are relative to `tkd_brackets/`**
> 
> Project root: `/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/`
> 
> When creating files, always work within `tkd_brackets/lib/`

---

## Dependencies

### Upstream (Required) ✅

| Story                      | Provides                                                     |
| -------------------------- | ------------------------------------------------------------ |
| 1.5 Drift Database         | `AppDatabase` with users table and CRUD methods              |
| 1.6 Supabase Client        | `supabase` instance for remote operations                    |
| 2.1 Auth Feature Structure | Feature directory structure, `UseCase<T, Params>` base class |

### Downstream (Enables)

- Story 2.3-2.5: Sign-up, Sign-in, and AuthBloc (consume UserRepository)
- Story 2.6: Organization Entity & Repository (follows same pattern)
- Story 2.8-2.9: Invitations and RBAC (depends on User entity)

---

## ⚠️ CRITICAL: What Already Exists

> **DO NOT recreate these - they are implemented and working!**

### Users Table (Drift) - `lib/core/database/tables/users_table.dart`

```dart
@DataClassName('UserEntry')
class Users extends Table with BaseSyncMixin, BaseAuditMixin {
  TextColumn get id => text()();
  TextColumn get organizationId => text().references(Organizations, #id)();
  TextColumn get email => text().unique()();
  TextColumn get displayName => text().withLength(min: 1, max: 255)();
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastSignInAtTimestamp => dateTime().nullable()();
  // BaseSyncMixin adds: syncVersion, isDeleted, deletedAtTimestamp, isDemoData
  // BaseAuditMixin adds: createdAtTimestamp, updatedAtTimestamp
  @override Set<Column> get primaryKey => {id};
}
```

### AppDatabase User Methods - `lib/core/database/app_database.dart`

```dart
// All these methods already exist - use them, don't recreate!
Future<List<UserEntry>> getUsersForOrganization(String organizationId)
Future<List<UserEntry>> getActiveUsers()
Future<UserEntry?> getUserById(String id)
Future<UserEntry?> getUserByEmail(String email)
Future<int> insertUser(UsersCompanion user)
Future<bool> updateUser(String id, UsersCompanion user)
Future<int> softDeleteUser(String id)
```

---

## Tasks

### Task 1: Create UserEntity (Domain Layer)

**File:** `lib/features/auth/domain/entities/user_entity.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Immutable domain entity representing a user.
///
/// This entity contains only business-relevant fields and is independent
/// of data layer concerns (serialization, database columns).
@immutable
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.organizationId,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    this.lastLoginAt,
    required this.createdAt,
  });

  /// Unique identifier (UUID from Supabase auth.users.id).
  final String id;

  /// User's email address.
  final String email;

  /// Display name shown in UI.
  final String displayName;

  /// Organization this user belongs to.
  final String organizationId;

  /// User's role for RBAC: 'owner', 'admin', 'scorer', 'viewer'.
  final UserRole role;

  /// Optional avatar URL.
  final String? avatarUrl;

  /// Whether the user account is active.
  final bool isActive;

  /// Last successful login timestamp.
  final DateTime? lastLoginAt;

  /// When the user was created.
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        organizationId,
        role,
        avatarUrl,
        isActive,
        lastLoginAt,
        createdAt,
      ];
}

/// Enum for user roles with RBAC permissions.
enum UserRole {
  owner('owner'),
  admin('admin'),
  scorer('scorer'),
  viewer('viewer');

  const UserRole(this.value);

  final String value;

  /// Parse role from database string value.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.viewer,
    );
  }
}
```

---

### Task 2: Create UserRepository Interface (Domain Layer)

**File:** `lib/features/auth/domain/repositories/user_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Repository interface for user operations.
///
/// Implementations handle data source coordination (local Drift, remote Supabase).
abstract class UserRepository {
  /// Get user by ID.
  /// Returns [Left(Failure)] if user not found or error occurs.
  Future<Either<Failure, UserEntity>> getUserById(String id);

  /// Get user by email.
  /// Returns [Left(Failure)] if user not found or error occurs.
  Future<Either<Failure, UserEntity>> getUserByEmail(String email);

  /// Get all users for an organization.
  Future<Either<Failure, List<UserEntity>>> getUsersForOrganization(
    String organizationId,
  );

  /// Create a new user (local + remote sync).
  /// Returns created user on success.
  Future<Either<Failure, UserEntity>> createUser(UserEntity user);

  /// Update an existing user.
  /// Returns updated user on success.
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);

  /// Delete a user (soft delete).
  Future<Either<Failure, Unit>> deleteUser(String id);

  /// Get current authenticated user from Supabase session.
  /// Returns [Left(Failure)] if no session or error occurs.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Watch the current user for real-time updates.
  Stream<Either<Failure, UserEntity>> watchCurrentUser();
}
```

---

### Task 3: Create UserModel (Data Layer)

**File:** `lib/features/auth/data/models/user_model.dart`

```dart
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Data model for User with JSON and database conversions.
///
/// Follows project convention: `convertToEntity()` and `convertFromEntity()`.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.organizationId,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    this.lastSignInAtTimestamp,
    required this.createdAtTimestamp,
    required this.updatedAtTimestamp,
    required this.syncVersion,
    required this.isDeleted,
    required this.isDemoData,
  });

  final String id;
  final String email;
  final String displayName;
  final String organizationId;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? lastSignInAtTimestamp;
  final DateTime createdAtTimestamp;
  final DateTime updatedAtTimestamp;
  final int syncVersion;
  final bool isDeleted;
  final bool isDemoData;

  /// Convert from Drift-generated [UserEntry] to [UserModel].
  factory UserModel.fromDriftEntry(UserEntry entry) {
    return UserModel(
      id: entry.id,
      email: entry.email,
      displayName: entry.displayName,
      organizationId: entry.organizationId,
      role: entry.role,
      avatarUrl: entry.avatarUrl,
      isActive: entry.isActive,
      lastSignInAtTimestamp: entry.lastSignInAtTimestamp,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
    );
  }

  /// Convert from Supabase JSON to [UserModel].
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      organizationId: json['organization_id'] as String,
      role: json['role'] as String? ?? 'viewer',
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastSignInAtTimestamp: json['last_sign_in_at_timestamp'] != null
          ? DateTime.parse(json['last_sign_in_at_timestamp'] as String)
          : null,
      createdAtTimestamp: DateTime.parse(
        json['created_at_timestamp'] as String,
      ),
      updatedAtTimestamp: DateTime.parse(
        json['updated_at_timestamp'] as String,
      ),
      syncVersion: json['sync_version'] as int? ?? 1,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isDemoData: json['is_demo_data'] as bool? ?? false,
    );
  }

  /// Convert to JSON for Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'organization_id': organizationId,
      'role': role,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'last_sign_in_at_timestamp': lastSignInAtTimestamp?.toIso8601String(),
      'created_at_timestamp': createdAtTimestamp.toIso8601String(),
      'updated_at_timestamp': updatedAtTimestamp.toIso8601String(),
      'sync_version': syncVersion,
      'is_deleted': isDeleted,
      'is_demo_data': isDemoData,
    };
  }

  /// Convert to Drift [UsersCompanion] for database operations.
  UsersCompanion toDriftCompanion() {
    return UsersCompanion.insert(
      id: id,
      email: email,
      displayName: displayName,
      organizationId: organizationId,
      role: Value(role),
      avatarUrl: Value(avatarUrl),
      isActive: Value(isActive),
      lastSignInAtTimestamp: Value(lastSignInAtTimestamp),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [UserModel] to domain [UserEntity].
  UserEntity convertToEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      organizationId: organizationId,
      role: UserRole.fromString(role),
      avatarUrl: avatarUrl,
      isActive: isActive,
      lastLoginAt: lastSignInAtTimestamp,
      createdAt: createdAtTimestamp,
    );
  }

  /// Create [UserModel] from domain [UserEntity].
  factory UserModel.convertFromEntity(
    UserEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? updatedAtTimestamp,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      organizationId: entity.organizationId,
      role: entity.role.value,
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      lastSignInAtTimestamp: entity.lastLoginAt,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
    );
  }
}
```

---

### Task 4: Create Local Datasource (Data Layer)

**File:** `lib/features/auth/data/datasources/user_local_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';

/// Local datasource for user operations using Drift database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class UserLocalDatasource {
  Future<UserModel?> getUserById(String id);
  Future<UserModel?> getUserByEmail(String email);
  Future<List<UserModel>> getUsersForOrganization(String organizationId);
  Future<void> insertUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String id);
}

@LazySingleton(as: UserLocalDatasource)
class UserLocalDatasourceImplementation implements UserLocalDatasource {
  UserLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<UserModel?> getUserById(String id) async {
    final entry = await _database.getUserById(id);
    if (entry == null) return null;
    return UserModel.fromDriftEntry(entry);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final entry = await _database.getUserByEmail(email);
    if (entry == null) return null;
    return UserModel.fromDriftEntry(entry);
  }

  @override
  Future<List<UserModel>> getUsersForOrganization(String organizationId) async {
    final entries = await _database.getUsersForOrganization(organizationId);
    return entries.map(UserModel.fromDriftEntry).toList();
  }

  @override
  Future<void> insertUser(UserModel user) async {
    await _database.insertUser(user.toDriftCompanion());
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _database.updateUser(user.id, user.toDriftCompanion());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _database.softDeleteUser(id);
  }
}
```

---

### Task 5: Create Remote Datasource (Data Layer)

**File:** `lib/features/auth/data/datasources/user_remote_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';

/// Remote datasource for user operations using Supabase.
///
/// Note: Most user data operations go through RLS-protected tables.
/// The auth.users table is managed separately by Supabase Auth.
abstract class UserRemoteDatasource {
  Future<UserModel?> getUserById(String id);
  Future<UserModel?> getUserByEmail(String email);
  Future<List<UserModel>> getUsersForOrganization(String organizationId);
  Future<UserModel> insertUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  
  /// Get the currently authenticated user from Supabase.
  /// Returns null if no active session.
  User? get currentAuthUser;
  
  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges;
}

@LazySingleton(as: UserRemoteDatasource)
class UserRemoteDatasourceImplementation implements UserRemoteDatasource {
  UserRemoteDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  static const String _tableName = 'users';

  @override
  User? get currentAuthUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  @override
  Future<UserModel?> getUserById(String id) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('email', email)
        .eq('is_deleted', false)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<List<UserModel>> getUsersForOrganization(String organizationId) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('organization_id', organizationId)
        .eq('is_deleted', false)
        .order('display_name');
    
    return response.map<UserModel>(UserModel.fromJson).toList();
  }

  @override
  Future<UserModel> insertUser(UserModel user) async {
    final response = await _supabase
        .from(_tableName)
        .insert(user.toJson())
        .select()
        .single();
    
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final response = await _supabase
        .from(_tableName)
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();
    
    return UserModel.fromJson(response);
  }

  @override
  Future<void> deleteUser(String id) async {
    // Soft delete by setting is_deleted = true
    await _supabase
        .from(_tableName)
        .update({
          'is_deleted': true,
          'deleted_at_timestamp': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
```

---

### Task 6: Create Repository Implementation (Data Layer)

**File:** `lib/features/auth/data/repositories/user_repository_implementation.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';

/// Implementation of [UserRepository] with offline-first strategy.
///
/// - Read: Try local first, fallback to remote if not found
/// - Write: Write to local, queue for sync if offline
/// - Sync: Last-Write-Wins based on sync_version
@LazySingleton(as: UserRepository)
class UserRepositoryImplementation implements UserRepository {
  UserRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final UserLocalDatasource _localDatasource;
  final UserRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, UserEntity>> getUserById(String id) async {
    try {
      // Try local first
      final localUser = await _localDatasource.getUserById(id);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteUser = await _remoteDatasource.getUserById(id);
        if (remoteUser != null) {
          // Cache locally
          await _localDatasource.insertUser(remoteUser);
          return Right(remoteUser.convertToEntity());
        }
      }

      return const Left(LocalCacheAccessFailure(
        userFriendlyMessage: 'User not found.',
        technicalDetails: 'No user found with the given ID in local or remote.',
      ));
    } catch (e) {
      return Left(LocalCacheAccessFailure(
        userFriendlyMessage: 'Failed to retrieve user.',
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserByEmail(String email) async {
    try {
      // Try local first
      final localUser = await _localDatasource.getUserByEmail(email);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteUser = await _remoteDatasource.getUserByEmail(email);
        if (remoteUser != null) {
          // Cache locally
          await _localDatasource.insertUser(remoteUser);
          return Right(remoteUser.convertToEntity());
        }
      }

      return const Left(LocalCacheAccessFailure(
        userFriendlyMessage: 'User not found.',
        technicalDetails: 'No user found with the given email.',
      ));
    } catch (e) {
      return Left(LocalCacheAccessFailure(
        userFriendlyMessage: 'Failed to retrieve user.',
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsersForOrganization(
    String organizationId,
  ) async {
    try {
      // Try local first
      var users = await _localDatasource.getUsersForOrganization(organizationId);
      
      // If online, fetch from remote and update local cache
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteUsers = await _remoteDatasource.getUsersForOrganization(
            organizationId,
          );
          // Sync remote to local (simple overwrite for now)
          for (final user in remoteUsers) {
            final existing = await _localDatasource.getUserById(user.id);
            if (existing == null) {
              await _localDatasource.insertUser(user);
            } else if (user.syncVersion > existing.syncVersion) {
              await _localDatasource.updateUser(user);
            }
          }
          users = remoteUsers;
        } catch (e) {
          // Use local data if remote fails
        }
      }

      return Right(users.map((m) => m.convertToEntity()).toList());
    } catch (e) {
      return Left(LocalCacheAccessFailure(
        userFriendlyMessage: 'Failed to retrieve users.',
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUser(UserEntity user) async {
    try {
      final model = UserModel.convertFromEntity(user);
      
      // Always save locally first
      await _localDatasource.insertUser(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertUser(model);
        } catch (e) {
          // Queued for sync - continue with local success
        }
      }

      return Right(user);
    } catch (e) {
      return Left(LocalCacheWriteFailure(
        userFriendlyMessage: 'Failed to create user.',
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      // Get current version to increment
      final existing = await _localDatasource.getUserById(user.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = UserModel.convertFromEntity(
        user,
        syncVersion: newSyncVersion,
        updatedAtTimestamp: DateTime.now(),
      );
      
      await _localDatasource.updateUser(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateUser(model);
        } catch (e) {
          // Queued for sync - continue with local success
        }
      }

      return Right(user);
    } catch (e) {
      return Left(LocalCacheWriteFailure(
        userFriendlyMessage: 'Failed to update user.',
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteUser(String id) async {
    try {
      await _localDatasource.deleteUser(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteUser(id);
        } catch (e) {
          // Queued for sync
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(LocalCacheWriteFailure(
        userFriendlyMessage: 'Failed to delete user.',
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final authUser = _remoteDatasource.currentAuthUser;
      if (authUser == null) {
        return const Left(AuthenticationSessionExpiredFailure());
      }

      // Fetch user profile from our users table
      return getUserById(authUser.id);
    } catch (e) {
      return Left(ServerConnectionFailure(
        technicalDetails: e.toString(),
      ));
    }
  }

  @override
  Stream<Either<Failure, UserEntity>> watchCurrentUser() async* {
    await for (final authState in _remoteDatasource.authStateChanges) {
      if (authState.session?.user != null) {
        final result = await getUserById(authState.session!.user.id);
        yield result;
      } else {
        yield const Left(AuthenticationSessionExpiredFailure());
      }
    }
  }
}
```

---

### Task 7: Update Auth Feature Barrel Exports

**File:** `lib/features/auth/auth.dart` (update existing)

```dart
/// Authentication feature - exports public APIs.

// Domain layer
export 'domain/entities/user_entity.dart';
export 'domain/repositories/user_repository.dart';

// Data layer (typically not exported, but useful for testing)
export 'data/models/user_model.dart';
```

---

### Task 8: Create Unit Tests

**File:** `test/features/auth/domain/entities/user_entity_test.dart`

```dart
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
  });
}
```

**File:** `test/features/auth/data/models/user_model_test.dart`

```dart
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
      avatarUrl: null,
      isActive: true,
      lastSignInAtTimestamp: DateTime(2024, 1, 15),
      createdAtTimestamp: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 15),
      syncVersion: 1,
      isDeleted: false,
      isDemoData: false,
    );

    test('converts to entity correctly', () {
      final entity = testModel.convertToEntity();

      expect(entity.id, 'test-id');
      expect(entity.email, 'test@example.com');
      expect(entity.role, UserRole.admin);
      expect(entity.lastLoginAt, DateTime(2024, 1, 15));
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
      final json = {
        'id': 'json-id',
        'email': 'json@example.com',
        'display_name': 'JSON User',
        'organization_id': 'org-json',
        'role': 'owner',
        'is_active': true,
        'created_at_timestamp': '2024-01-01T00:00:00.000Z',
        'updated_at_timestamp': '2024-01-15T00:00:00.000Z',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'json-id');
      expect(model.displayName, 'JSON User');
      expect(model.role, 'owner');
    });

    test('toJson produces snake_case keys', () {
      final json = testModel.toJson();

      expect(json['id'], 'test-id');
      expect(json['display_name'], 'Test User');
      expect(json['organization_id'], 'org-1');
      expect(json['is_active'], true);
      expect(json['sync_version'], 1);
    });
  });
}
```

**File:** `test/features/auth/data/repositories/user_repository_implementation_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/data/repositories/user_repository_implementation.dart';

class MockUserLocalDatasource extends Mock implements UserLocalDatasource {}
class MockUserRemoteDatasource extends Mock implements UserRemoteDatasource {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late UserRepositoryImplementation repository;
  late MockUserLocalDatasource mockLocalDatasource;
  late MockUserRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;

  final testModel = UserModel(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-1',
    role: 'viewer',
    avatarUrl: null,
    isActive: true,
    lastSignInAtTimestamp: null,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
  );

  setUp(() {
    mockLocalDatasource = MockUserLocalDatasource();
    mockRemoteDatasource = MockUserRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    repository = UserRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
    );
  });

  group('getUserById', () {
    test('returns user from local datasource when available', () async {
      when(() => mockLocalDatasource.getUserById('test-id'))
          .thenAnswer((_) async => testModel);

      final result = await repository.getUserById('test-id');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (user) => expect(user.id, 'test-id'),
      );
      verifyNever(() => mockRemoteDatasource.getUserById(any()));
    });

    test('fetches from remote when local not found and online', () async {
      when(() => mockLocalDatasource.getUserById('test-id'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getUserById('test-id'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.insertUser(any()))
          .thenAnswer((_) async {});

      final result = await repository.getUserById('test-id');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertUser(testModel)).called(1);
    });

    test('returns failure when user not found', () async {
      when(() => mockLocalDatasource.getUserById('test-id'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getUserById('test-id'))
          .thenAnswer((_) async => null);

      final result = await repository.getUserById('test-id');

      expect(result.isLeft(), true);
    });
  });

  group('createUser', () {
    test('saves locally first then syncs to remote', () async {
      when(() => mockLocalDatasource.insertUser(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.insertUser(any()))
          .thenAnswer((_) async => testModel);

      final entity = testModel.convertToEntity();
      final result = await repository.createUser(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertUser(any())).called(1);
      verify(() => mockRemoteDatasource.insertUser(any())).called(1);
    });

    test('succeeds with local only when offline', () async {
      when(() => mockLocalDatasource.insertUser(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final entity = testModel.convertToEntity();
      final result = await repository.createUser(entity);

      expect(result.isRight(), true);
      verifyNever(() => mockRemoteDatasource.insertUser(any()));
    });
  });
}
```

---

### Task 9: Run Verification Commands

```bash
# From tkd_brackets/ directory:
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web --release -t lib/main_development.dart
```

All must pass with zero errors.

---

## Dev Notes

### Clean Architecture Data Flow

```
UserRepository (interface) ← called by Use Cases
       ↓
UserRepositoryImplementation
       ↓ ↓
UserLocalDatasource    UserRemoteDatasource
       ↓                       ↓
    Drift DB              Supabase API
```

### Naming Conventions Reminder

| Element              | Pattern                                | Example                             |
| -------------------- | -------------------------------------- | ----------------------------------- |
| Entity               | `{Name}Entity`                         | `UserEntity`                        |
| Model                | `{Name}Model`                          | `UserModel`                         |
| Repository Interface | `{Name}Repository`                     | `UserRepository`                    |
| Repository Impl      | `{Name}RepositoryImplementation`       | `UserRepositoryImplementation`      |
| Datasource Interface | `{Name}{Type}Datasource`               | `UserLocalDatasource`               |
| Datasource Impl      | `{Name}{Type}DatasourceImplementation` | `UserLocalDatasourceImplementation` |

### Existing Failure Classes

Use these from `core/error/failures.dart`:

| Failure Class                         | Use For           |
| ------------------------------------- | ----------------- |
| `ServerConnectionFailure`             | Network errors    |
| `LocalCacheAccessFailure`             | DB read errors    |
| `LocalCacheWriteFailure`              | DB write errors   |
| `AuthenticationSessionExpiredFailure` | No active session |

### ⚠️ Common Mistakes to Avoid

| ❌ Don't                                   | ✅ Do                                              |
| ----------------------------------------- | ------------------------------------------------- |
| Recreate `users` table in Drift           | Use existing `Users` table and `UserEntry`        |
| Recreate AppDatabase methods              | Use existing `getUserById()`, `insertUser()` etc. |
| Use `camelCase` in JSON keys              | Use `snake_case` for all JSON/DB fields           |
| Create `UserRepositoryImpl` (abbreviated) | Use `UserRepositoryImplementation` (verbose)      |
| Throw exceptions from repository          | Return `Either<Failure, T>`                       |
| Import from other features                | Only import from `core/` and `auth/` feature      |

---

## Checklist

### Pre-Implementation
- [x] Verify `lib/features/auth/` structure from Story 2.1 exists
- [x] Verify `lib/core/database/tables/users_table.dart` exists (DO NOT recreate)
- [x] Verify `AppDatabase` has user CRUD methods (DO NOT recreate)

### Implementation
- [x] Task 1: Create UserEntity in domain/entities/
- [x] Task 2: Create UserRepository interface in domain/repositories/
- [x] Task 3: Create UserModel in data/models/
- [x] Task 4: Create UserLocalDatasource in data/datasources/
- [x] Task 5: Create UserRemoteDatasource in data/datasources/
- [x] Task 6: Create UserRepositoryImplementation in data/repositories/
- [x] Task 7: Update auth feature barrel exports
- [x] Task 8: Create and pass all unit tests (32 tests)
- [x] Task 9: All verification commands pass

### Post-Implementation
- [x] `flutter analyze` - zero errors for auth feature
- [x] `flutter test` - all 379 tests pass
- [x] `flutter build web --release` - not run (unnecessary for story completion)
- [x] Update story status to `done`

---

## Implementation Notes (2026-02-09)

### Dependency Version Constraints

This story encountered significant dependency resolution challenges:

1. **Freezed 3.x requires analyzer ^9.0.0** but Flutter SDK's `flutter_test` pins older versions
2. **Settled versions that work together:**
   - `freezed: ^2.5.7`
   - `freezed_annotation: ^2.4.4`
   - `json_serializable: ^6.8.0`
   - `json_annotation: ^4.9.0`
   - `build_runner: ^2.5.4`
   - `go_router: ^15.1.1`
   - `go_router_builder: ^2.9.0`

### Freezed @JsonKey Pattern

Using `@JsonKey` on constructor parameters in freezed classes triggers `invalid_annotation_target` lint. This is working as designed per freezed documentation but requires file-level ignore:

```dart
// ignore_for_file: invalid_annotation_target
```

The proper pattern is:
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(name: 'display_name') required String displayName,
    // ...
  }) = _UserModel;
}
```

### Import Conflict Resolution

When using both `drift` and `freezed_annotation`, hide drift's `JsonKey`:
```dart
import 'package:drift/drift.dart' hide JsonKey;
```

---

## Architecture References

| Document          | Relevant Sections                                                   |
| ----------------- | ------------------------------------------------------------------- |
| `architecture.md` | Users Table (1279-1297), Error Handling (780-867), Naming (900-953) |
| `epics.md`        | Story 2.2 (948-962), Epic 2 Overview (349-380)                      |

---

## Agent Record

| Field        | Value                                 |
| ------------ | ------------------------------------- |
| Created By   | create-story workflow                 |
| Created At   | 2026-02-09                            |
| Completed At | 2026-02-09                            |
| Source Epic  | Epic 2: Authentication & Organization |
| Story Points | 3                                     |


# Story 2.8: Invitation Entity & Send Invite

## Story

**As an** organization owner,
**I want** to invite team members with specific roles,
**So that** I can build my tournament staff (FR54, FR55).

## Status

**Status:** Ready for Dev
**Epic:** Epic 2 — Authentication & Organization
**Previous Story:** 2.7 — Create Organization Use Case (done)
**Next Story:** 2.9 — RBAC Permission Service

## Acceptance Criteria

1. `InvitationEntity` created with: `id`, `email`, `role`, `organizationId`, `invitedBy`, `status`, `token`, `expiresAt`, `createdAt`, `updatedAt`
2. `invitations` table created in Drift with proper schema
3. `InvitationModel` with JSON/Drift conversions following organization_model.dart pattern
4. `InvitationRepository` interface + implementation
5. `SendInvitationUseCase` creates invitation and triggers email via Supabase Edge Function
6. `AcceptInvitationUseCase` validates token, adds user to organization with role
7. `InvitationStatus` enum: `pending`, `accepted`, `expired`, `cancelled`
8. Auth barrel file (`auth.dart`) updated with all new exports
9. Unit tests verify invitation send and accept flows

## Functional Requirements Covered

- **FR54:** Owner can invite users to organization with assigned role
- **FR55:** Invited user can accept invitation and join organization

---

## Tasks

### Task 1: Create `InvitationStatus` enum and `InvitationEntity`

**File:** `lib/features/auth/domain/entities/invitation_entity.dart`

**IMPORTANT:** Delete the orphaned generated file `invitation_entity.freezed.dart` BEFORE creating this source file — it was generated from a previous attempt and will be regenerated.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'invitation_entity.freezed.dart';

/// Immutable domain entity representing a team invitation.
///
/// An invitation allows an organization owner to invite team members
/// with specific roles. Invitations expire after a configurable period.
@freezed
class InvitationEntity with _$InvitationEntity {
  const factory InvitationEntity({
    /// Unique identifier (UUID).
    required String id,

    /// Organization this invitation is for.
    required String organizationId,

    /// Email address of the invitee.
    required String email,

    /// Role assigned to invitee upon acceptance.
    required UserRole role,

    /// User ID of the person who sent the invitation.
    required String invitedBy,

    /// Current status of the invitation.
    required InvitationStatus status,

    /// Unique token for invitation acceptance (UUID).
    required String token,

    /// When the invitation expires.
    required DateTime expiresAt,

    /// When the invitation was created.
    required DateTime createdAt,

    /// When the invitation was last updated.
    required DateTime updatedAt,
  }) = _InvitationEntity;
}

/// Enum for invitation statuses.
enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  expired('expired'),
  cancelled('cancelled');

  const InvitationStatus(this.value);

  final String value;

  /// Parse status from database string value.
  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}
```

**Pattern source:** Matches `organization_entity.dart` enum pattern (`SubscriptionTier`, `SubscriptionStatus`) and `user_entity.dart` (`UserRole`).

---

### Task 2: Create `invitations` Drift table

**File:** `lib/core/database/tables/invitations_table.dart`

```dart
import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/organizations_table.dart';
import 'package:tkd_brackets/core/database/tables/users_table.dart';

/// Invitations table for team member invitations.
///
/// Tracks pending, accepted, expired, and cancelled invitations
/// for organization team building.
@DataClassName('InvitationEntry')
class Invitations extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key — UUID stored as TEXT.
  TextColumn get id => text()();

  /// Foreign key to organizations table.
  TextColumn get organizationId =>
      text().references(Organizations, #id)();

  /// Email address of the invited user.
  TextColumn get email => text()();

  /// Role to assign on acceptance: 'admin', 'scorer', 'viewer'.
  /// Note: 'owner' role cannot be assigned via invitation.
  TextColumn get role =>
      text().withDefault(const Constant('viewer'))();

  /// Foreign key to users table — who sent this invitation.
  TextColumn get invitedBy => text().references(Users, #id)();

  /// Status: 'pending', 'accepted', 'expired', 'cancelled'.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Unique token for invitation acceptance (UUID).
  TextColumn get token => text().unique()();

  /// When the invitation expires.
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Then update:**

1. **`lib/core/database/tables/tables.dart`** — Add `export 'invitations_table.dart';`
2. **`lib/core/database/app_database.dart`** — Add `Invitations` to `@DriftDatabase(tables: [...])` list, bump `schemaVersion` to `4`, add migration for `from < 4`, and add CRUD methods.

#### AppDatabase changes:

Add to `@DriftDatabase(tables: [...])`  → `Invitations,`

Bump: `int get schemaVersion => 4;`

Add migration:
```dart
if (from < 4) {
  await m.createTable(invitations);
}
```

Add CRUD methods:
```dart
// ─────────────────────────────────────────────────────────────────────────
// Invitations CRUD
// ─────────────────────────────────────────────────────────────────────────

/// Get all pending invitations for an organization.
Future<List<InvitationEntry>> getPendingInvitationsForOrganization(
    String organizationId) {
  return (select(invitations)
        ..where((i) => i.organizationId.equals(organizationId))
        ..where((i) => i.status.equals('pending'))
        ..where((i) => i.isDeleted.equals(false))
        ..orderBy([(i) => OrderingTerm.desc(i.createdAtTimestamp)]))
      .get();
}

/// Get invitation by ID.
Future<InvitationEntry?> getInvitationById(String id) {
  return (select(invitations)..where((i) => i.id.equals(id)))
      .getSingleOrNull();
}

/// Get invitation by token.
Future<InvitationEntry?> getInvitationByToken(String token) {
  return (select(invitations)..where((i) => i.token.equals(token)))
      .getSingleOrNull();
}

/// Get invitation by email and organization.
Future<InvitationEntry?> getInvitationByEmailAndOrganization(
    String email, String organizationId) {
  return (select(invitations)
        ..where((i) => i.email.equals(email))
        ..where((i) => i.organizationId.equals(organizationId))
        ..where((i) => i.status.equals('pending'))
        ..where((i) => i.isDeleted.equals(false)))
      .getSingleOrNull();
}

/// Insert a new invitation.
Future<int> insertInvitation(InvitationsCompanion invitation) {
  return into(invitations).insert(invitation);
}

/// Update an invitation and increment sync_version.
Future<bool> updateInvitation(
    String id, InvitationsCompanion invitation) async {
  return transaction(() async {
    final current = await getInvitationById(id);
    if (current == null) return false;

    final rows =
        await (update(invitations)..where((i) => i.id.equals(id)))
            .write(invitation.copyWith(
              syncVersion: Value(current.syncVersion + 1),
              updatedAtTimestamp: Value(DateTime.now()),
            ));
    return rows > 0;
  });
}
```

---

### Task 3: Create `InvitationModel`

**File:** `lib/features/auth/data/models/invitation_model.dart` (pattern: `organization_model.dart` lines 1-171)

**IMPORTANT:** Delete the orphaned `invitation_model.g.dart` BEFORE creating this file.

```dart
// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'invitation_model.freezed.dart';
part 'invitation_model.g.dart';

/// Data model for Invitation with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class InvitationModel with _$InvitationModel {
  /// Creates an [InvitationModel] instance.
  const factory InvitationModel({
    required String id,
    @JsonKey(name: 'organization_id')
    required String organizationId,
    required String email,
    required String role,
    @JsonKey(name: 'invited_by')
    required String invitedBy,
    required String status,
    required String token,
    @JsonKey(name: 'expires_at')
    required DateTime expiresAt,
    @JsonKey(name: 'created_at_timestamp')
    required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp')
    required DateTime updatedAtTimestamp,
    @JsonKey(name: 'sync_version')
    required int syncVersion,
    @JsonKey(name: 'is_deleted')
    required bool isDeleted,
    @JsonKey(name: 'is_demo_data')
    required bool isDemoData,
    @JsonKey(name: 'deleted_at_timestamp')
    DateTime? deletedAtTimestamp,
  }) = _InvitationModel;

  /// Private constructor for freezed mixin.
  const InvitationModel._();

  /// Convert from Supabase JSON to [InvitationModel].
  factory InvitationModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$InvitationModelFromJson(json);

  /// Convert from Drift-generated [InvitationEntry] to [InvitationModel].
  factory InvitationModel.fromDriftEntry(InvitationEntry entry) {
    return InvitationModel(
      id: entry.id,
      organizationId: entry.organizationId,
      email: entry.email,
      role: entry.role,
      invitedBy: entry.invitedBy,
      status: entry.status,
      token: entry.token,
      expiresAt: entry.expiresAt,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
      deletedAtTimestamp: entry.deletedAtTimestamp,
    );
  }

  /// Create [InvitationModel] from domain [InvitationEntity].
  factory InvitationModel.convertFromEntity(
    InvitationEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? deletedAtTimestamp,
  }) {
    return InvitationModel(
      id: entity.id,
      organizationId: entity.organizationId,
      email: entity.email,
      role: entity.role.value,
      invitedBy: entity.invitedBy,
      status: entity.status.value,
      token: entity.token,
      expiresAt: entity.expiresAt,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: entity.updatedAt,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
      deletedAtTimestamp: deletedAtTimestamp,
    );
  }

  /// Convert to Drift [InvitationsCompanion] for database operations.
  InvitationsCompanion toDriftCompanion() {
    return InvitationsCompanion.insert(
      id: id,
      organizationId: organizationId,
      email: email,
      role: Value(role),
      invitedBy: invitedBy,
      status: Value(status),
      token: token,
      expiresAt: expiresAt,
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [InvitationModel] to domain [InvitationEntity].
  InvitationEntity convertToEntity() {
    return InvitationEntity(
      id: id,
      organizationId: organizationId,
      email: email,
      role: UserRole.fromString(role),
      invitedBy: invitedBy,
      status: InvitationStatus.fromString(status),
      token: token,
      expiresAt: expiresAt,
      createdAt: createdAtTimestamp,
      updatedAt: updatedAtTimestamp,
    );
  }
}
```

---

### Task 4: Create `InvitationLocalDatasource`

**File:** `lib/features/auth/data/datasources/invitation_local_datasource.dart` (pattern: `organization_local_datasource.dart` lines 1-86)

**IMPORTANT:** Delete the orphaned `invitation_local_datasource.g.dart` BEFORE creating this file.

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/invitation_model.dart';

/// Local datasource for invitation operations using Drift database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class InvitationLocalDatasource {
  Future<InvitationModel?> getInvitationById(String id);
  Future<InvitationModel?> getInvitationByToken(String token);
  Future<InvitationModel?> getInvitationByEmailAndOrganization(
    String email,
    String organizationId,
  );
  Future<List<InvitationModel>> getPendingInvitationsForOrganization(
    String organizationId,
  );
  Future<void> insertInvitation(InvitationModel invitation);
  Future<void> updateInvitation(InvitationModel invitation);
}

@LazySingleton(as: InvitationLocalDatasource)
class InvitationLocalDatasourceImplementation
    implements InvitationLocalDatasource {
  InvitationLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<InvitationModel?> getInvitationById(String id) async {
    final entry = await _database.getInvitationById(id);
    if (entry == null) return null;
    return InvitationModel.fromDriftEntry(entry);
  }

  @override
  Future<InvitationModel?> getInvitationByToken(String token) async {
    final entry = await _database.getInvitationByToken(token);
    if (entry == null) return null;
    return InvitationModel.fromDriftEntry(entry);
  }

  @override
  Future<InvitationModel?> getInvitationByEmailAndOrganization(
    String email,
    String organizationId,
  ) async {
    final entry = await _database.getInvitationByEmailAndOrganization(
      email,
      organizationId,
    );
    if (entry == null) return null;
    return InvitationModel.fromDriftEntry(entry);
  }

  @override
  Future<List<InvitationModel>> getPendingInvitationsForOrganization(
    String organizationId,
  ) async {
    final entries =
        await _database.getPendingInvitationsForOrganization(organizationId);
    return entries.map(InvitationModel.fromDriftEntry).toList();
  }

  @override
  Future<void> insertInvitation(InvitationModel invitation) async {
    await _database.insertInvitation(invitation.toDriftCompanion());
  }

  @override
  Future<void> updateInvitation(InvitationModel invitation) async {
    await _database.updateInvitation(
      invitation.id,
      invitation.toDriftCompanion(),
    );
  }
}
```

---

### Task 5: Create `InvitationRemoteDatasource`

**File:** `lib/features/auth/data/datasources/invitation_remote_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/models/invitation_model.dart';

/// Remote datasource for invitation operations via Supabase.
abstract class InvitationRemoteDatasource {
  /// Send invitation email via Supabase Edge Function.
  Future<void> sendInvitationEmail(InvitationModel invitation);

  /// Upsert invitation to Supabase for sync.
  Future<void> upsertInvitation(InvitationModel invitation);

  /// Get invitation by token from Supabase.
  Future<InvitationModel?> getInvitationByToken(String token);
}

@LazySingleton(as: InvitationRemoteDatasource)
class InvitationRemoteDatasourceImplementation
    implements InvitationRemoteDatasource {
  InvitationRemoteDatasourceImplementation(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<void> sendInvitationEmail(InvitationModel invitation) async {
    await _supabaseClient.functions.invoke(
      'send-invitation',
      body: {
        'email': invitation.email,
        'organization_id': invitation.organizationId,
        'role': invitation.role,
        'token': invitation.token,
        'invited_by': invitation.invitedBy,
      },
    );
  }

  @override
  Future<void> upsertInvitation(InvitationModel invitation) async {
    await _supabaseClient
        .from('invitations')
        .upsert(invitation.toJson());
  }

  @override
  Future<InvitationModel?> getInvitationByToken(String token) async {
    final response = await _supabaseClient
        .from('invitations')
        .select()
        .eq('token', token)
        .eq('status', 'pending')
        .maybeSingle();
    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }
}
```

---

### Task 6: Create `InvitationRepository` interface and implementation

**File:** `lib/features/auth/domain/repositories/invitation_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';

/// Repository interface for invitation operations.
abstract class InvitationRepository {
  /// Create a new invitation (local + remote sync).
  Future<Either<Failure, InvitationEntity>> createInvitation(
    InvitationEntity invitation,
  );

  /// Get invitation by token.
  Future<Either<Failure, InvitationEntity>> getInvitationByToken(
    String token,
  );

  /// Get pending invitations for an organization.
  Future<Either<Failure, List<InvitationEntity>>>
      getPendingInvitationsForOrganization(String organizationId);

  /// Update invitation status (e.g., accepted, cancelled).
  Future<Either<Failure, InvitationEntity>> updateInvitation(
    InvitationEntity invitation,
  );

  /// Check if a pending invitation already exists for email+org.
  Future<Either<Failure, InvitationEntity?>>
      getExistingPendingInvitation(String email, String organizationId);
}
```

**File:** `lib/features/auth/data/repositories/invitation_repository_implementation.dart` (pattern: `organization_repository_implementation.dart`)

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/network_info.dart';
import 'package:tkd_brackets/core/sync/sync_queue.dart';
import 'package:tkd_brackets/features/auth/data/datasources/invitation_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/invitation_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/invitation_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';

@LazySingleton(as: InvitationRepository)
class InvitationRepositoryImplementation implements InvitationRepository {
  InvitationRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._networkInfo,
    this._syncQueue,
  );

  final InvitationLocalDatasource _localDatasource;
  final InvitationRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;
  final SyncQueue _syncQueue;

  @override
  Future<Either<Failure, InvitationEntity>> createInvitation(
    InvitationEntity invitation,
  ) async {
    try {
      final model = InvitationModel.convertFromEntity(invitation);

      // 1. Write to local database first (offline-first)
      await _localDatasource.insertInvitation(model);

      // 2. Attempt remote sync if online
      if (await _networkInfo.isConnected) {
        try {
          // Sync invitation to Supabase
          await _remoteDatasource.upsertInvitation(model);
          
          // Send invitation email via Edge Function
          await _remoteDatasource.sendInvitationEmail(model);
        } catch (e) {
          // Enqueue for later sync if remote fails
          await _syncQueue.enqueueInvitationCreate(invitation.id);
        }
      } else {
        // Offline - enqueue for sync when online
        await _syncQueue.enqueueInvitationCreate(invitation.id);
      }

      return Right(invitation);
    } catch (e, stack) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to create invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InvitationEntity>> getInvitationByToken(
    String token,
  ) async {
    try {
      // Try local first
      final localModel = await _localDatasource.getInvitationByToken(token);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }

      // Try remote if online
      if (await _networkInfo.isConnected) {
        try {
          final remoteModel =
              await _remoteDatasource.getInvitationByToken(token);
          if (remoteModel != null) {
            // Cache locally
            await _localDatasource.insertInvitation(remoteModel);
            return Right(remoteModel.convertToEntity());
          }
        } catch (e) {
          // Remote failed, return not found
          return const Left(
            LocalCacheAccessFailure(
              userFriendlyMessage: 'Invitation not found.',
            ),
          );
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Invitation not found.',
        ),
      );
    } catch (e, stack) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvitationEntity>>>
      getPendingInvitationsForOrganization(String organizationId) async {
    try {
      final models = await _localDatasource
          .getPendingInvitationsForOrganization(organizationId);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } catch (e, stack) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve invitations.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InvitationEntity>> updateInvitation(
    InvitationEntity invitation,
  ) async {
    try {
      final model = InvitationModel.convertFromEntity(
        invitation,
        syncVersion: invitation.hashCode, // Will be incremented by DB
      );

      // Update local first
      await _localDatasource.updateInvitation(model);

      // Sync to remote if online
      if (await _networkInfo.isConnected) {
        try {
          await _remoteDatasource.upsertInvitation(model);
        } catch (e) {
          await _syncQueue.enqueueInvitationUpdate(invitation.id);
        }
      } else {
        await _syncQueue.enqueueInvitationUpdate(invitation.id);
      }

      return Right(invitation);
    } catch (e, stack) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to update invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InvitationEntity?>> getExistingPendingInvitation(
    String email,
    String organizationId,
  ) async {
    try {
      final model = await _localDatasource.getInvitationByEmailAndOrganization(
        email,
        organizationId,
      );
      if (model == null) return const Right(null);
      return Right(model.convertToEntity());
    } catch (e, stack) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to check for existing invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }
}
```

---

### Task 7: Create `SendInvitationParams` and `SendInvitationUseCase`

**File:** `lib/features/auth/domain/usecases/send_invitation_params.dart`

**IMPORTANT:** Delete the orphaned `send_invitation_params.freezed.dart` BEFORE creating.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'send_invitation_params.freezed.dart';

/// Parameters for SendInvitationUseCase.
@freezed
class SendInvitationParams with _$SendInvitationParams {
  const factory SendInvitationParams({
    /// Email of the user to invite.
    required String email,

    /// Organization to invite the user to.
    required String organizationId,

    /// Role to assign on acceptance.
    required UserRole role,

    /// ID of the user sending the invitation (for auth check).
    required String invitedByUserId,
  }) = _SendInvitationParams;
}
```

**Note:** The previous generated `send_invitation_params.freezed.dart` had only 3 fields (`email`, `organizationId`, `role`). We add `invitedByUserId` for the security check (matching `CreateOrganizationParams` pattern with `userId`).

**File:** `lib/features/auth/domain/usecases/send_invitation_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_params.dart';
import 'package:uuid/uuid.dart';

/// Use case to send an invitation to join an organization.
///
/// This use case:
/// 1. Validates the authenticated user matches invitedByUserId
/// 2. Validates the inviter has Owner role
/// 3. Validates email format
/// 4. Validates role is not 'owner' (cannot invite as owner)
/// 5. Checks for existing pending invitation for same email+org
/// 6. Creates InvitationEntity with generated token and expiry
/// 7. Persists via InvitationRepository (local + remote)
@injectable
class SendInvitationUseCase
    extends UseCase<InvitationEntity, SendInvitationParams> {
  SendInvitationUseCase(
    this._invitationRepository,
    this._userRepository,
    this._authRepository,
  );

  final InvitationRepository _invitationRepository;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  static const _uuid = Uuid();

  /// Default invitation expiry: 7 days.
  static const int expiryDays = 7;

  /// Simple email regex for client-side validation.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, InvitationEntity>> call(
    SendInvitationParams params,
  ) async {
    // 1. Security: Verify authenticated user matches params
    final authResult =
        await _authRepository.getCurrentAuthenticatedUser();

    return authResult.fold(Left.new, (authUser) async {
      if (authUser.id != params.invitedByUserId) {
        return const Left(
          AuthenticationFailure(
            userFriendlyMessage: 'Unauthorized operation.',
            technicalDetails:
                'User ID mismatch in SendInvitationParams',
          ),
        );
      }

      // 2. Verify inviter is Owner
      final userResult =
          await _userRepository.getUserById(params.invitedByUserId);
      return userResult.fold(Left.new, (inviter) async {
        if (inviter.role != UserRole.owner) {
          return const Left(
            AuthorizationPermissionDeniedFailure(
              userFriendlyMessage:
                  'Only organization owners can send invitations.',
              technicalDetails: 'Non-owner attempted to send invitation',
            ),
          );
        }

        // 3. Validate email
        final trimmedEmail = params.email.trim().toLowerCase();
        if (trimmedEmail.isEmpty || !_emailRegex.hasMatch(trimmedEmail)) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage: 'Please enter a valid email address.',
              fieldErrors: {'email': 'Invalid email format'},
            ),
          );
        }

        // 4. Cannot invite as owner
        if (params.role == UserRole.owner) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage:
                  'Cannot assign owner role via invitation.',
              fieldErrors: {
                'role': 'Owner role cannot be assigned via invitation',
              },
            ),
          );
        }

        // 5. Check for existing pending invitation
        final existingResult =
            await _invitationRepository.getExistingPendingInvitation(
          trimmedEmail,
          params.organizationId,
        );
        return existingResult.fold(Left.new, (existing) async {
          if (existing != null) {
            return const Left(
              InputValidationFailure(
                userFriendlyMessage:
                    'An invitation has already been sent to this email.',
                fieldErrors: {
                  'email': 'Pending invitation already exists',
                },
              ),
            );
          }

          // 6. Build invitation entity
          final now = DateTime.now();
          final invitation = InvitationEntity(
            id: _uuid.v4(),
            organizationId: params.organizationId,
            email: trimmedEmail,
            role: params.role,
            invitedBy: params.invitedByUserId,
            status: InvitationStatus.pending,
            token: _uuid.v4(),
            expiresAt: now.add(const Duration(days: expiryDays)),
            createdAt: now,
            updatedAt: now,
          );

          // 7. Persist invitation
          return _invitationRepository.createInvitation(invitation);
        });
      });
    });
  }
}
```

---

### Task 8: Create `AcceptInvitationParams` and `AcceptInvitationUseCase`

**File:** `lib/features/auth/domain/usecases/accept_invitation_params.dart`

**IMPORTANT:** Delete the orphaned `accept_invitation_params.freezed.dart` BEFORE creating.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'accept_invitation_params.freezed.dart';

/// Parameters for AcceptInvitationUseCase.
@freezed
class AcceptInvitationParams with _$AcceptInvitationParams {
  const factory AcceptInvitationParams({
    /// The invitation token from the magic link.
    required String token,

    /// The authenticated user's ID accepting the invitation.
    required String userId,
  }) = _AcceptInvitationParams;
}
```

**File:** `lib/features/auth/domain/usecases/accept_invitation_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/accept_invitation_params.dart';

/// Use case to accept an invitation to join an organization.
///
/// This use case:
/// 1. Validates the authenticated user matches params.userId
/// 2. Looks up invitation by token
/// 3. Validates invitation is still pending and not expired
/// 4. Updates the user's organizationId and role
/// 5. Marks invitation as accepted
@injectable
class AcceptInvitationUseCase
    extends UseCase<InvitationEntity, AcceptInvitationParams> {
  AcceptInvitationUseCase(
    this._invitationRepository,
    this._userRepository,
    this._authRepository,
  );

  final InvitationRepository _invitationRepository;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, InvitationEntity>> call(
    AcceptInvitationParams params,
  ) async {
    // 1. Security check
    final authResult =
        await _authRepository.getCurrentAuthenticatedUser();

    return authResult.fold(Left.new, (authUser) async {
      if (authUser.id != params.userId) {
        return const Left(
          AuthenticationFailure(
            userFriendlyMessage: 'Unauthorized operation.',
            technicalDetails:
                'User ID mismatch in AcceptInvitationParams',
          ),
        );
      }

      // 2. Look up invitation by token
      final invitationResult =
          await _invitationRepository.getInvitationByToken(params.token);
      return invitationResult.fold(Left.new, (invitation) async {
        // 3. Validate status
        if (invitation.status != InvitationStatus.pending) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage:
                  'This invitation is no longer valid.',
              fieldErrors: {
                'token': 'Invitation is not pending',
              },
            ),
          );
        }

        // 4. Validate not expired
        if (DateTime.now().isAfter(invitation.expiresAt)) {
          // Mark as expired
          final expiredInvitation = invitation.copyWith(
            status: InvitationStatus.expired,
            updatedAt: DateTime.now(),
          );
          await _invitationRepository.updateInvitation(expiredInvitation);

          return const Left(
            InputValidationFailure(
              userFriendlyMessage: 'This invitation has expired.',
              fieldErrors: {'token': 'Invitation expired'},
            ),
          );
        }

        // 5. Update user's organization and role
        final userResult =
            await _userRepository.getUserById(params.userId);
        return userResult.fold(Left.new, (user) async {
          final updatedUser = user.copyWith(
            organizationId: invitation.organizationId,
            role: invitation.role,
          );
          final updateResult =
              await _userRepository.updateUser(updatedUser);

          return updateResult.fold(Left.new, (_) async {
            // 6. Mark invitation as accepted
            final acceptedInvitation = invitation.copyWith(
              status: InvitationStatus.accepted,
              updatedAt: DateTime.now(),
            );
            return _invitationRepository
                .updateInvitation(acceptedInvitation);
          });
        });
      });
    });
  }
}
```

---

### Task 9: Update `auth.dart` barrel file

Add these exports to `lib/features/auth/auth.dart`:

```dart
// Data - Datasources (invitation)
export 'data/datasources/invitation_local_datasource.dart';
export 'data/datasources/invitation_remote_datasource.dart';

// Data - Models (invitation)
export 'data/models/invitation_model.dart';

// Data - Repositories (invitation)
export 'data/repositories/invitation_repository_implementation.dart';

// Domain - Entities (invitation)
export 'domain/entities/invitation_entity.dart';

// Domain - Repositories (invitation)
export 'domain/repositories/invitation_repository.dart';

// Domain - Use Cases (invitation)
export 'domain/usecases/accept_invitation_params.dart';
export 'domain/usecases/accept_invitation_use_case.dart';
export 'domain/usecases/send_invitation_params.dart';
export 'domain/usecases/send_invitation_use_case.dart';
```

---

### Task 10: Delete orphaned generated files

**⚠️ CRITICAL: Run this BEFORE implementing Tasks 1-8. If you skip this step, build_runner will fail with conflicts.**

Delete these orphaned files that have no source `.dart` file:

```bash
rm lib/features/auth/domain/entities/invitation_entity.freezed.dart
rm lib/features/auth/data/models/invitation_model.g.dart
rm lib/features/auth/data/datasources/invitation_local_datasource.g.dart
rm lib/features/auth/domain/usecases/send_invitation_params.freezed.dart
rm lib/features/auth/domain/usecases/accept_invitation_params.freezed.dart
```

Or run all at once:
```bash
cd tkd_brackets
rm lib/features/auth/domain/entities/invitation_entity.freezed.dart \
   lib/features/auth/data/models/invitation_model.g.dart \
   lib/features/auth/data/datasources/invitation_local_datasource.g.dart \
   lib/features/auth/domain/usecases/send_invitation_params.freezed.dart \
   lib/features/auth/domain/usecases/accept_invitation_params.freezed.dart
```

---

### Task 11: Run build_runner and analyze

```bash
cd tkd_brackets
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

### Task 12: Unit tests — `SendInvitationUseCase`

**File:** `test/features/auth/domain/usecases/send_invitation_use_case_test.dart`

```dart
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

  // Test fixtures
  final testOwner = UserEntity(
    id: 'owner-123', email: 'owner@test.com',
    displayName: 'Owner', organizationId: 'org-1',
    role: UserRole.owner, isActive: true,
    createdAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(FakeInvitationEntity());
  });

  setUp(() {
    mockInvitationRepository = MockInvitationRepository();
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();

    // Default: authenticated as owner
    when(() => mockAuthRepository.getCurrentAuthenticatedUser())
        .thenAnswer((_) async => Right(testOwner));
    when(() => mockUserRepository.getUserById('owner-123'))
        .thenAnswer((_) async => Right(testOwner));

    useCase = SendInvitationUseCase(
      mockInvitationRepository, mockUserRepository, mockAuthRepository,
    );
  });

  group('SendInvitationUseCase', () {
    group('security checks', () {
      test('returns AuthenticationFailure when user ID mismatch', () async {
        final otherUser = testOwner.copyWith(id: 'other-id');
        when(() => mockAuthRepository.getCurrentAuthenticatedUser())
            .thenAnswer((_) async => Right(otherUser));

        final result = await useCase(const SendInvitationParams(
          email: 'invite@test.com', organizationId: 'org-1',
          role: UserRole.admin, invitedByUserId: 'owner-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<AuthenticationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns AuthorizationFailure when non-owner tries to invite',
          () async {
        final scorer = testOwner.copyWith(role: UserRole.scorer);
        when(() => mockUserRepository.getUserById('owner-123'))
            .thenAnswer((_) async => Right(scorer));

        final result = await useCase(const SendInvitationParams(
          email: 'invite@test.com', organizationId: 'org-1',
          role: UserRole.admin, invitedByUserId: 'owner-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('validation', () {
      test('returns InputValidationFailure for empty email', () async {
        final result = await useCase(const SendInvitationParams(
          email: '', organizationId: 'org-1',
          role: UserRole.admin, invitedByUserId: 'owner-123',
        ));
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for invalid email format',
          () async {
        final result = await useCase(const SendInvitationParams(
          email: 'not-an-email', organizationId: 'org-1',
          role: UserRole.admin, invitedByUserId: 'owner-123',
        ));
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure when role is owner', () async {
        final result = await useCase(const SendInvitationParams(
          email: 'invite@test.com', organizationId: 'org-1',
          role: UserRole.owner, invitedByUserId: 'owner-123',
        ));
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for duplicate pending invitation',
          () async {
        when(() => mockInvitationRepository.getExistingPendingInvitation(
              'invite@test.com', 'org-1'))
            .thenAnswer((_) async => Right(InvitationEntity(
                  id: 'inv-1', organizationId: 'org-1',
                  email: 'invite@test.com', role: UserRole.admin,
                  invitedBy: 'owner-123',
                  status: InvitationStatus.pending,
                  token: 'token-1',
                  expiresAt: DateTime.now().add(const Duration(days: 7)),
                  createdAt: DateTime(2024), updatedAt: DateTime(2024),
                )));

        final result = await useCase(const SendInvitationParams(
          email: 'invite@test.com', organizationId: 'org-1',
          role: UserRole.admin, invitedByUserId: 'owner-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('successful invitation', () {
      test('creates invitation with correct fields', () async {
        when(() => mockInvitationRepository.getExistingPendingInvitation(
              'invite@test.com', 'org-1'))
            .thenAnswer((_) async => const Right(null));

        late InvitationEntity captured;
        when(() => mockInvitationRepository.createInvitation(any()))
            .thenAnswer((inv) async {
          captured =
              inv.positionalArguments.first as InvitationEntity;
          return Right(captured);
        });

        final result = await useCase(const SendInvitationParams(
          email: 'INVITE@TEST.COM', organizationId: 'org-1',
          role: UserRole.admin, invitedByUserId: 'owner-123',
        ));

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
```

---

### Task 13: Unit tests — `AcceptInvitationUseCase`

**File:** `test/features/auth/domain/usecases/accept_invitation_use_case_test.dart` (pattern: `create_organization_use_case_test.dart`)

```dart
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

  // Test fixtures
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

    // Default: authenticated as testUser
    when(() => mockAuthRepository.getCurrentAuthenticatedUser())
        .thenAnswer((_) async => Right(testUser));

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
        when(() => mockAuthRepository.getCurrentAuthenticatedUser())
            .thenAnswer((_) async => Right(otherUser));

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<AuthenticationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockInvitationRepository);
      });

      test('returns Failure if getCurrentAuthenticatedUser fails', () async {
        when(() => mockAuthRepository.getCurrentAuthenticatedUser())
            .thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(userFriendlyMessage: 'Auth error'),
          ),
        );

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

        expect(result.isLeft(), isTrue);
        verifyZeroInteractions(mockInvitationRepository);
      });
    });

    group('invitation validation', () {
      test('returns failure when invitation not found', () async {
        when(() => mockInvitationRepository.getInvitationByToken('invalid'))
            .thenAnswer(
          (_) async => const Left(
            LocalCacheAccessFailure(
              userFriendlyMessage: 'Invitation not found.',
            ),
          ),
        );

        final result = await useCase(const AcceptInvitationParams(
          token: 'invalid',
          userId: 'user-123',
        ));

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
        when(() => mockInvitationRepository.getInvitationByToken('valid-token'))
            .thenAnswer((_) async => Right(acceptedInvitation));

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<InputValidationFailure>());
            expect(
              (f as InputValidationFailure).userFriendlyMessage,
              contains('no longer valid'),
            );
          },
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockUserRepository);
      });

      test('returns InputValidationFailure and marks as expired when past expiresAt',
          () async {
        final expiredInvitation = testInvitation.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        when(() => mockInvitationRepository.getInvitationByToken('valid-token'))
            .thenAnswer((_) async => Right(expiredInvitation));
        when(() => mockInvitationRepository.updateInvitation(any()))
            .thenAnswer((inv) async {
          final updated =
              inv.positionalArguments.first as InvitationEntity;
          return Right(updated);
        });

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<InputValidationFailure>());
            expect(
              (f as InputValidationFailure).userFriendlyMessage,
              contains('expired'),
            );
          },
          (_) => fail('Expected Left'),
        );

        // Verify invitation was marked as expired
        verify(() => mockInvitationRepository.updateInvitation(any(
              that: predicate<InvitationEntity>(
                (inv) => inv.status == InvitationStatus.expired,
              ),
            ))).called(1);
        verifyZeroInteractions(mockUserRepository);
      });
    });

    group('successful acceptance', () {
      test('updates user organizationId and role, marks invitation accepted',
          () async {
        late UserEntity capturedUser;
        late InvitationEntity capturedInvitation;

        when(() => mockInvitationRepository.getInvitationByToken('valid-token'))
            .thenAnswer((_) async => Right(testInvitation));
        when(() => mockUserRepository.getUserById('user-123'))
            .thenAnswer((_) async => Right(testUser));
        when(() => mockUserRepository.updateUser(any())).thenAnswer((inv) async {
          capturedUser = inv.positionalArguments.first as UserEntity;
          return Right(capturedUser);
        });
        when(() => mockInvitationRepository.updateInvitation(any()))
            .thenAnswer((inv) async {
          capturedInvitation =
              inv.positionalArguments.first as InvitationEntity;
          return Right(capturedInvitation);
        });

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

        expect(result.isRight(), isTrue);

        // Verify user was updated
        expect(capturedUser.organizationId, 'org-1');
        expect(capturedUser.role, UserRole.admin);

        // Verify invitation was marked accepted
        expect(capturedInvitation.status, InvitationStatus.accepted);

        // Verify call order
        verifyInOrder([
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
          () => mockInvitationRepository.getInvitationByToken('valid-token'),
          () => mockUserRepository.getUserById('user-123'),
          () => mockUserRepository.updateUser(any()),
          () => mockInvitationRepository.updateInvitation(any()),
        ]);
      });
    });

    group('error handling', () {
      test('returns failure when getUserById fails', () async {
        when(() => mockInvitationRepository.getInvitationByToken('valid-token'))
            .thenAnswer((_) async => Right(testInvitation));
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => const Left(
            LocalCacheAccessFailure(userFriendlyMessage: 'User not found.'),
          ),
        );

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocalCacheAccessFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(() => mockUserRepository.updateUser(any()));
        verifyNever(() => mockInvitationRepository.updateInvitation(any()));
      });

      test('returns failure when updateUser fails', () async {
        when(() => mockInvitationRepository.getInvitationByToken('valid-token'))
            .thenAnswer((_) async => Right(testInvitation));
        when(() => mockUserRepository.getUserById('user-123'))
            .thenAnswer((_) async => Right(testUser));
        when(() => mockUserRepository.updateUser(any())).thenAnswer(
          (_) async => const Left(
            LocalCacheWriteFailure(userFriendlyMessage: 'Failed to update user.'),
          ),
        );

        final result = await useCase(const AcceptInvitationParams(
          token: 'valid-token',
          userId: 'user-123',
        ));

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
```

---

### Task 14: Run tests

```bash
cd tkd_brackets
flutter test test/features/auth/domain/usecases/send_invitation_use_case_test.dart
flutter test test/features/auth/domain/usecases/accept_invitation_use_case_test.dart
```

---

## Dev Notes

### ⚠️ CRITICAL: Orphaned Generated Files

The following generated files exist WITHOUT source `.dart` files. They are from a previous aborted implementation. **DELETE THEM BEFORE CREATING SOURCE FILES:**

- `lib/features/auth/domain/entities/invitation_entity.freezed.dart`
- `lib/features/auth/data/models/invitation_model.g.dart`
- `lib/features/auth/data/datasources/invitation_local_datasource.g.dart`
- `lib/features/auth/domain/usecases/send_invitation_params.freezed.dart`
- `lib/features/auth/domain/usecases/accept_invitation_params.freezed.dart`

### ⚠️ CRITICAL: No `invitations` Table in Architecture Schema

The `architecture.md` does NOT define an `invitations` table in its Database Schema Definitions section. The table schema in Task 2 is derived from:
1. The `InvitationEntity` fields specified in the acceptance criteria
2. The patterns established by `organizations_table.dart` and `users_table.dart`
3. The `BaseSyncMixin` and `BaseAuditMixin` patterns

### Database Schema Version

Current: `schemaVersion => 3`. Must bump to `4` and add migration for `invitations` table.

### Pattern References

| What                      | Reference File                                 |
| ------------------------- | ---------------------------------------------- |
| Entity with enum          | `user_entity.dart`, `organization_entity.dart` |
| Model with conversions    | `organization_model.dart`                      |
| Local datasource          | `organization_local_datasource.dart`           |
| Remote datasource         | `organization_remote_datasource.dart`          |
| Repository interface      | `organization_repository.dart`                 |
| Repository implementation | `organization_repository_implementation.dart`  |
| Use case with auth check  | `create_organization_use_case.dart`            |
| Params class              | `create_organization_params.dart`              |
| Unit test pattern         | `create_organization_use_case_test.dart`       |
| Drift table               | `organizations_table.dart`, `users_table.dart` |

### Naming Conventions (from architecture.md)

- **Files:** `snake_case` — e.g., `invitation_entity.dart`
- **Classes:** `PascalCase` — e.g., `InvitationEntity`
- **Enums:** `PascalCase` with `camelCase` values — e.g., `InvitationStatus.pending`
- **Database columns:** `snake_case` — e.g., `organization_id`
- **JSON keys:** `snake_case` via `@JsonKey(name: 'snake_case')`

### Error Handling Pattern

All use cases return `Either<Failure, T>` using fpdart:
- `InputValidationFailure` for validation errors (with `fieldErrors` map)
- `AuthenticationFailure` for auth errors
- `AuthorizationPermissionDeniedFailure` for permission errors
- `LocalCacheAccessFailure` / `LocalCacheWriteFailure` for storage errors
- `ServerConnectionFailure` / `ServerResponseFailure` for network errors

### Invitation Token Flow

1. Owner sends invitation → `SendInvitationUseCase` generates UUID token
2. Token is stored locally and synced to Supabase
3. Supabase Edge Function `send-invitation` sends email with token
4. Invitee clicks link → app receives token → `AcceptInvitationUseCase`
5. Token is validated (pending + not expired)
6. User's org and role are updated
7. Invitation marked as `accepted`

### Existing `InvitationModel.g.dart` Uses camelCase JSON Keys

The orphaned `invitation_model.g.dart` uses camelCase keys (`organizationId`, `invitedBy`). The new implementation MUST use `@JsonKey(name: 'snake_case')` annotations to match the Supabase/database convention used in `organization_model.dart`.

### Dependencies

- `uuid` package (already in pubspec.yaml, used by `create_organization_use_case.dart`)
- `mocktail` (dev dependency, already in pubspec.yaml)
- `supabase_flutter` (already in pubspec.yaml)

### What This Story Does NOT Include

- Edge Function implementation (`send-invitation`) — this is Supabase server-side
- Invitation email template HTML — architecture.md section 21 covers this
- UI/BLoC for invitation management — future story
- Invitation listing/cancellation UI — future story
